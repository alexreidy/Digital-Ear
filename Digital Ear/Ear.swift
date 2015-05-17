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
    
    private let audioSession = AVAudioSession()
    
    private var recorder: AVAudioRecorder!
    
    var settings = defaultAudioSettings
    
    private var onSoundRecognized: (sound: Sound) -> ()
    var soundsRecognizedLastAnalysis = Set<String>()
    
    private var shouldStopRecording = false
    
    private var sounds: [Sound] = []
    private var freqListForWAV = [String : [Float]]() // cache
    
    private let secondsToRecord: Double = 7
    
    private let tempWav = "tmp.wav"
        
    init(onSoundRecognized: (sound: Sound) -> (), sampleRate: Int) {
        self.onSoundRecognized = onSoundRecognized
        
        audioSession.setCategory(AVAudioSessionCategoryRecord, error: nil)
        audioSession.setMode(AVAudioSessionModeMeasurement, error: nil)
        audioSession.setActive(true, error: nil)
        
        settings[AVSampleRateKey] = sampleRate
    }
    
    class func adjustForNoiseAndTrimEnds(samples: [Float]) -> [Float] {
        // At low amplitudes, the fluctuation across "zero" due to noise
        // is actually quite pronounced, resulting in high frequencies when
        // it's quiet, so we basically change all of the negligibly small amplitudes to zero.
        // Additionally, we remove any leading or trailing zeros before returning.
        
        var noiseAdjustedSamples = samples
        var firstNonzeroAmplitudeIndex = 0, lastNonzeroAmplitudeIndex = 0
        
        let SAMPLES_PER_CHUNK = DEFAULT_SAMPLE_RATE / 4
        
        for var k = 0; k < samples.count / SAMPLES_PER_CHUNK; k++ {
            let chunk: [Float] = Array(noiseAdjustedSamples[k * SAMPLES_PER_CHUNK ..< (k+1) * SAMPLES_PER_CHUNK])
            if abs(average(chunk, absolute: true)) < 0.0001 {
                for var i = k * SAMPLES_PER_CHUNK; i < (k+1) * SAMPLES_PER_CHUNK; i++ {
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
    
    class func countCyclesIn(samples: [Float]) -> Int {
        if samples.count == 0 { return 0 }
        
        var zeroCrossings = 0
        var prevSign = sign(samples[0])
        
        for amplitude in samples {
            var currentSign = sign(amplitude)
            if currentSign == -prevSign {
                zeroCrossings++
            }
            prevSign = currentSign
        }
        
        return Int(round(Float(zeroCrossings) / 2.0))
    }
    
    class func countFrequencyIn(samples: [Float], sampleRate: Int) -> Float {
        let cycles = countCyclesIn(samples)
        let seconds: Float = Float(samples.count) / Float(sampleRate)
        return Float(cycles) / seconds
    }
    
    private func range(data: [Float]) -> Float {
        var max = -MAXFLOAT, min = MAXFLOAT
        for x in data {
            if x > max { max = x }
            if x < min { min = x }
        }
        return max - min
    }
    
    private func meanDeviation(data: [Float]) -> Float {
        var deviationSum: Float = 0
        let mean = average(data)
        for x in data {
            deviationSum += abs(x - mean)
        }
        return deviationSum / Float(data.count)
    }
    
    private func createFrequencyArray(samples: [Float], sampleRate: Int, freqChunksPerSec: Int = 50) -> [Float] {
        // TODO - refactor with slices (?)
        
        let samplesPerChunk = sampleRate / freqChunksPerSec
        if samples.count < samplesPerChunk {
            // In this case, would return [] without the explicit
            // statement, but this saves some CPU cycles
            return []
        }
        
        var freqArray: [Float] = []
        var samplesForChunk = [Float](count: samplesPerChunk, repeatedValue: 0.0)
        
        for var n = 0, i = 0; n < samples.count; n++, i++ {
            if i == samplesForChunk.count {
                freqArray.append(Ear.countFrequencyIn(samplesForChunk, sampleRate: sampleRate))
                i = 0
                continue
            }
            
            samplesForChunk[i] = samples[n]
        }
        
        return freqArray
    }
    
    private func calcAverageRelativeFreqDiff(freqListA: [Float], freqListB: [Float]) -> Float {
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

        for (var indexOffset = 0; indexOffset <= freqListLenDiff; indexOffset++) {
            var relativeFreqDiffSum: Float = 0
            for (var i = 0; i < smallFreqList.count; i++) {
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
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        if shouldStopRecording { return }
        println("finished recording; processing...")
        
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
                let fileName = rec.valueForKey("fileName") as! String
                
                var freqListB: [Float] = []
                if let freqList = freqListForWAV[fileName] {
                    freqListB = freqList
                } else {
                    var samplesInSavedRecording = Ear.adjustForNoiseAndTrimEnds(
                        extractSamplesFromWAV(DOCUMENT_DIR+"\(fileName).wav"))
                    freqListB = createFrequencyArray(samplesInSavedRecording,
                        sampleRate: DEFAULT_SAMPLE_RATE)
                }
                
                var maxRelativeFreqDiffForRecognition: Float = 0.16
                if meanDeviation(freqListB) < 250 {
                    maxRelativeFreqDiffForRecognition = 0.08
                }
                
                let averageFreqDiff = calcAverageRelativeFreqDiff(freqListA, freqListB: freqListB)
                println(sound.name + " \(averageFreqDiff)")
                
                if averageFreqDiff <= maxRelativeFreqDiffForRecognition {
                    if !soundsRecognizedLastAnalysis.contains(sound.name) {
                        onSoundRecognized(sound: sound)
                        soundsRecognized.insert(sound.name)
                    }
                    // Sound has been recognized, so we don't analyze any more of its recordings
                    break
                }
            }
        }
        
        soundsRecognizedLastAnalysis = soundsRecognized
        
        return listen()
    }
    
    private func recordAudio(toPath path: String, seconds: Double) {
        recorder = AVAudioRecorder(URL: NSURL(fileURLWithPath: path),
            settings: settings, error: nil)
        recorder.delegate = self
        recorder.recordForDuration(seconds)
    }
    
    private var lastFreqCacheUpdateTime = now() - 60
    private var shouldTryFreqCacheUpdate: Bool {
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
        println("going to listen")
        shouldStopRecording = false
        
        if shouldTryFreqCacheUpdate {
            sounds = getSounds()
            println("trying freq cache update")
            var fileNames: [String] = []
            for sound in sounds {
                for rec in sound.recordings {
                    let fileName = rec.valueForKey("fileName") as! String
                    fileNames.append(fileName)
                    if !contains(freqListForWAV.keys, fileName) {
                        println("adding freqList to cache")
                        freqListForWAV[fileName] = createFrequencyArray(Ear.adjustForNoiseAndTrimEnds(
                            extractSamplesFromWAV(DOCUMENT_DIR+"\(fileName).wav")),
                            sampleRate: DEFAULT_SAMPLE_RATE)
                    }
                }
            }
            // If there's a freqList in the cache with a fileName that
            // no longer exists, delete dict entry.
            for fn in freqListForWAV.keys {
                if !contains(fileNames, fn) {
                    println("removing freqList from cache")
                    freqListForWAV.removeValueForKey(fn)
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
        println("stopped listening")
        shouldStopRecording = true
        stopRecordingAudio()
    }

}