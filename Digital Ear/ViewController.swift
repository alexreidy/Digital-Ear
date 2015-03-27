//
//  ViewController.swift
//  Digital Ear
//
//  Created by Alex Reidy on 3/5/15.
//  Copyright (c) 2015 Alex Reidy. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var soundLabel: UILabel!
    
    func onSoundRecognized(sname: String) {
        let slstr = "It sounds like \(sname)"
        println(slstr)
        
        soundLabel.text = slstr
        
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    var ear: Ear?
    
    @IBAction func unwindToMainView(segue: UIStoryboardSegue) {
        
        println("Unwinding to Main VC")
        
        ear?.listen()
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        println("BETTER TURN OFF RECORDING ETC")
        ear?.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        ear = Ear(onSoundRecognized: onSoundRecognized, sampleRate: 44100)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            self.ear!.listen()
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}