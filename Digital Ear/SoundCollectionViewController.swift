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
        soundTableView.autoresizesSubviews = true
        soundNames = getSoundNames()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return soundNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Value2, reuseIdentifier: nil)
        cell.detailTextLabel?.text = soundNames[indexPath.row]
        
        let deleteButton = UIButton()
        deleteButton.setTitle("delete", forState: UIControlState.Normal)
        deleteButton.titleLabel?.font = UIFont(name: "Avenir Next", size: 10)
        deleteButton.addTarget(self, action: Selector("deleteSoundButtonTapped:"),
            forControlEvents: UIControlEvents.TouchUpInside)
        deleteButton.frame = CGRectMake(soundTableView.frame.width - 60, 10, 80, 30)
        deleteButton.setTitleColor(UIColor.orangeColor(),
            forState: UIControlState.Normal)
        cell.contentView.addSubview(deleteButton)
        
        deleteButton.tag = indexPath.row
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        sound = Sound(name: soundNames[indexPath.row])
        performSegueWithIdentifier("toSoundViewController", sender: sound.name)
    }
    
    var row = 0
    func deleteSound(action: UIAlertAction!) -> Void {
        Sound(name: soundNames[row]).delete()
        soundNames.removeAtIndex(row)
        soundTableView.reloadData()
        NSUserDefaults()
    }
    
    func deleteSoundButtonTapped(sender: AnyObject) {
        row = sender.tag
        let alert = UIAlertController(title: nil,
            message: "Are you sure you want to delete this sound?",
            preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Yes, delete", style: UIAlertActionStyle.Default,
            handler: deleteSound)
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator
        coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        soundTableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let s: AnyObject = sender {
            if s is UIButton { // if "Add new" button pressed
                sound = Sound(name: "")
            }
        }
    }
    
    @IBAction func unwindToSoundCollectionViewController(segue: UIStoryboardSegue) {
        soundNames = getSoundNames()
        soundTableView.reloadData()
    }
    
}