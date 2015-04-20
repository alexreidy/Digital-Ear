//
//  WaveformView.swift
//  Digital Ear
//
//  Created by Alex Reidy on 4/20/15.
//  Copyright (c) 2015 Alex Reidy. All rights reserved.
//

import Foundation
import UIKit

class WaveformView: UIView {
    
    private let N_BARS = 5000
    
    var samples: [Float] = []
    
    convenience init(frame: CGRect, samples: [Float]) {
        self.init(frame: frame)
        self.samples = Ear.adjustForNoiseAndTrimEnds(samples)
    }
    
    override func drawRect(rect: CGRect) {
        if samples.count < N_BARS {
            return
        }
        let ctx = UIGraphicsGetCurrentContext()
        let dx: Float = Float(self.frame.width) / Float(N_BARS)
        
        var SAMPLES_PER_BAR: Int = samples.count / N_BARS
        
        CGContextSetRGBFillColor(ctx, 0.0, 1.0, 0.0, 1.0)
        for var i = 0; i < N_BARS; i++ {
            
            let avgAmplitude: Float = average(Array(samples[i * SAMPLES_PER_BAR..<(i+1) * SAMPLES_PER_BAR]))
            let r = CGRectMake(CGFloat(Float(i) * dx), CGFloat(self.frame.height/2), CGFloat(dx),
                CGFloat(avgAmplitude * 5 * Float(self.frame.height)))
            CGContextFillRect(ctx, r)
        }
    }
}