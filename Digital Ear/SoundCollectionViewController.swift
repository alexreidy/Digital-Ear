//
//  SoundCollectionViewController.swift
//  Digital Ear
//
//  Created by Alex Reidy on 3/21/15.
//  Copyright (c) 2015 Alex Reidy. All rights reserved.
//

import Foundation
import UIKit

class SoundCollectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var soundNames: [String] = []
    
    @IBOutlet weak var soundTableView: UITableView!
    
    override func viewDidLoad() {
        soundTableView.dataSource = self
        soundTableView.delegate = self
        soundNames = getSoundNames()
    }
    
    private func getSoundNames() -> [String] {
        let names = NSMutableSet()
        loadRecordingObjects()
        for rec in recordings {
            names.addObject(rec.valueForKey("soundName") as String)
        }
        return names.allObjects as [String]
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return soundNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Value2, reuseIdentifier: nil)
        cell.detailTextLabel?.text = soundNames[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        soundName = soundNames[indexPath.row]
        performSegueWithIdentifier("toSoundViewController", sender: soundName)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let s = sender {
            if s is UIButton {
                soundName = ""
            }
        }
    }
    
    @IBAction func unwindToSoundCollectionViewController(segue: UIStoryboardSegue) {
        soundNames = getSoundNames()
        soundTableView.reloadData()
    }
    
}