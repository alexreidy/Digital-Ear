//
//  SoundCollectionViewController.swift
//  Digital Ear
//
//  Created by Alex Reidy on 3/21/15.
//  Copyright (c) 2015 Alex Reidy. All rights reserved.
//

import Foundation
import UIKit

var sound = Sound(name: "")

class SoundCollectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var soundNames: [String] = []
    
    @IBOutlet weak var soundTableView: UITableView!
    
    override func viewDidLoad() {
        soundTableView.dataSource = self
        soundTableView.delegate = self
        soundNames = getSoundNames()
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
        sound = Sound(name: soundNames[indexPath.row])
        performSegueWithIdentifier("toSoundViewController", sender: sound.name)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let s: AnyObject = sender {
            if s is UIButton {
                sound.name = ""
            }
        }
    }
    
    @IBAction func unwindToSoundCollectionViewController(segue: UIStoryboardSegue) {
        soundNames = getSoundNames()
        soundTableView.reloadData()
    }
    
}