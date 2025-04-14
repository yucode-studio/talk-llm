//
//  VADEngine.swift
//  Talk
//
//  Created by Yu on 2025/4/8.
//

protocol VADEngine {
    func process(frame: [Int16]) throws -> Bool

    static var frameLength: UInt32 { get }

    static var sampleRate: UInt32 { get }

    func delete()
}
