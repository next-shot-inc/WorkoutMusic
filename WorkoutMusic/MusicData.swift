//
//  MusicData.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/18/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit
import CoreData

/// Class to store on the side, the BPM per song
/// instead of always going to getSongBPM

class SongBPMStore {
    func retrieve(song: FetchAppleMusic.MusicTrackInfo) -> Int? {
        guard let managedContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            return nil
        }
        let fetchRequest: NSFetchRequest<SongBPMData> = SongBPMData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "storeId == %@", song.storeId! as CVarArg)
        do {
            let objects = try managedContext.fetch(fetchRequest)
            if( objects.count >= 1 ) {
                return Int(objects[0].bpm)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    func save(song: FetchAppleMusic.MusicTrackInfo) {
        guard let managedContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            return
        }
        let songBPMData = SongBPMData(context: managedContext)
        songBPMData.bpm = Int32(song.bpm)
        songBPMData.storeId = song.storeId!
        
        do {
            try managedContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}
