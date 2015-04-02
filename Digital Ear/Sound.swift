//
//  Sounds.swift
//  Digital Ear
//
//  Created by Alex Reidy on 3/26/15.
//  Copyright (c) 2015 Alex Reidy. All rights reserved.
//

import Foundation
import CoreData

var managedContext: NSManagedObjectContext? // to be initialized in AppDelegate

func loadRecordingObjects(soundName: String?) -> [NSManagedObject] {
    // If soundName is nil, ALL recording objects are returned
    var recordings: [NSManagedObject] = []
    let fetchRequest = NSFetchRequest(entityName: "Recording")
    if let context = managedContext {
        let allRecs = context.executeFetchRequest(fetchRequest, error: nil) as [NSManagedObject]
        if let sn = soundName {
            for rec in allRecs {
                if rec.valueForKey("soundName") as String == sn {
                    recordings.append(rec)
                }
            }
            return recordings
        } else {
            return allRecs
        }
    }
    return []
}

func getSoundNames() -> [String] {
    let names = NSMutableSet()
    let recordings = loadRecordingObjects(nil)
    for rec in recordings {
        names.addObject(rec.valueForKey("soundName") as String)
    }
    return names.allObjects as [String]
}

func makeRecordingObjectWith(#fileName: String, #soundName: String) -> NSManagedObject? {
    if let context = managedContext {
        let entity = NSEntityDescription.entityForName("Recording", inManagedObjectContext: context)
        let recording = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: context)
        recording.setValue(fileName, forKey: "fileName")
        recording.setValue(soundName, forKey: "soundName")
        return recording
    }
    return nil
}

func deleteRecording(recording: NSManagedObject, save: Bool = true) {
    if let context = managedContext {
        context.deleteObject(recording)
        if save {
            saveRecordingContext()
        }
    }
}

func saveRecordingContext() {
    if let context = managedContext {
        if !context.save(nil) {
            println("ERROR SAVING")
        }
    }
}

func getSounds() -> [Sound] {
    var sounds: [Sound] = []
    for name in getSoundNames() {
        sounds.append(Sound(name: name))
    }
    return sounds
}

class Sound {
    
    private var _name: String
    
    // A set would probably be better for performance
    private(set) var recordings: [NSManagedObject] = []
    
    var name: String {
        get {
            return _name
        }
        set(newName) {
            if _name == newName { return }
            _name = newName
            for rec in recordings {
                rec.setValue(newName, forKey: "soundName")
            }
            save()
        }
    }

    init(name: String) {
        _name = name
        if name == "" {
            return
        }
        recordings = loadRecordingObjects(name)
    }
    
    func addRecordingWithFileName(fileName: String) {
        if let rec = makeRecordingObjectWith(fileName: fileName, soundName: name) {
            recordings.append(rec)
            save()
        }
    }
    
    func deleteRecordingWithFileName(fileName: String) {
        var i = 0
        for ; i < recordings.count; i++ {
            let rec = recordings[i]
            if rec.valueForKey("fileName") as String == fileName {
                deleteRecording(rec, save: true)
                break
            }
        }
        recordings.removeAtIndex(i)
    }
    
    func delete() {
        for rec in recordings {
            deleteRecording(rec, save: false)
        }
        recordings = []
        save()
    }
    
    func save() {
        saveRecordingContext()
    }
    
}