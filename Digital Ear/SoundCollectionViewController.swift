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

    fileprivate var soundNames: [String] = []
    
    @IBOutlet weak var soundTableView: UITableView!
    
    override func viewDidLoad() {
        soundTableView.dataSource = self
        soundTableView.delegate = self
        soundTableView.autoresizesSubviews = true
        soundNames = getSoundNames()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return soundNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.value2, reuseIdentifier: nil)
        cell.detailTextLabel?.text = soundNames[indexPath.row]
        
        let deleteButton = UIButton()
        deleteButton.setTitle("delete", for: UIControlState())
        deleteButton.titleLabel?.font = UIFont(name: "Avenir Next", size: 10)
        deleteButton.addTarget(self, action: #selector(SoundCollectionViewController.deleteSoundButtonTapped(_:)),
            for: UIControlEvents.touchUpInside)
        deleteButton.frame = CGRect(x: soundTableView.frame.width - 60, y: 10, width: 80, height: 30)
        deleteButton.setTitleColor(UIColor.orange,
            for: UIControlState())
        cell.contentView.addSubview(deleteButton)
        
        deleteButton.tag = indexPath.row
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        sound = Sound(name: soundNames[indexPath.row])
        performSegue(withIdentifier: "toSoundViewController", sender: sound.name)
    }
    
    var row = 0
    func deleteSound(_ action: UIAlertAction!) -> Void {
        Sound(name: soundNames[row]).delete()
        soundNames.remove(at: row)
        soundTableView.reloadData()
        UserDefaults()
    }
    
    func deleteSoundButtonTapped(_ sender: AnyObject) {
        row = sender.tag
        let alert = UIAlertController(title: nil,
            message: "Are you sure you want to delete this sound?",
            preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Yes, delete", style: UIAlertActionStyle.default,
            handler: deleteSound)
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        present(alert, animated: true, completion: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with
        coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        soundTableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let s: AnyObject = sender as AnyObject? {
            if s is UIButton { // if "Add new" button pressed
                sound = Sound(name: "")
            }
        }
    }
    
    @IBAction func unwindToSoundCollectionViewController(_ segue: UIStoryboardSegue) {
        soundNames = getSoundNames()
        soundTableView.reloadData()
    }
    
}
