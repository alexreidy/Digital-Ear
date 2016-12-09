//
//  Ear.swift
//  Digital Ear
//
//  Created by Alex Reidy on 3/7/15.
//  Copyright (c) 2015 Alex Reidy. All rights reserved.
//

import Foundation
import AVFoundation

class Ear: NSObject, AVAudioRecorderDelegate {
    
    fileprivate let audioSession = AVAudioSession()
    
    fileprivate var recorder: AVAudioRecorder!
    
    var settings: [String: Any] = defaultAudioSettings as! [String: Any]
    
    fileprivate var onSoundRecognized: (_ sound: Sound) -> ()
    var soundsRecognizedLastAnalysis = Set<String>()
    
    fileprivate var shouldStopRecording = false
    
    fileprivate var sounds: [Sound] = []
    fileprivate var freqListForWAV = [String : [Float]]() // cache
    
    fileprivate let secondsToRecord: Double = 7
    
    fileprivate let tempWav = "tmp.wav"
        
    init(onSoundRecognized: @escaping (_ sound: Sound) -> (), sampleRate: Int) {
        self.onSoundRecognized = onSoundRecognized
        
        try! audioSession.setCategory(AVAudioSessionCategoryRecord)
        try! audioSession.setMode(AVAudioSessionModeMeasurement)
        try! audioSession.setActive(true)
        
        settings[AVSampleRateKey] = sampleRate
    }
    
    class func adjustForNoiseAndTrimEnds(_ samples: [Float]) -> [Float] {
        // At low amplitudes, the fluctuation across "zero" due to noise
        // is actually quite pronounced, resulting in high frequencies when
        // it's quiet, so we basically change all of the negligibly small amplitudes to zero.
        // Additionally, we remove any leading or trailing zeros before returning.
        
        var noiseAdjustedSamples = samples
        var firstNonzeroAmplitudeIndex = 0, lastNonzeroAmplitudeIndex = 0
        
        let SAMPLES_PER_CHUNK = DEFAULT_SAMPLE_RATE / 4
        
        for k in 0 ..< samples.count / SAMPLES_PER_CHUNK {
            let chunk: [Float] = Array(noiseAdjustedSamples[k * SAMPLES_PER_CHUNK ..< (k+1) * SAMPLES_PER_CHUNK])
            if abs(average(chunk, absolute: true)) < 0.0001 {
                for i in k * SAMPLES_PER_CHUNK ..< (k+1) * SAMPLES_PER_CHUNK {
                    noiseAdjustedSamples[i] = 0.0
                }
                continue
            }
            lastNonzeroAmplitudeIndex = (k+1) * SAMPLES_PER_CHUNK
            if firstNonzeroAmplitudeIndex == 0 {
                firstNonzeroAmplitudeIndex = k * SAMPLES_PER_CHUNK
            }
        }
        
        return Array(noiseAdjustedSamples[
            firstNonzeroAmplitudeIndex..<lastNonzeroAmplitudeIndex])
    }
    
    class func countCyclesIn(_ samples: [Float]) -> Int {
        if samples.count == 0 { return 0 }
        
        var zeroCrossings = 0
        var prevSign = sign(samples[0])
        
        for amplitude in samples {
            var currentSign = sign(amplitude)
            if currentSign == -prevSign {
                zeroCrossings += 1
            }
            prevSign = currentSign
        }
        
        return Int(round(Float(zeroCrossings) / 2.0))
    }
    
    class func countFrequencyIn(_ samples: [Float], sampleRate: Int) -> Float {
        let cycles = countCyclesIn(samples)
        let seconds: Float = Float(samples.count) / Float(sampleRate)
        return Float(cycles) / seconds
    }
    
    fileprivate func range(_ data: [Float]) -> Float {
        var max = -MAXFLOAT, min = MAXFLOAT
        for x in data {
            if x > max { max = x }
            if x < min { min = x }
        }
        return max - min
    }
    
    fileprivate func meanDeviation(_ data: [Float]) -> Float {
        var deviationSum: Float = 0
        let mean = average(data)
        for x in data {
            deviationSum += abs(x - mean)
        }
        return deviationSum / Float(data.count)
    }
    
    fileprivate func createFrequencyArray(_ samples: [Float], sampleRate: Int, freqChunksPerSec: Int = 50) -> [Float] {
        // TODO - refactor with slices (?)
        
        let samplesPerChunk = sampleRate / freqChunksPerSec
        if samples.count < samplesPerChunk {
            // In this case, would return [] without the explicit
            // statement, but this saves some CPU cycles
            return []
        }
        
        var freqArray: [Float] = []
        var samplesForChunk = [Float](repeating: 0.0, count: samplesPerChunk)
        var i = 0
        
        for n in 0 ..< samples.count {
            if i == samplesForChunk.count {
                freqArray.append(Ear.countFrequencyIn(samplesForChunk, sampleRate: sampleRate))
                i = 0
                continue
            }
            
            samplesForChunk[i] = samples[n]
            i += 1
        }
        
        return freqArray
    }
    
    fileprivate func calcAverageRelativeFreqDiff(_ freqListA: [Float], freqListB: [Float]) -> Float {
        // We "slide" the smaller freqList across the larger one and compare each frequency
        // to compute the minimum average relative difference in frequency (a proportion)
        
        var largeFreqList: [Float] = freqListB
        var smallFreqList: [Float] = freqListA
        if freqListA.count > freqListB.count {
            largeFreqList = freqListA
            smallFreqList = freqListB
        }
        
        if freqListA.count == 0 && freqListB.count == 0 {
            return 0
        }
        if smallFreqList.count == 0 {
            // NO frequency can't be similar to SOME frequencies
            return 1
        }
        // Notice that this point reached => smallFreqList is not empty
        if largeFreqList.count == 0 {
            return 1
        }
        
        let freqListLenDiff = largeFreqList.count - smallFreqList.count
        var minAvgRelativeFreqDiff: Float = 1

        for indexOffset in 0 ... freqListLenDiff {
            var relativeFreqDiffSum: Float = 0

            for i in 0 ..< smallFreqList.count {
                let base: Float = max(smallFreqList[i], largeFreqList[i + indexOffset])
                if base > 0 {
                    relativeFreqDiffSum += abs(smallFreqList[i] - largeFreqList[i + indexOffset]) / base
                }
            }
            
            let avgRelativeFreqDiff = relativeFreqDiffSum / Float(smallFreqList.count)
            
            if avgRelativeFreqDiff < minAvgRelativeFreqDiff {
                minAvgRelativeFreqDiff = avgRelativeFreqDiff
            }
        }
        
        return minAvgRelativeFreqDiff
    }
    
    var prevSamplesInQuestion: [Float] = []
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder!, successfully flag: Bool) {
        if shouldStopRecording { return }
        print("finished recording; processing...")
        
        let sampleRate = settings[AVSampleRateKey] as! Int
        var samplesInQuestion = prevSamplesInQuestion
        if samplesInQuestion.count > 5 * sampleRate {
            // At most, samplesInQuestion is (5 + secondsToRecord) * sampleRate samples long
            let startIndex = samplesInQuestion.count - 5 * sampleRate
            samplesInQuestion = Array(samplesInQuestion[startIndex..<samplesInQuestion.count])
        }
        samplesInQuestion += Ear.adjustForNoiseAndTrimEnds(
            extractSamplesFromWAV(NSTemporaryDirectory()+tempWav))
        
        var freqListA = createFrequencyArray(samplesInQuestion, sampleRate: DEFAULT_SAMPLE_RATE)
        
        prevSamplesInQuestion = samplesInQuestion
        
        var soundsRecognized = Set<String>()
        
        for sound in sounds {
            for rec in sound.recordings {
                let fileName = rec.value(forKey: "fileName") as! String
                
                var freqListB: [Float] = []
                if let freqList = freqListForWAV[fileName] {
                    freqListB = freqList
                } else {
                    var samplesInSavedRecording = extractSamplesFromWAV(DOCUMENT_DIR+"\(fileName).wav") // Ear.adjustForNoiseAndTrimEnds(extractSamplesFromWAV(DOCUMENT_DIR+"\(fileName).wav"))
                    freqListB = createFrequencyArray(samplesInSavedRecording,
                        sampleRate: DEFAULT_SAMPLE_RATE)
                }
                
                var maxRelativeFreqDiffForRecognition: Float = 0.13
                if meanDeviation(freqListB) < 250 {
                    maxRelativeFreqDiffForRecognition = 0.07
                }
                
                let averageFreqDiff = calcAverageRelativeFreqDiff(freqListA, freqListB: freqListB)
                print(sound.name + " \(averageFreqDiff)")
                
                if averageFreqDiff <= maxRelativeFreqDiffForRecognition {
                    if !soundsRecognizedLastAnalysis.contains(sound.name) {
                        onSoundRecognized(sound)
                        soundsRecognized.insert(sound.name)
                    }
                    // Sound has been recognized, so we don't analyze any more of its recordings
                    break
                }
            }
        }
        
        soundsRecognizedLastAnalysis = soundsRecognized
        
        if !shouldStopRecording {
            return listen()
        }
    }
    
    fileprivate func recordAudio(toPath path: String, seconds: Double) {
        recorder = try! AVAudioRecorder(url: URL(fileURLWithPath: path), settings: settings)
        recorder.delegate = self
        recorder.record(forDuration: seconds)
    }
    
    fileprivate var lastFreqCacheUpdateTime = now() - 60
    fileprivate var shouldTryFreqCacheUpdate: Bool {
        get {
            let time = now()
            if time - lastFreqCacheUpdateTime >= 30 {
                lastFreqCacheUpdateTime = time
                return true
            }
            return false
        }
    }
    
    func listen() {
        print("going to listen")
        shouldStopRecording = false
        
        if shouldTryFreqCacheUpdate {
            sounds = getSounds()
            print("trying freq cache update")
            var fileNames: [String] = []
            for sound in sounds {
                for rec in sound.recordings {
                    let fileName = rec.value(forKey: "fileName") as! String
                    fileNames.append(fileName)
                    if !freqListForWAV.keys.contains(fileName) {
                        print("adding freqList to cache")
                        freqListForWAV[fileName] = createFrequencyArray(Ear.adjustForNoiseAndTrimEnds(
                            extractSamplesFromWAV(DOCUMENT_DIR+"\(fileName).wav")),
                            sampleRate: DEFAULT_SAMPLE_RATE)
                    }
                }
            }
            // If there's a freqList in the cache with a fileName that
            // no longer exists, delete dict entry.
            for fn in freqListForWAV.keys {
                if !fileNames.contains(fn) {
                    print("removing freqList from cache")
                    freqListForWAV.removeValue(forKey: fn)
                }
            }
        }
        
        // Notice the indirect tail recursion starting here.
        // recordAudio() tells recorder to record and call its delegate's didFinishRecording
        // method (implemented above) when finished, which calls this listen() method again.
        // I'm only guessing that recorder object calls
        // self.delegate.audioRecorderDidFinishRecording() as its tail call.
        // Otherwise there might theoretically be a call stack mem leak.
        return recordAudio(toPath: NSTemporaryDirectory()+tempWav, seconds: secondsToRecord)
    }
    
    func stop() {
        print("stopped listening")
        shouldStopRecording = true
        recorder.stop()
    }

}
