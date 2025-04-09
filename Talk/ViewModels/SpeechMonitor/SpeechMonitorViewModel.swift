//
//  SpeechMonitorViewModel.swift
//  Talk
//
//  Created by Yu on 2025/4/6.
//

import Foundation
import AVFoundation
import ios_voice_processor
import Combine

/// Core view model for automatic voice detection and recognition
/// Uses a VAD engine to detect voice activity
/// Starts recording when speech is detected, returns audio data after silence
class SpeechMonitorViewModel: NSObject, ObservableObject {
    /// Logger
    private let logger = DebugLogger(tag: "SpeechMonitor")

    /// VAD (Voice Activity Detection) engine
    private var vadEngine: VADEngine?
    
    /// Whether currently recording
    private var recording = false

    /// Ring buffer to store recent audio frames for "pre-recording"
    private var ringBuffer: [[Int16]] = []
    
    /// Maximum number of frames in the ring buffer, controls pre-recording length
    /// Currently stores about 1 second of audio (40 frames)
    private let maxRingBufferFrames = 40

    /// Full recording data (includes pre-recording and speaking audio)
    private var currentRecording: [Int16] = []

    /// Timer to detect silence
    /// Ends recording automatically after a period of silence (e.g., 1 second)
    private var vadTimeoutTimer: Timer?

    /// Interval for updating volume (in seconds)
    private let volumeUpdateInterval: TimeInterval = 0.1 // 100ms

    /// Last time the volume was updated
    private var lastVolumeUpdateTime: Date = Date.distantPast
    
    /// Minimum threshold for volume change to trigger UI update
    private let volumeChangeThreshold: Float = 0.05 // 5% change
    
    /// Last published volume value
    private var lastPublishedVolume: Float = 0.0
    
    /// Volume publisher
    private let volumeSubject = PassthroughSubject<Float, Never>()
    
    /// Subscription holders
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published Properties

    /// Whether the system is currently listening to audio input
    @Published private(set) var listening = false
    
    /// Whether speech is currently detected
    @Published private(set) var speaking: Bool = false
    
    /// Current speaking volume (0 to 1)
    /// Only updates when speaking is true
    @Published private(set) var voiceVolume: Float = 0.0
    
    /// Final recorded PCM audio data
    /// Updated when speech is detected and ends
    @Published private(set) var recordedAudioData: [Int16]? = nil
    
    /// Error information
    @Published var error: Error? = nil

    // MARK: - Audio Configuration
    
    /// Audio sample rate (Hz)
    private(set) var sampleRate: UInt32 = 16000
    
    /// Number of audio channels (mono)
    private(set) var numChannels: UInt16 = 1

    // MARK: - Initialization
    
    /// Initialize the voice monitoring view model
    /// - Parameter vadEngine: VAD engine instance, defaults to nil (uses CobraVAD if not provided)
    init(vadEngine: VADEngine? = nil) {
        super.init()
        
        // Add audio processing and error callbacks
        VoiceProcessor.instance.addErrorListener(VoiceProcessorErrorListener { [weak self] error in
            Task { @MainActor [weak self] in
                self?.error = error
                self?.logger.error("VoiceProcessor Error: \(error)")
            }
        })
        
        VoiceProcessor.instance.addFrameListener(VoiceProcessorFrameListener { [weak self] frame in
            self?.processAudioFrame(frame)
        })
        
        // Setup volume smoothing
        setupVolumeDebounce()
        
        logger.info("Initialized successfully")
    }
    
    /// Set up volume throttling and smoothing
    private func setupVolumeDebounce() {
        volumeSubject
            .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
            .removeDuplicates(by: { abs($0 - $1) < self.volumeChangeThreshold })
            .sink { [weak self] volume in
                guard let self = self else { return }
                self.lastPublishedVolume = volume
                Task { @MainActor in
                    self.voiceVolume = volume
                    self.logger.debug("Volume updated: \(String(format: "%.2f", volume))")
                }
            }
            .store(in: &cancellables)
    }

    /// Release resources on deinit
    deinit {
        logger.info("Releasing resources")
        stopMonitoring()
        vadEngine?.delete()
        vadEngine = nil
        
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    // MARK: - Public Methods
    
    /// Set the VAD engine
    /// - Parameter engine: VAD engine instance to use
    /// - Returns: Whether the engine was set successfully
    @discardableResult
    func setVADEngine(_ engine: VADEngine) -> Bool {
        logger.info("Setting new VAD engine...")
        
        let wasListening = listening
        if wasListening {
            stopMonitoring()
        }
        
        vadEngine?.delete()
        vadEngine = engine
        logger.success("VAD engine updated")
        
        if wasListening {
            startMonitoring()
        }
        
        return true
    }
    
    /// Start audio monitoring
    /// Begins capturing and analyzing microphone input
    func startMonitoring() {
        logger.info("Starting monitoring...")
        guard !listening else {
            logger.warning("Already listening, skipping request")
            return
        }
        guard vadEngine != nil else {
            let error = NSError(domain: "SpeechMonitor", code: 1, userInfo: [NSLocalizedDescriptionKey: "VAD engine not initialized"])
            Task { @MainActor in
                self.error = error
                logger.error("Failed to start monitoring: VAD engine not initialized")
            }
            return
        }
        
        guard VoiceProcessor.hasRecordAudioPermission else {
            logger.info("Requesting microphone permission...")
            VoiceProcessor.requestRecordAudioPermission { [weak self] isGranted in
                guard isGranted else {
                    Task { @MainActor [weak self] in
                        self?.error = NSError(domain: "SpeechMonitor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])
                        self?.logger.error("Microphone permission denied")
                    }
                    return
                }
                
                self?.logger.success("Microphone permission granted")
                Task { @MainActor in
                    self?.startMonitoring()
                }
            }
            return
        }
        
        do {
            let frameLength = type(of: vadEngine!).frameLength
            let sampleRate = type(of: vadEngine!).sampleRate
            
            try VoiceProcessor.instance.start(
                frameLength: frameLength,
                sampleRate: UInt32(sampleRate)
            )
            logger.success("Monitoring started. frameLength=\(frameLength), sampleRate=\(sampleRate)")
            Task { @MainActor in
                self.listening = true
                self.error = nil
            }
        } catch {
            Task { @MainActor in
                self.error = error
                logger.error("VoiceProcessor start error: \(error)")
            }
        }
    }

    /// Stop audio monitoring
    /// Stops microphone input and resets state
    func stopMonitoring() {
        logger.info("Stopping monitoring...")
        guard listening else {
            logger.warning("Not currently listening, skipping request")
            return
        }
        
        do {
            try VoiceProcessor.instance.stop()
            logger.success("Monitoring stopped")
            
            Task { @MainActor in
                self.listening = false
                self.speaking = false
                self.voiceVolume = 0.0
                self.lastPublishedVolume = 0.0
            }
        } catch {
            Task { @MainActor in
                self.error = error
                logger.error("VoiceProcessor stop error: \(error)")
            }
        }
        
        vadTimeoutTimer?.invalidate()
        vadTimeoutTimer = nil
    }

    /// Toggle monitoring on or off
    func toggleMonitoring() {
        logger.info("Toggling monitoring state, current: \(listening ? "On" : "Off")")
        if listening {
            stopMonitoring()
        } else {
            startMonitoring()
        }
    }

    // MARK: - Private Methods
    
    /// Process incoming audio frame
    /// - Parameter frame: Raw PCM audio data
    private func processAudioFrame(_ frame: [Int16]) {
        ringBuffer.append(frame)
        if ringBuffer.count > maxRingBufferFrames {
            ringBuffer.removeFirst()
        }

        guard let vadEngine = vadEngine else { return }
        
        do {
            let isSpeaking = try vadEngine.process(frame: frame)
            
            Task { @MainActor [weak self] in
                self?.updateVoiceState(isSpeaking: isSpeaking, frame: frame)
            }
        } catch {
            Task { @MainActor [weak self] in
                self?.error = error
                self?.logger.error("VAD frame processing error: \(error)")
            }
        }
    }

    /// Update speech state and control recording logic
    @MainActor
    private func updateVoiceState(isSpeaking: Bool, frame: [Int16]) {
        if isSpeaking {
            if !speaking {
                speaking = true
                logger.voice("Speech started")
                beginRecordingWithPreSpeech()
            }
            
            updateVoiceVolume(frame: frame)
            resetVadTimeout()
            
            if recording {
                currentRecording.append(contentsOf: frame)
            }
        }
    }

    /// Calculate and update volume level from audio frame
    private func updateVoiceVolume(frame: [Int16]) {
        let now = Date()
        guard now.timeIntervalSince(lastVolumeUpdateTime) >= volumeUpdateInterval else {
            return
        }
        lastVolumeUpdateTime = now

        let sampleStride = 4
        var sum: Float = 0.0
        var count = 0
        
        for i in stride(from: 0, to: frame.count, by: sampleStride) {
            let sample = Float(frame[i])
            sum += sample * sample
            count += 1
        }
        
        guard count > 0 else { return }
        
        let rms = sqrt(sum / Float(count))
        let normalizedVolume = rms / 32767.0
        let mappedVolume = pow(normalizedVolume, 0.4)
        let clampedVolume = min(1.0, max(0.0, mappedVolume))
        
        if speaking {
            volumeSubject.send(clampedVolume)
        } else {
            if lastPublishedVolume > 0 {
                volumeSubject.send(0.0)
            }
        }
    }

    /// Reset the silence timeout timer
    private func resetVadTimeout() {
        vadTimeoutTimer?.invalidate()
        vadTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.logger.info("Silence timeout reached, ending recording")
                self.speaking = false
                self.endRecording()
            }
        }
    }

    /// Start recording and include pre-recorded frames
    private func beginRecordingWithPreSpeech() {
        currentRecording = ringBuffer.flatMap { $0 }
        recording = true
        logger.info("Recording started, pre-recorded frames: \(ringBuffer.count)")
    }

    /// End recording and finalize audio data
    @MainActor
    private func endRecording() {
        recording = false
        logger.info("Recording ended, total samples: \(currentRecording.count)")
        self.recordedAudioData = currentRecording
        
        currentRecording.removeAll()
        ringBuffer.removeAll()
        
        if let audioData = self.recordedAudioData {
            let durationInSeconds = Float(audioData.count) / Float(sampleRate)
            logger.success("Recording complete, samples: \(audioData.count), duration: \(String(format: "%.2f", durationInSeconds)) seconds")
        } else {
            logger.error("No audio data recorded")
        }
    }
}

/// Data conversion extension
extension Data {
    /// Convert value to binary Data
    /// - Parameter value: Value to convert
    init<T>(from value: T) {
        var value = value
        self = Swift.withUnsafeBytes(of: &value) { Data($0) }
    }
}
