#!/usr/bin/env swift
import Foundation

let sampleRate = 22_050
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "LastBeacon/Resources/Audio")
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

func littleEndianBytes<T: FixedWidthInteger>(_ value: T) -> [UInt8] {
    withUnsafeBytes(of: value.littleEndian) { Array($0) }
}

func writeWave(name: String, duration: Double, sample: (Double) -> Double) throws {
    let count = Int(Double(sampleRate) * duration)
    var pcm = Data(capacity: count * 2)
    for index in 0..<count {
        let time = Double(index) / Double(sampleRate)
        let clamped = max(-1, min(1, sample(time)))
        pcm.append(contentsOf: littleEndianBytes(Int16(clamped * Double(Int16.max))))
    }

    var wave = Data("RIFF".utf8)
    wave.append(contentsOf: littleEndianBytes(UInt32(36 + pcm.count)))
    wave.append(Data("WAVEfmt ".utf8))
    wave.append(contentsOf: littleEndianBytes(UInt32(16)))
    wave.append(contentsOf: littleEndianBytes(UInt16(1)))
    wave.append(contentsOf: littleEndianBytes(UInt16(1)))
    wave.append(contentsOf: littleEndianBytes(UInt32(sampleRate)))
    wave.append(contentsOf: littleEndianBytes(UInt32(sampleRate * 2)))
    wave.append(contentsOf: littleEndianBytes(UInt16(2)))
    wave.append(contentsOf: littleEndianBytes(UInt16(16)))
    wave.append(Data("data".utf8))
    wave.append(contentsOf: littleEndianBytes(UInt32(pcm.count)))
    wave.append(pcm)
    try wave.write(to: outputDirectory.appendingPathComponent("\(name).wav"), options: .atomic)
}

let tau = Double.pi * 2
try writeWave(name: "ambient_loop", duration: 8) { time in
    let pulse = 0.65 + 0.35 * sin(tau * 0.25 * time)
    return 0.13 * pulse * sin(tau * 110 * time)
        + 0.06 * sin(tau * 165 * time)
        + 0.035 * sin(tau * 330 * time)
}
try writeWave(name: "tower", duration: 0.16) { time in
    let envelope = exp(-22 * time)
    return 0.42 * envelope * sin(tau * (760 - 1_900 * time) * time)
}
try writeWave(name: "victory", duration: 0.62) { time in
    let envelope = min(1, time * 14) * exp(-2.4 * time)
    return 0.18 * envelope * (
        sin(tau * 440 * time) + sin(tau * 554.37 * time) + sin(tau * 659.25 * time)
    )
}
try writeWave(name: "defeat", duration: 0.62) { time in
    let envelope = min(1, time * 10) * exp(-3.2 * time)
    return 0.32 * envelope * sin(tau * (220 - 90 * time) * time)
}
