//
//  SoundViewController.swift
//  Digital Ear
//
//  Created by Alex Reidy on 3/22/15.
//  Copyright (c) 2015 Alex Reidy. All rights reserved.
//

import Foundation
import AVFoundation
import CoreData
import UIKit

class SoundViewController: UIViewController, AVAudioRecorderDelegate, UITableViewDataSource {
    
    @IBOutlet weak var titleTextField: UITextField!

    @IBOutlet weak var recordingsTableView: UITableView!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    var fileName = ""
    
    override func viewDidLoad() {
        recordingsTableView.dataSource = self
        titleTextField.text = sound.name
    }
    
    func deleteRecButtonTapped(sender: AnyObject) {
        sound.deleteRecordingWithFileName(String(sender.tag))
        recordingsTableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sound.recordings.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Value2, reuseIdentifier: nil)
        let fileName = sound.recordings[indexPath.row].valueForKey("fileName") as? String
        cell.detailTextLabel?.text = fileName
        
        let deleteButton = UIButton()
        deleteButton.setTitle("delete", forState: UIControlState.Normal)
        deleteButton.titleLabel?.font = UIFont(name: "Avenir Next", size: 10)
        deleteButton.addTarget(self, action: Selector("deleteRecButtonTapped:"),
            forControlEvents: UIControlEvents.TouchUpInside)
        deleteButton.frame = CGRectMake(80, 10, 80, 30)
        deleteButton.setTitleColor(UIColor.orangeColor(),
            forState: UIControlState.Normal)
        cell.contentView.addSubview(deleteButton)
        
        if let fn = fileName {
            deleteButton.tag = fn.toInt()!
        }
        
        return cell
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        sound.addRecordingWithFileName(fileName)
        sound.save()
        recordingsTableView.reloadData()
        recordButton.setTitle("Record an instance of this sound",
            forState: UIControlState.Normal)
        titleTextField.enabled = true
        backButton.enabled = true
    }
    
    @IBAction func onRecordButtonTapped(sender: AnyObject) {
        if sound.name == "" {
            println("todo: UI alert: sound name required")
            return
        }
        if recording() {
            stopRecordingAudio()
        } else {
            titleTextField.enabled = false
            backButton.enabled = false
            fileName = String(now())
            startRecordingAudio(toPath: DOCUMENT_DIR + "\(fileName).wav", delegate: self)
            recordButton.setTitle("Stop recording", forState: UIControlState.Normal)
        }
    }
    
    @IBAction func doneEditing(sender: AnyObject) {
        let newSoundName = titleTextField.text
        titleTextField.resignFirstResponder()
        if newSoundName == "" {
            titleTextField.text = sound.name
        } else {
            sound.name = newSoundName
            // Reload in case sounds were merged
            sound = Sound(name: sound.name)
            recordingsTableView.reloadData()
        }
    }
    
}