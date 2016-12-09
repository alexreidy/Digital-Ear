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

func loadRecordingObjects(_ soundName: String?) -> [NSManagedObject] {
    // If soundName is nil, ALL recording objects are returned
    var recordings: [NSManagedObject] = []
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Recording")
    if let context = managedContext {
        guard let allRecs: [NSManagedObject] = try? context.fetch(fetchRequest) as! [NSManagedObject] else { return [NSManagedObject]() }
        if let sn = soundName {
            for rec in allRecs {
                if rec.value(forKey: "soundName") as! String == sn {
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
        names.add(rec.value(forKey: "soundName") as! String)
    }
    return names.allObjects as! [String]
}

func makeRecordingObjectWith(fileName: String, soundName: String) -> NSManagedObject? {
    if let context = managedContext {
        let entity = NSEntityDescription.entity(forEntityName: "Recording", in: context)
        let recording = NSManagedObject(entity: entity!, insertInto: context)
        recording.setValue(fileName, forKey: "fileName")
        recording.setValue(soundName, forKey: "soundName")
        return recording
    }
    return nil
}

func deleteRecording(_ recording: NSManagedObject, save: Bool = true) {
    if let context = managedContext {
        context.delete(recording)
        if save {
            saveRecordingContext()
        }
    }
}

func saveRecordingContext() {
    if let context = managedContext {
        do {
            try context.save()
        } catch {
            print("ERROR SAVING")
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
    
    fileprivate var _name: String
    
    // A set would probably be better for performance
    fileprivate(set) var recordings: [NSManagedObject] = []
    
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
        if name == "" { return }
        recordings = loadRecordingObjects(name)
    }
    
    var flashWhenRecognized: Bool {
        get {
            return UserDefaults().bool(forKey: name + "_SHOULD_FLASH")
        }
        set(should) {
            UserDefaults().set(should, forKey:
                name + "_SHOULD_FLASH")
        }
    }
    
    var vibrateWhenRecognized: Bool {
        get {
            return UserDefaults().bool(forKey: name + "_SHOULD_VIBRATE")
        }
        set(should) {
            UserDefaults().set(should, forKey:
                name + "_SHOULD_VIBRATE")
        }
    }
    
    func addRecordingWithFileName(_ fileName: String) {
        if let rec = makeRecordingObjectWith(fileName: fileName, soundName: name) {
            recordings.append(rec)
            save()
        }
    }
    
    func deleteRecordingWithFileName(_ fileName: String) {
        for i in 0 ..< recordings.count {
            let rec = recordings[i]
            if rec.value(forKey: "fileName") as! String == fileName {
                deleteRecording(rec, save: true)
                recordings.remove(at: i)
                return
            }
        }
        
    }
    
    func delete() {
        for rec in recordings {
            deleteRecording(rec, save: false)
        }
        recordings = []
        save()
        UserDefaults().removeObject(forKey: name + "_SHOULD_VIBRATE")
        UserDefaults().removeObject(forKey: name + "_SHOULD_FLASH")
    }
    
    func save() {
        saveRecordingContext()
    }
    
}
