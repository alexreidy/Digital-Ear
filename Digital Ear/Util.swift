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
let defaultAudioSettings: [NSObject : AnyObject] = [
    AVFormatIDKey: kAudioFormatLinearPCM,
    AVLinearPCMIsFloatKey: true,
    AVNumberOfChannelsKey: 1,
    AVSampleRateKey: DEFAULT_SAMPLE_RATE,
]

func timestampDouble() -> Double { return NSDate().timeIntervalSince1970 }
func now() -> Int { return time(nil) }

func sign(x: Float) -> Int {
    if x < 0 { return -1 }
    return 1
}

func max(nums: [Float]) -> Float {
    var max: Float = -MAXFLOAT
    for n in nums {
        if n > max {
            max = n
        }
    }
    return max
}

func average(data: [Float], absolute: Bool = false) -> Float {
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
    utilAudioRecorder = AVAudioRecorder(URL: NSURL(fileURLWithPath: path),
        settings: defaultAudioSettings, error: nil)
    if let recorder = utilAudioRecorder {
        recorder.delegate = delegate
        recorder.recordForDuration(seconds)
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
        return recorder.recording
    }
    return false
}

func playAudio(filePath: String) {
    utilAudioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, error: nil)
    utilAudioPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: filePath), error:nil)
    if let player = utilAudioPlayer {
        player.volume = 1
        if player.play() {
            println("playing")
        }
    }
}

func extractSamplesFromWAV(path: String) -> [Float] {
    var af = AVAudioFile(forReading: NSURL(fileURLWithPath: path),
        commonFormat: AVAudioCommonFormat.PCMFormatFloat32,
        interleaved: false, error: nil)
    
    if af == nil {
        println("Error opening audio file with path \(path)")
        return []
    }
    
    let N_SAMPLES = Int(af.length)
    
    var buffer = AVAudioPCMBuffer(PCMFormat: AVAudioFormat(settings: defaultAudioSettings),
        frameCapacity: AVAudioFrameCount(N_SAMPLES))
    
    af.readIntoBuffer(buffer, error: nil)
    
    var samples = [Float](count: N_SAMPLES, repeatedValue: 0.0)
    for var i = 0; i < N_SAMPLES; i++ {
        samples[i] = buffer.floatChannelData.memory[i]
    }
    
    return samples
}

func formatTimeBetween(startTime: Int, endTime: Int) -> String {
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

func formatTimeSince(time: Int) -> String {
    return formatTimeBetween(time, now())
}

func canAddSound() -> Bool {
    if getSoundNames().count < 1 {
        return true
    }
    return NSUserDefaults().boolForKey("unlimited")
}

import StoreKit
extension SKProduct {
    // Thanks to Ben Dodson
    func localizedPrice() -> String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.locale = self.priceLocale
        return formatter.stringFromNumber(self.price)!
    }
    
}