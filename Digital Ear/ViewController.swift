//
//  ViewController.swift
//  Digital Ear
//
//  Created by Alex Reidy on 3/5/15.
//  Copyright (c) 2015 Alex Reidy. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UITableViewDataSource {
    
    var camera: AVCaptureDevice? = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    var flashing = false
    
    var recognizedSounds: [(timestamp: Int, soundName: String)] = []
    
    @IBOutlet weak var tableForRecognizedSounds: UITableView!
    
    func onSoundRecognized(sname: String) {
        println("Sounds like \(sname)")
        recognizedSounds.append((timestamp: now(), soundName: sname))
        tableForRecognizedSounds.reloadData()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            self.flash(0.4, times: 5)
        })
    }
    
    var ear: Ear?
    
    @IBAction func onButtonToggled(sender: AnyObject) {
        if sender is UISwitch {
            let s: UISwitch = sender as! UISwitch
            if s.on {
                ear?.listen()
            } else {
                ear?.stop()
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recognizedSounds.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Value2, reuseIdentifier: nil)
        
        let rs = recognizedSounds[recognizedSounds.count - 1 - indexPath.row]
        let minutesSinceRecognized: Int = Int(floor(Double(now() - rs.timestamp) / 60.0))
        
        cell.detailTextLabel?.text = "Sounds like \(rs.soundName) (\(formatTimeSince(rs.timestamp)))"
        
        return cell
    }
    
    @IBAction func unwindToMainView(segue: UIStoryboardSegue) {
        ear?.listen()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        ear?.stop()
        if let cam = camera {
            cam.lockForConfiguration(nil)
            if cam.isTorchModeSupported(AVCaptureTorchMode.Off) {
                cam.torchMode = AVCaptureTorchMode.Off
            }
            cam.unlockForConfiguration()
        }
    }
    
    func setFlashLevel(level: Float) {
        if let cam = camera {
            cam.lockForConfiguration(nil)
            if cam.hasTorch && cam.isTorchModeSupported(AVCaptureTorchMode.Off) &&
                cam.isTorchModeSupported(AVCaptureTorchMode.On) {
                if cam.torchAvailable {
                    if level == 0 {
                        cam.torchMode = AVCaptureTorchMode.Off
                    } else {
                        cam.setTorchModeOnWithLevel(level, error: nil)
                    }
                }
            } else if cam.hasFlash && cam.isFlashModeSupported(AVCaptureFlashMode.Off) &&
                cam.isFlashModeSupported(AVCaptureFlashMode.On) {
                if cam.flashAvailable {
                    if level == 0 {
                        cam.flashMode = AVCaptureFlashMode.Off
                    } else {
                        cam.flashMode = AVCaptureFlashMode.On
                    }
                }
            }
            cam.unlockForConfiguration()
        }
    }
    
    func flash(interval: Double, times: Int) {
        // interval is in seconds
        if flashing { return }
        flashing = true
        var on = true
        for var i = 0; i < times * 2; i++, on = !on {
            if on { setFlashLevel(0.9) } else { setFlashLevel(0) }
            NSThread.sleepForTimeInterval(interval)
        }
        flashing = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableForRecognizedSounds.dataSource = self
                        
        ear = Ear(onSoundRecognized: onSoundRecognized, sampleRate: DEFAULT_SAMPLE_RATE)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            if let e = self.ear {
                e.listen()
            }
        })
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            while true {
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    self.tableForRecognizedSounds.reloadData()
                })
                NSThread.sleepForTimeInterval(5)
            }
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}