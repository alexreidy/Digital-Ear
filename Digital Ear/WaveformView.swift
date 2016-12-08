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
    
    fileprivate let N_BARS = 5000
    
    var samples: [Float] = []
    
    convenience init(frame: CGRect, samples: [Float]) {
        self.init(frame: frame)
        self.samples = Ear.adjustForNoiseAndTrimEnds(samples)
    }
    
    override func draw(_ rect: CGRect) {
        if samples.count < N_BARS {
            return
        }
        let ctx = UIGraphicsGetCurrentContext()
        let dx: Float = Float(self.frame.width) / Float(N_BARS)
        
        var SAMPLES_PER_BAR: Int = samples.count / N_BARS
        
        ctx?.setFillColor(red: 48.0/255.0, green: 48.0/255.0, blue: 48.0/255.0, alpha: 1.0)
        ctx?.fill(CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        
        ctx?.setFillColor(red: 31.0/255.0, green: 239.0/255.0, blue: 156.0/255.0, alpha: 1.0)
        for k in 0 ..< N_BARS {
            let avgAmplitude: Float = average(Array(samples[k * SAMPLES_PER_BAR..<(k+1) * SAMPLES_PER_BAR]))
            let r = CGRect(x: CGFloat(Float(k) * dx), y: CGFloat(self.frame.height/2), width: CGFloat(dx),
                height: CGFloat(avgAmplitude * 5 * Float(self.frame.height)))
            ctx?.fill(r)
        }
    }
}
