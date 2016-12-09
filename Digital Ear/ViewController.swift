//
//  ViewController.swift
//  Digital Ear
//
//  Created by Alex Reidy on 3/5/15.
//  Copyright (c) 2015 Alex Reidy. All rights reserved.
//

import UIKit
import AVFoundation

/*
let soundsForScreenshot: [(timestamp: Int, soundName: String)] = [
    (now()-60*65*2-26, "the doorbell"),
    (now()-60*65*2-20, "the door opening"),
    (now()-60*12-3, "the microwave"),
    (now()-60*1-3, "the sink"),
    (now()-42, "the oven"),
    (now()-27, "the smoke detector!"),
]*/

class ViewController: UIViewController, UITableViewDataSource {
    
    var camera: AVCaptureDevice? = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    var flashing = false
    
    var notification = UILocalNotification()
    
    var recognizedSounds: [(timestamp: Int, soundName: String)] = []
    
    @IBOutlet weak var tableForRecognizedSounds: UITableView!
    
    @IBOutlet weak var powerSwitch: UISwitch!
    
    func vibrate(_ times: Int, interval: Double = 1) {
        for i in 0 ..< times {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            Thread.sleep(forTimeInterval: interval)
        }
    }
    
    func onSoundRecognized(_ sound: Sound) {
        let slstr = "Sounds like \(sound.name)"
        print(slstr)
        let sn: String = sound.name // won't let me pass sound.name raw ???
        recognizedSounds.append((timestamp: now(), soundName: sn))
        tableForRecognizedSounds.reloadData()
        
        if inBackgroundMode {
            notification.alertBody = slstr
            UIApplication.shared.presentLocalNotificationNow(notification)
        }
        
        if sound.flashWhenRecognized {
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async(execute: {
                self.flash(0.4, times: 5)
            })
        }
        if sound.vibrateWhenRecognized {
            ear?.stop()
            if inBackgroundMode {
                vibrate(3)
                ear?.listen()
            } else {
                DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async(execute: {
                    self.vibrate(5)
                    self.ear?.listen()
                })
            }
        }
        
    }
    
    var ear: Ear?
    
    @IBAction func onButtonToggled(_ sender: AnyObject) {
        if sender is UISwitch {
            let s: UISwitch = sender as! UISwitch
            if s.isOn {
                ear?.listen()
            } else {
                ear?.stop()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recognizedSounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.value2, reuseIdentifier: nil)
        
        let rs = recognizedSounds[recognizedSounds.count - 1 - indexPath.row]
        let minutesSinceRecognized: Int = Int(floor(Double(now() - rs.timestamp) / 60.0))
        
        cell.detailTextLabel?.text = "Sounds like \(rs.soundName) (\(formatTimeSince(rs.timestamp)))"
        
        return cell
    }
    
    @IBAction func unwindToMainView(_ segue: UIStoryboardSegue) {
        if powerSwitch.isOn {
            ear?.listen()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        ear?.stop()
        if let cam = camera {
            try! cam.lockForConfiguration()
            if cam.isTorchModeSupported(AVCaptureTorchMode.off) {
                cam.torchMode = AVCaptureTorchMode.off
            }
            cam.unlockForConfiguration()
        }
    }
    
    func setFlashLevel(_ level: Float) {
        if let cam = camera {
            try? cam.lockForConfiguration()
            if cam.hasTorch && cam.isTorchModeSupported(AVCaptureTorchMode.off) &&
                cam.isTorchModeSupported(AVCaptureTorchMode.on) {
                if cam.isTorchAvailable {
                    if level == 0 {
                        cam.torchMode = AVCaptureTorchMode.off
                    } else {
                        try? cam.setTorchModeOnWithLevel(level)
                    }
                }
            } else if cam.hasFlash && cam.isFlashModeSupported(AVCaptureFlashMode.off) &&
                cam.isFlashModeSupported(AVCaptureFlashMode.on) {
                if cam.isFlashAvailable {
                    if level == 0 {
                        cam.flashMode = AVCaptureFlashMode.off
                    } else {
                        cam.flashMode = AVCaptureFlashMode.on
                    }
                }
            }
            cam.unlockForConfiguration()
        }
    }
    
    func flash(_ interval: Double, times: Int) {
        // interval is in seconds
        if flashing { return }
        flashing = true
        var on = true
        for i in 0 ..< times * 2 {
            if on { setFlashLevel(0.9) } else { setFlashLevel(0) }
            Thread.sleep(forTimeInterval: interval)
            on = !on
        }
        flashing = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableForRecognizedSounds.dataSource = self
        
        UserDefaults().set(true, forKey: "unlimited")
        
        UIApplication.shared.registerUserNotificationSettings(
            UIUserNotificationSettings(types: UIUserNotificationType.alert, categories: nil))
        
        ear = Ear(onSoundRecognized: onSoundRecognized, sampleRate: DEFAULT_SAMPLE_RATE)
        
        if let e = self.ear {
            e.listen()
        }
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async(execute: {
            while true {
                OperationQueue.main.addOperation({
                    self.tableForRecognizedSounds.reloadData()
                })
                Thread.sleep(forTimeInterval: 5)
            }
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }


}
