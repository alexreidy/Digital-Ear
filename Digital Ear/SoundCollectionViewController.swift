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
        deleteButton.addTarget(self, action: Selector("deleteRecButtonTapped:"),
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
    
    func deleteRecButtonTapped(sender: AnyObject) {
        let i = sender.tag
        println("deleting\(i)")
        Sound(name: soundNames[i]).delete()
        soundNames.removeAtIndex(i)
        soundTableView.reloadData()
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