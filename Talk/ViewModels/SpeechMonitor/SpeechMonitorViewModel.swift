//
//  SpeechMonitorViewModel.swift
//  Talk
//
//  Created by Yu on 2025/4/6.
//

import AVFoundation
import Combine
import Foundation
import ios_voice_processor

// TODO: Refactor this file to simplify the VAD code and make it more readable

/// Core view model for automatic voice detection and recognition
/// Uses a VAD engine to detect voice activity
/// Starts recording when speech is detected, returns audio data after silence
class SpeechMonitorViewModel: NSObject, ObservableObject {
    /// Logger
    private let logger = DebugLogger(tag: "SpeechMonitor")

    /// VAD (Voice Activity Detection) engine
    private var vadEngine: VADEngine = EnergyVADEngine()

    /// Whether currently recording
    private var recording = false

    /// Whether to use manual recording mode (without VAD)
    private var manualRecording = false

    /// Ring buffer to store recent audio frames for "pre-recording"
    private var ringBuffer: [Int16] = []

    /// Maximum size of ring buffer in samples (not frames)
    /// Stores about 1.5 second of audio at 16kHz (24000 samples)
    private let maxRingBufferSize = 24000

    /// Frame overlap to ensure smooth transitions between frames
    private let frameOverlap = 10

    /// Minimum active frames needed to consider valid speech
    private let minActiveFrames = 3

    /// Minimum silent frames needed to consider valid silence
    private let minSilentFrames = 5

    /// Active frames counter for speech verification
    private var activeFramesCount = 0

    /// Consecutive silent frames counter for current frame processing
    private var silentFramesCount = 0

    /// Accumulated silent frames counter for end-of-speech detection
    private var accumulatedSilentFrames = 0

    /// Maximum silence frames before ending recording (1.2 seconds at 16kHz, 40ms per frame)
    private let maxSilentFrames = 30

    /// Minimum recording duration (in frames) to keep the recording, avoids false triggers
    private let minRecordingFrames = 30

    /// Full recording data (includes pre-recording and speaking audio)
    private var currentRecording: [Int16] = []

    /// Timer to detect silence
    /// Ends recording automatically after a period of silence (e.g., 3 seconds)
    private var vadTimeoutTimer: Timer?

    /// Interval for updating volume (in seconds)
    private let volumeUpdateInterval: TimeInterval = 0.1 // 100ms

    /// Last time the volume was updated
    private var lastVolumeUpdateTime: Date = .distantPast

    /// Minimum threshold for volume change to trigger UI update
    private let volumeChangeThreshold: Float = 0.05 // 5% change

    /// Last published volume value
    private var lastPublishedVolume: Float = 0.0

    /// Volume publisher
    private let volumeSubject = PassthroughSubject<Float, Never>()

    /// Subscription holders
    private var cancellables = Set<AnyCancellable>()

    /// Raw VAD speaking state from last frame
    private var lastVADResult = false

    /// Processed speaking state with smoothing logic
    private var smoothedSpeakingState = false

    /// Recent VAD history buffer for smoothing algorithm
    private var recentVADHistory: [Bool] = []

    /// Maximum size of VAD history buffer
    private let maxVADHistorySize = 10

    /// Silence detection sensitivity multiplier when in speaking state
    /// Higher values make it more likely to stay in speaking state during pauses
    private let inSpeechSilenceThresholdMultiplier: Float = 0.5

    /// Last audio frame for overlap processing
    private var lastAudioFrame: [Int16]?

    /// Silence threshold multiplier when already in speaking state
    /// Lower values make it more sensitive to detect the end of speech
    private let silenceThresholdMultiplier: Float = 0.8

    /// Consecutive silent frame counter (for detecting end of speech)
    private var consecutiveSilentFrames = 0

    /// Silence energy threshold base value
    private let baseSilenceThreshold: Float = 350.0

    /// Current adaptive silence threshold, adjusted based on audio levels
    private var currentSilenceThreshold: Float = 350.0

    /// Debug frame counter
    private var frameCounter = 0

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
    override init() {
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
        vadEngine.delete()

        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    // MARK: - Public Methods

    /// Set manual recording mode
    /// - Parameter isManual: Whether to use manual recording mode
    func setManualRecording(_ isManual: Bool) {
        logger.info("Setting manual recording mode: \(isManual)")
        manualRecording = isManual
    }

    /// Set the VAD engine
    /// - Parameter engine: VAD engine instance to use
    func setVADEngine(_: VADEngine) {
        logger.info("Setting new VAD engine...")

        let wasListening = listening
        if wasListening {
            stopMonitoring()
        }

        vadEngine.delete()
        logger.success("VAD engine updated")

        if wasListening {
            startMonitoring()
        }
    }

    /// Start audio monitoring
    /// Begins capturing and analyzing microphone input
    /// Delegates to appropriate method based on manual recording setting
    func startMonitoring() {
        vadEngine.delete()

        if manualRecording {
            startMonitoringWithoutVAD()
        } else {
            startMonitoringWithVAD()
        }
    }

    /// Stop audio monitoring
    /// Stops microphone input and resets state
    /// Delegates to appropriate method based on manual recording setting
    func stopMonitoring() {
        if manualRecording {
            stopMonitoringWithoutVAD()
        } else {
            stopMonitoringWithVAD()
        }
    }

    /// Start audio monitoring with VAD
    /// Begins capturing and analyzing microphone input using voice activity detection
    func startMonitoringWithVAD() {
        logger.info("Starting monitoring with VAD...")
        guard !listening else {
            logger.warning("Already listening, skipping request")
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
                    self?.startMonitoringWithVAD()
                }
            }
            return
        }

        do {
            let frameLength = type(of: vadEngine).frameLength
            let sampleRate = type(of: vadEngine).sampleRate

            try VoiceProcessor.instance.start(
                frameLength: frameLength,
                sampleRate: UInt32(sampleRate)
            )
            logger.success("Monitoring with VAD started. frameLength=\(frameLength), sampleRate=\(sampleRate)")
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

    /// Stop audio monitoring with VAD
    /// Stops microphone input and resets state
    func stopMonitoringWithVAD() {
        logger.info("Stopping monitoring with VAD...")
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
                self.resetStateCounters()
                self.ringBuffer.removeAll() // Clear ring buffer when stopping monitoring
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

    /// Start audio monitoring without VAD
    /// Immediately begins recording without waiting for voice activity
    func startMonitoringWithoutVAD() {
        logger.info("Starting monitoring without VAD (manual recording)...")
        guard !listening else {
            logger.warning("Already listening, skipping request")
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
                    self?.startMonitoringWithoutVAD()
                }
            }
            return
        }

        do {
            // Use same audio configuration as VAD for consistency
            let frameLength = type(of: vadEngine).frameLength
            let sampleRate = type(of: vadEngine).sampleRate

            try VoiceProcessor.instance.start(
                frameLength: frameLength,
                sampleRate: UInt32(sampleRate)
            )

            // Initialize recording immediately
            currentRecording = []
            recording = true

            logger.success("Manual recording started. frameLength=\(frameLength), sampleRate=\(sampleRate)")
            Task { @MainActor in
                self.listening = true
                self.speaking = true // Set speaking to true for manual recording
                self.error = nil
            }
        } catch {
            Task { @MainActor in
                self.error = error
                logger.error("VoiceProcessor start error: \(error)")
            }
        }
    }

    /// Stop audio monitoring without VAD
    /// Immediately stops recording and processes the audio
    func stopMonitoringWithoutVAD() {
        logger.info("Stopping manual recording...")
        guard listening else {
            logger.warning("Not currently listening, skipping request")
            return
        }

        do {
            try VoiceProcessor.instance.stop()

            // Process the recording if we have data
            if recording && !currentRecording.isEmpty {
                // Normalize recording levels for consistent volume
                let normalizedRecording = normalizeAudioLevels(currentRecording)

                let frameSize = Int(type(of: vadEngine).frameLength)
                var isSpeaking = false

                for i in stride(from: 0, to: normalizedRecording.count, by: frameSize) {
                    let end = min(i + frameSize, normalizedRecording.count)
                    let frameData = Array(normalizedRecording[i ..< end])

                    if try vadEngine.process(frame: frameData) {
                        isSpeaking = true
                        break
                    }
                }

                if isSpeaking {
                    Task { @MainActor in
                        self.recordedAudioData = normalizedRecording

                        if let audioData = self.recordedAudioData {
                            let durationInSeconds = Float(audioData.count) / Float(self.sampleRate)
                            logger.success("Manual recording complete, samples: \(audioData.count), duration: \(String(format: "%.2f", durationInSeconds)) seconds")
                        } else {
                            logger.error("No audio data recorded")
                        }
                    }
                } else {
                    logger.warning("No speech detected in manual recording")
                }
            } else {
                logger.warning("No recording data available")
            }

            logger.success("Manual recording stopped")

            Task { @MainActor in
                self.listening = false
                self.speaking = false
                self.voiceVolume = 0.0
                self.lastPublishedVolume = 0.0
                self.recording = false
                self.currentRecording.removeAll()
                self.resetStateCounters()
            }
        } catch {
            Task { @MainActor in
                self.error = error
                logger.error("VoiceProcessor stop error: \(error)")
            }
        }
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
        frameCounter += 1

        // Add frame to ring buffer with proper management
        updateRingBuffer(with: frame)

        // For manual recording, just add the frame to recording
        if manualRecording && recording {
            addFrameToRecording(frame)

            // Update volume level
            Task { @MainActor [weak self] in
                self?.updateVoiceVolume(frame: frame)
            }

            return
        }

        // Normal VAD processing
        do {
            let rawIsSpeaking = try vadEngine.process(frame: frame)

            // Calculate frame energy for better decision making
            let frameEnergy = calculateEnergy(frame)

            // Update adaptive silence threshold based on recent audio
            updateSilenceThreshold(frameEnergy: frameEnergy, isSpeaking: rawIsSpeaking)

            // Enhanced state determination with energy consideration
            let enhancedIsSpeaking = determineEnhancedSpeakingState(
                vadResult: rawIsSpeaking,
                frameEnergy: frameEnergy
            )

            // Only log occasionally to reduce spam
            if frameCounter % 25 == 0 {
                let state = enhancedIsSpeaking ? "SPEAKING" : "SILENT"
                let rawState = rawIsSpeaking ? "true" : "false"
                logger.debug("Frame #\(frameCounter): VAD=\(rawState), Enhanced=\(state), Energy=\(String(format: "%.1f", frameEnergy)), Threshold=\(String(format: "%.1f", currentSilenceThreshold))")
            }

            // Update VAD history buffer
            recentVADHistory.append(enhancedIsSpeaking)
            if recentVADHistory.count > maxVADHistorySize {
                recentVADHistory.removeFirst()
            }

            // Apply smoothing algorithm for final speaking state
            let smoothedIsSpeaking = determineSmoothedSpeakingState(enhancedIsSpeaking)
            lastVADResult = rawIsSpeaking

            Task { @MainActor [weak self] in
                self?.updateVoiceState(isSpeaking: smoothedIsSpeaking, frameEnergy: frameEnergy, frame: frame)
            }
        } catch {
            Task { @MainActor [weak self] in
                self?.error = error
                self?.logger.error("VAD frame processing error: \(error)")
            }
        }
    }

    /// Update ring buffer with new audio frame
    /// - Parameter frame: New audio frame to add
    private func updateRingBuffer(with frame: [Int16]) {
        // Direct sample-based buffer management for maximum precision
        if ringBuffer.count + frame.count > maxRingBufferSize {
            // Calculate how many samples to remove
            let excessSamples = (ringBuffer.count + frame.count) - maxRingBufferSize

            // Keep the most recent samples
            if excessSamples < ringBuffer.count {
                ringBuffer.removeFirst(excessSamples)
            } else {
                ringBuffer.removeAll()
            }
        }

        // Add new frame samples to the ring buffer
        ringBuffer.append(contentsOf: frame)
    }

    /// Calculate energy level of audio samples with better weighting
    private func calculateEnergy(_ samples: [Int16]) -> Float {
        guard !samples.isEmpty else { return 0 }

        var sum: Float = 0
        var weightedCount: Float = 0

        // Apply slight bias to more recent samples
        let sampleCount = Float(samples.count)

        for (i, sample) in samples.enumerated() {
            let weight = 0.5 + (0.5 * Float(i) / sampleCount) // 0.5-1.0 weight range
            let value = Float(sample) * weight
            sum += value * value
            weightedCount += weight
        }

        return weightedCount > 0 ? sqrt(sum / weightedCount) : 0
    }

    /// Update the adaptive silence threshold based on recent audio frames
    private func updateSilenceThreshold(frameEnergy: Float, isSpeaking: Bool) {
        // If speaking, gradually increase threshold to adapt to current voice level
        if isSpeaking && frameEnergy > currentSilenceThreshold {
            // Slow adaptation upward - 5% weight to new value
            currentSilenceThreshold = (currentSilenceThreshold * 0.95) + (frameEnergy * 0.05 * 0.3)
            // Cap at reasonable maximum
            currentSilenceThreshold = min(currentSilenceThreshold, 1500.0)
        } else {
            // Slow decay back to base threshold when silent
            currentSilenceThreshold = max(
                baseSilenceThreshold,
                currentSilenceThreshold * 0.995 // Very slow decay
            )
        }
    }

    /// Determine enhanced speaking state using both VAD result and energy level
    private func determineEnhancedSpeakingState(vadResult: Bool, frameEnergy: Float) -> Bool {
        // If VAD says speaking, trust it
        if vadResult {
            consecutiveSilentFrames = 0
            return true
        }

        // VAD says not speaking, use energy to confirm
        let effectiveThreshold = speaking ?
            currentSilenceThreshold * silenceThresholdMultiplier : // Lower threshold during speech
            currentSilenceThreshold

        // If energy is still high, override VAD result
        if frameEnergy > effectiveThreshold && speaking {
            consecutiveSilentFrames = 0
            return true
        }

        // Definitely silent
        consecutiveSilentFrames += 1
        return false
    }

    /// Apply smoothing algorithm to VAD results to prevent single-frame errors
    /// - Parameter currentVAD: Current enhanced VAD result
    /// - Returns: Smoothed speaking state
    private func determineSmoothedSpeakingState(_ currentVAD: Bool) -> Bool {
        // Non-speaking to speaking transition (quick)
        if !smoothedSpeakingState && currentVAD {
            // Check for minimum activation frames
            let recentTrueCount = recentVADHistory.suffix(minActiveFrames).filter { $0 }.count
            if recentTrueCount >= minActiveFrames {
                smoothedSpeakingState = true
            }
            return smoothedSpeakingState
        }

        // Speaking to non-speaking transition (slower)
        if smoothedSpeakingState && !currentVAD {
            // End speech only after enough consecutive silent frames
            if consecutiveSilentFrames >= minSilentFrames {
                smoothedSpeakingState = false
                logger.info("Speech ended after \(consecutiveSilentFrames) consecutive silent frames")
            }
        }

        return smoothedSpeakingState
    }

    /// Update voice state and control recording logic
    @MainActor
    private func updateVoiceState(isSpeaking: Bool, frameEnergy _: Float, frame: [Int16]) {
        if isSpeaking {
            // Speaking state handling
            activeFramesCount += 1
            accumulatedSilentFrames = 0

            // First-time speech detection
            if !speaking && activeFramesCount >= minActiveFrames {
                speaking = true
                logger.voice("Speech started")
                beginRecordingWithPreSpeech()
            }

            if speaking {
                updateVoiceVolume(frame: frame)
                resetVadTimeout()

                if recording {
                    addFrameToRecording(frame)
                }
            }
        } else {
            // Silent state handling
            activeFramesCount = 0

            if speaking {
                // When in speaking state, still record the frames during short silences
                if recording {
                    addFrameToRecording(frame)
                }

                // Track silence duration
                accumulatedSilentFrames += 1

                // End recording after sufficient silence
                // This is a faster response than waiting for consecutive frames
                if consecutiveSilentFrames >= maxSilentFrames || accumulatedSilentFrames >= maxSilentFrames {
                    speaking = false
                    logger.info("Ending recording: consecutive=\(consecutiveSilentFrames), accumulated=\(accumulatedSilentFrames)")
                    endRecording()
                }
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
        vadTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                // Only end recording if we're still in speaking state
                // This is a backup mechanism to the frame-based silence detection
                if self.speaking {
                    self.logger.info("Silence timeout reached, ending recording")
                    self.speaking = false
                    self.endRecording()
                }
            }
        }
    }

    /// Start recording and include pre-recorded frames
    private func beginRecordingWithPreSpeech() {
        logger.info("Beginning recording with \(ringBuffer.count) pre-recorded samples")

        // Start with empty recording
        currentRecording = []

        // Analyze the ring buffer to find optimal starting point
        let optimalStartIndex = findOptimalStartIndex(in: ringBuffer)

        if optimalStartIndex > 0 {
            logger.info("Trimmed \(optimalStartIndex) initial samples from pre-recording buffer")
        }

        // Add ring buffer content from the optimal starting point
        if optimalStartIndex < ringBuffer.count {
            let preRecordingSamples = Array(ringBuffer[optimalStartIndex...])
            currentRecording.append(contentsOf: preRecordingSamples)
            logger.info("Added \(preRecordingSamples.count) pre-recorded samples to recording")
        }

        recording = true
    }

    /// Find optimal starting point in audio buffer to minimize silence
    /// - Parameter buffer: Audio buffer to analyze
    /// - Returns: Index of optimal starting point
    private func findOptimalStartIndex(in buffer: [Int16]) -> Int {
        guard !buffer.isEmpty else { return 0 }

        // Parameters for start detection
        let frameSize = 160 // 10ms at 16kHz
        let threshold: Float = 350.0 // Adjust based on testing - lower for more sensitivity
        let minActivationLevel: Float = 600.0 // Lower threshold for confirmed speech

        // First pass: find any activity above basic threshold
        var firstActivityIndex = buffer.count

        // Calculate average energy for adaptive threshold
        var totalEnergy: Float = 0
        var frameCount = 0

        for i in stride(from: 0, to: buffer.count, by: frameSize) {
            let endIndex = min(i + frameSize, buffer.count)
            if endIndex - i < frameSize / 3 { break } // Skip tiny frames at the end

            let segment = Array(buffer[i ..< endIndex])
            let energy = calculateEnergy(segment)

            totalEnergy += energy
            frameCount += 1

            if energy > threshold && firstActivityIndex == buffer.count {
                firstActivityIndex = i
            }
        }

        // If no basic activity found, return a conservative position
        if firstActivityIndex >= buffer.count {
            // Return position that captures about last 100ms
            return max(0, buffer.count - 1600)
        }

        // Adaptive thresholds based on buffer content
        let avgEnergy = frameCount > 0 ? totalEnergy / Float(frameCount) : 0
        let adaptiveThreshold = max(minActivationLevel, avgEnergy * 1.5)

        // Second pass: look for confirmed speech starting from first activity
        // This finds the true speech onset, avoiding small pre-utterance noises
        for i in stride(from: max(0, firstActivityIndex - frameSize), to: buffer.count, by: frameSize / 2) {
            let endIndex = min(i + frameSize, buffer.count)
            let segment = Array(buffer[i ..< endIndex])
            let energy = calculateEnergy(segment)

            if energy > adaptiveThreshold {
                // Found confirmed speech - backtrack a bit to catch speech onset
                let backtrackFrames = 3 // Backtrack 3 frames (30ms) to catch speech onset
                let startIndex = max(0, i - (frameSize * backtrackFrames))
                return startIndex
            }
        }

        // If no confirmed speech found, start from first activity with generous backtracking
        return max(0, firstActivityIndex - frameSize * 2)
    }

    /// Add frame to recording with overlap for smooth transitions
    private func addFrameToRecording(_ frame: [Int16]) {
        if let lastFrame = lastAudioFrame, !lastFrame.isEmpty {
            // Apply cross-fade at the boundaries for smooth transitions
            let overlapSize = min(frameOverlap, min(lastFrame.count, frame.count))

            // Skip overlap if either frame is too small
            if overlapSize > 0 {
                for i in 0 ..< overlapSize {
                    // Calculate crossfade weights
                    let weight1 = Float(overlapSize - i) / Float(overlapSize) // Decreases from 1.0 to 0.0
                    let weight2 = Float(i) / Float(overlapSize) // Increases from 0.0 to 1.0

                    // Apply weighted average for overlapping samples
                    let lastSample = Float(lastFrame[lastFrame.count - overlapSize + i])
                    let newSample = Float(frame[i])
                    let blendedSample = (lastSample * weight1) + (newSample * weight2)

                    // Update the last sample in previous frame with the blended value
                    currentRecording[currentRecording.count - overlapSize + i] = Int16(blendedSample)
                }

                // Add the remaining samples from the new frame (after overlap)
                if frame.count > overlapSize {
                    currentRecording.append(contentsOf: frame[overlapSize...])
                }
            } else {
                // No overlap possible, just append
                currentRecording.append(contentsOf: frame)
            }
        } else {
            // First frame, just add it
            currentRecording.append(contentsOf: frame)
        }

        // Save last frame for next overlap processing
        lastAudioFrame = frame
    }

    /// Trim trailing silence from recording using adaptive threshold
    private func trimTrailingSilence(_ recording: [Int16]) -> [Int16] {
        guard recording.count > 320 else { return recording }

        let frameSize = 160
        let minKeepFrames = 5 // Minimum frames to keep after last speech (more generous)

        // Calculate adaptive threshold based on average energy in recording
        var totalEnergy: Float = 0
        var frameCount = 0

        for i in stride(from: 0, through: recording.count - frameSize, by: frameSize) {
            let endIdx = min(i + frameSize, recording.count)
            let frame = Array(recording[i ..< endIdx])
            totalEnergy += calculateEnergy(frame)
            frameCount += 1
        }

        // Use adaptive threshold - lower for quiet recordings, higher for loud ones
        let avgEnergy = frameCount > 0 ? totalEnergy / Float(frameCount) : 0
        let threshold = max(250.0, min(800.0, avgEnergy * 0.12)) // More sensitive threshold

        // Process in reverse to find the last non-silent frame
        var lastSpeechIndex = recording.count

        for i in stride(from: recording.count - frameSize, through: 0, by: -frameSize) {
            let startIdx = max(0, i)
            let endIdx = min(startIdx + frameSize, recording.count)
            let frame = Array(recording[startIdx ..< endIdx])

            let energy = calculateEnergy(frame)
            if energy > threshold {
                // Found the last non-silent frame
                lastSpeechIndex = endIdx
                break
            }
        }

        // Keep more frames after the last speech to avoid abrupt endings
        let endPosition = min(lastSpeechIndex + (frameSize * minKeepFrames), recording.count)

        logger.info("Trimmed \(recording.count - endPosition) samples from end of recording")

        return Array(recording[0 ..< endPosition])
    }

    /// End recording and finalize audio data
    @MainActor
    private func endRecording() {
        recording = false
        logger.info("Recording ended, total samples: \(currentRecording.count)")

        // Verify minimum recording duration to avoid false triggers
        let minSamples = minRecordingFrames * 160
        if currentRecording.count < minSamples {
            logger.warning("Recording too short (\(currentRecording.count) samples < minimum \(minSamples)), discarding")
            currentRecording.removeAll()
            resetStateCounters()
            return
        }

        // Trim trailing silence
        let trimmedRecording = trimTrailingSilence(currentRecording)

        // Normalize recording levels for consistent volume
        let normalizedRecording = normalizeAudioLevels(trimmedRecording)
        recordedAudioData = normalizedRecording

        currentRecording.removeAll()
        resetStateCounters()

        if let audioData = recordedAudioData {
            let durationInSeconds = Float(audioData.count) / Float(sampleRate)
            logger.success("Recording complete, samples: \(audioData.count), duration: \(String(format: "%.2f", durationInSeconds)) seconds")
        } else {
            logger.error("No audio data recorded")
        }
    }

    /// Normalize audio levels for consistent volume
    private func normalizeAudioLevels(_ samples: [Int16]) -> [Int16] {
        guard !samples.isEmpty else { return samples }

        // Find peak value
        var peakValue: Float = 0
        for sample in samples {
            let absValue = abs(Float(sample))
            if absValue > peakValue {
                peakValue = absValue
            }
        }

        // If peak is already near maximum or very low, apply appropriate normalization
        if peakValue < 100 || peakValue > 32000 {
            let targetPeak: Float = 24000 // Target peak level (75% of max)
            let scaleFactor = peakValue > 0 ? targetPeak / peakValue : 1.0

            logger.info("Normalizing audio with scale factor: \(String(format: "%.2f", scaleFactor))")

            // Apply normalization with clipping protection
            return samples.map { sample in
                let scaledValue = Float(sample) * scaleFactor
                let clippedValue = max(-32767, min(32767, scaledValue))
                return Int16(clippedValue)
            }
        }

        return samples
    }

    /// Reset all state counters and buffers
    private func resetStateCounters() {
        activeFramesCount = 0
        silentFramesCount = 0
        accumulatedSilentFrames = 0
        consecutiveSilentFrames = 0
        recentVADHistory.removeAll()
        smoothedSpeakingState = false
        lastVADResult = false
        lastAudioFrame = nil
        currentSilenceThreshold = baseSilenceThreshold

        // Don't clear ring buffer when stopping recording
        // This allows capturing speech that starts immediately after a previous recording
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
