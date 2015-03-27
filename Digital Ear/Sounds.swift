//
//  Sounds.swift
//  Digital Ear
//
//  Created by Alex Reidy on 3/26/15.
//  Copyright (c) 2015 Alex Reidy. All rights reserved.
//

import Foundation
import CoreData

var managedContext: NSManagedObjectContext?
var recordings: [NSManagedObject] = []
var soundName = ""

func loadRecordingObjects(withSpecificName: Bool = false) {
    let fetchRequest = NSFetchRequest(entityName: "Recording")
    if let context = managedContext {
        recordings = []
        var allRecs = context.executeFetchRequest(fetchRequest, error: nil) as [NSManagedObject]
        if withSpecificName {
            for rec in allRecs {
                if rec.valueForKey("soundName") as String == soundName {
                    recordings.append(rec)
                }
            }
        } else {
            recordings = allRecs
        }
    }
}

func addRecordingObjectWithFileName(fileName: String) {
    if let context = managedContext {
        let entity = NSEntityDescription.entityForName("Recording", inManagedObjectContext: context)
        let recording = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: context)
        recording.setValue(fileName, forKey: "fileName")
        recording.setValue(soundName, forKey: "soundName")
        recordings.append(recording)
    }
}

func deleteRecordingWithFilename(fname: String) {
    if let context = managedContext {
        for rec in recordings {
            if rec.valueForKey("fileName") as String == fname {
                context.deleteObject(rec)
            }
        }
    }
    saveRecordingObjects()
    loadRecordingObjects(withSpecificName: true)
}

func saveRecordingObjects() {
    if let context = managedContext {
        if !context.save(nil) {
            println("ERROR SAVING")
        }
    }
}