//
//  AudioHelper.swift
//  Talk
//
//  Created by Yu on 2025/4/8.
//

import Foundation

enum AudioHelper {
    static func convertToWavData(_ pcmData: [Int16], sampleRate: UInt32 = 16000, numChannels: UInt16 = 1, bitsPerSample: UInt16 = 16) -> Data {
        let byteRate = sampleRate * UInt32(numChannels) * UInt32(bitsPerSample / 8)
        let blockAlign = numChannels * (bitsPerSample / 8)
        let dataSize = UInt32(pcmData.count * MemoryLayout<Int16>.size)
        let chunkSize = 36 + dataSize

        var header = Data()
        header.append("RIFF".data(using: .ascii)!) // ChunkID
        header.append(Data(from: chunkSize)) // ChunkSize
        header.append("WAVEfmt ".data(using: .ascii)!) // Format + Subchunk1ID
        header.append(Data(from: UInt32(16))) // Subchunk1Size (PCM)
        header.append(Data(from: UInt16(1))) // AudioFormat (1 = PCM)
        header.append(Data(from: numChannels)) // NumChannels
        header.append(Data(from: sampleRate)) // SampleRate
        header.append(Data(from: byteRate)) // ByteRate
        header.append(Data(from: blockAlign)) // BlockAlign
        header.append(Data(from: bitsPerSample)) // BitsPerSample
        header.append("data".data(using: .ascii)!) // Subchunk2ID
        header.append(Data(from: dataSize)) // Subchunk2Size

        let audioData = pcmData.withUnsafeBytes { Data($0) }
        header.append(audioData)

        print("WAV header: SampleRate=\(sampleRate)Hz, Channels=\(numChannels), BitsPerSample=\(bitsPerSample)")

        return header
    }
}
