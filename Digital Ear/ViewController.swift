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
    
    var recognizedSounds: [(timestamp: Int, soundName: String)] = []
    
    @IBOutlet weak var tableForRecognizedSounds: UITableView!
    
    func onSoundRecognized(sname: String) {
        println("Sounds like \(sname)")
        recognizedSounds.append((timestamp: now(), soundName: sname))
        tableForRecognizedSounds.reloadData()
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    var ear: Ear?
    
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