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
        
        CGContextSetRGBFillColor(ctx, 48.0/255.0, 48.0/255.0, 48.0/255.0, 1.0)
        CGContextFillRect(ctx, CGRectMake(0, 0, self.frame.width, self.frame.height))
        
        CGContextSetRGBFillColor(ctx, 31.0/255.0, 239.0/255.0, 156.0/255.0, 1.0)
        for var k = 0; k < N_BARS; k++ {
            let avgAmplitude: Float = average(Array(samples[k * SAMPLES_PER_BAR..<(k+1) * SAMPLES_PER_BAR]))
            let r = CGRectMake(CGFloat(Float(k) * dx), CGFloat(self.frame.height/2), CGFloat(dx),
                CGFloat(avgAmplitude * 5 * Float(self.frame.height)))
            CGContextFillRect(ctx, r)
        }
    }
}