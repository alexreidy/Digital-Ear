//
//  Util.swift
//  Digital Ear
//
//  Created by Alex Reidy on 3/7/15.
//  Copyright (c) 2015 Alex Reidy. All rights reserved.
//

import Foundation
import AVFoundation

let MAX_REC_DURATION: Double = 5 // seconds
let DOCUMENT_DIR = NSHomeDirectory() + "/Documents/"

let utilAudioSession = AVAudioSession()
var utilAudioRecorder: AVAudioRecorder?
var utilAudioPlayer: AVAudioPlayer?

let DEFAULT_SAMPLE_RATE = 44100
let defaultAudioSettings: [AnyHashable: Any] = [
    AVFormatIDKey: kAudioFormatLinearPCM,
    AVLinearPCMIsFloatKey: true,
    AVNumberOfChannelsKey: 1,
    AVSampleRateKey: DEFAULT_SAMPLE_RATE,
]

func timestampDouble() -> Double { return Date().timeIntervalSince1970 }
func now() -> Int { return time(nil) }

func sign(_ x: Float) -> Int {
    if x < 0 { return -1 }
    return 1
}

func max(_ nums: [Float]) -> Float {
    var max: Float = -MAXFLOAT
    for n in nums {
        if n > max {
            max = n
        }
    }
    return max
}

func average(_ data: [Float], absolute: Bool = false) -> Float {
    // If absolute, return the average absolute distance from zero
    var sum: Float = 0
    for x in data {
        if absolute {
            sum += abs(x)
        } else {
            sum += x
        }
    }
    return sum / Float(data.count)
}

func startRecordingAudio(toPath path: String, delegate: AVAudioRecorderDelegate? = nil,
    seconds: Double = MAX_REC_DURATION) {
    // if utilAudioRecorder == nil ??? don't want to record while recording...
    utilAudioRecorder = try! AVAudioRecorder(url: URL(fileURLWithPath: path), settings: defaultAudioSettings as! [String: Any])
    if let recorder = utilAudioRecorder {
        recorder.delegate = delegate
        recorder.record(forDuration: seconds)
    }
}

func stopRecordingAudio() {
    if let recorder = utilAudioRecorder {
        recorder.stop()
        utilAudioRecorder = nil
    }
}

func recording() -> Bool {
    if let recorder = utilAudioRecorder {
        return recorder.isRecording
    }
    return false
}

func playAudio(_ filePath: String) {
    try! utilAudioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
    utilAudioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: filePath))
    if let player = utilAudioPlayer {
        player.volume = 1
        if player.play() {
            print("playing")
        }
    }
}

func extractSamplesFromWAV(_ path: String) -> [Float] {
    let audioFile: AVAudioFile?
    do {
        audioFile = try AVAudioFile(forReading: URL(fileURLWithPath: path), commonFormat: AVAudioCommonFormat.pcmFormatFloat32, interleaved: false)
    } catch {
        audioFile = nil
        print("Error opening audio file with path \(path), and error: \(error)")
        return [Float]()
    }

    guard let af = audioFile else {
        return [Float]()
    }
    
    let N_SAMPLES = Int(af.length)
    
    let buffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(settings: defaultAudioSettings as! [String: Any]),
        frameCapacity: AVAudioFrameCount(N_SAMPLES))
    
    
    do {
        try af.read(into: buffer, frameCount: AVAudioFrameCount(N_SAMPLES))
    } catch {
        print("problem reading \(error)")
        return [Float]()
    }
    
    var samples = [Float](repeating: 0.0, count: N_SAMPLES)
    for i in 0 ..< N_SAMPLES {
        if let data = buffer.floatChannelData {
            samples[i] = data.pointee[i]
        }
    }
    
    return samples
}

func formatTimeBetween(_ startTime: Int, endTime: Int) -> String {
    if endTime < startTime { return "error" }
    let secondsElapsed = endTime - startTime
    if secondsElapsed >= 3600 * 24 {
        let days = secondsElapsed / (3600 * 24)
        let hours = (secondsElapsed % (3600 * 24)) / 3600
        return "\(days)d, \(hours)h"
    }
    if secondsElapsed >= 3600 {
        let hours = secondsElapsed / 3600
        let seconds = secondsElapsed % 3600
        let minutes = seconds / 60
        return "\(hours)h, \(minutes)m"
    }
    if secondsElapsed >= 60 {
        let minutesElapsed: Int = secondsElapsed / 60
        let seconds: Int = secondsElapsed % 60
        return "\(minutesElapsed)m, \(seconds)s"
    }
    return "\(secondsElapsed)s"
}

func formatTimeSince(_ time: Int) -> String {
    return formatTimeBetween(time, endTime: now())
}

func canAddSound() -> Bool {
    if UserDefaults().bool(forKey: "unlimited") || getSoundNames().count < 1 {
        return true
    }
    return false
}

import StoreKit
extension SKProduct {
    // Thanks to Ben Dodson
    func localizedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)!
    }
    
}
