//
//  PlayWorkoutPlayList.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/23/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MediaPlayer

// Class linked with the Core Data object WorkoutPlayListData
class StoredWorkoutMusicPlayList {
    var name : String
    var tracks = [StoredWorkoutPlayListSong]()
    
    init(data: WorkoutPlayListData) {
        self.name = data.name!
        for elt in data.elements!.array {
            let wsongData = elt as? WorkoutSongData
            tracks.append(StoredWorkoutPlayListSong(data: wsongData!))
        }
    }
    
    func detailText() -> String {
        var totalDuration : Double = 0
        for track in tracks {
            totalDuration += Double(track.durationTime)
        }
        
        let fmt = DateComponentsFormatter()
        fmt.zeroFormattingBehavior = .pad
        fmt.allowedUnits = [.minute, .second]
        let timestring = fmt.string(from: totalDuration)
        
        let bpms = tracks.map { (track) -> Int in
            return track.bpm
        }
        let bpm_min = bpms.min()!
        let bpm_max = bpms.max()!
        
        return timestring! + " @ \(bpm_min)-\(bpm_max)"
    }
    
    var totalDuration : Double {
        get {
            var totalDuration : Double = 0
            for track in tracks {
                totalDuration += Double(track.durationTime)
            }
            return totalDuration
        }
    }
    
    func startTime(songIndex: Int) -> Double {
        if( songIndex < 0 ) {
            return 0
        }
        if( songIndex >= tracks.count ) {
            return totalDuration
        }
        
        var totalDuration : Double = 0
        for i in 0 ..< songIndex {
            totalDuration += Double(tracks[i].durationTime)
        }
        return totalDuration
    }
}

// Class linked with the Core Data object WorkoutSongData
class StoredWorkoutPlayListSong {
    var songName: String
    var songId : String
    var startTime : Double = 0  // In seconds
    var endTime : Double  = 0 // In seconds
    var bpm : Int = 0
    
    init(data: WorkoutSongData) {
        songName = data.songName!
        songId = data.storedId!
        startTime = data.startTime
        endTime = data.endTime
        bpm = Int(data.tempo)
    }
    
    var durationTime : Double {
        get {
            return endTime - startTime
        }
    }
}

// Cell to display the play list name, duration and intensityView.
class PlayWorkoutPlayListTableCell : UITableViewCell {
    var playList : StoredWorkoutMusicPlayList?
    @IBOutlet weak var playListName: UILabel!
    @IBOutlet weak var playListDuration: UILabel!
    @IBOutlet weak var playListIntensityView: WorkoutIntensityView!
}

// UITableViewController synchronized via CoreData on the WorkoutPlayListData table content
class PlayWorkoutPlayListController : UITableViewController , NSFetchedResultsControllerDelegate {
    weak var mainController: PlayWorkoutPlayController?
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        let sections = fetchedResultsController.sections
        let youHaveData = sections != nil && sections![0].numberOfObjects != 0
        if youHaveData {
            tableView.separatorStyle = .singleLine
            tableView.backgroundView = nil
            return fetchedResultsController.sections?.count ?? 0
        } else {
            let noDataLabel: UILabel  = UILabel(frame: CGRect(x: 20, y: 0, width: tableView.bounds.size.width - 20, height: tableView.bounds.size.height))
            noDataLabel.text          = "No workout playlist available.\n Use Build tab to construct a workout playlist from your own Music playlist"
            noDataLabel.textColor     = UIColor.black
            noDataLabel.textAlignment = .center
            noDataLabel.numberOfLines = 0
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if( fetchedResultsController.sections == nil ) {
            return 0
        }
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutPlayListTableCell", for: indexPath)
        let list = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withPlayList: list)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let list = fetchedResultsController.object(at: indexPath)
        let workout = StoredWorkoutMusicPlayList(data: list)
        mainController?.selectedWorkout = workout
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = fetchedResultsController.managedObjectContext
            context.delete(fetchedResultsController.object(at: indexPath))
                
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func configureCell(_ cell: UITableViewCell, withPlayList playList: WorkoutPlayListData) {
        guard let ecell = cell as? PlayWorkoutPlayListTableCell else {
            return
        }
        ecell.playList = StoredWorkoutMusicPlayList(data: playList)
        ecell.playListName.text = playList.name!
        ecell.playListDuration.text = ecell.playList!.detailText()
        ecell.playListIntensityView.workoutPlayList = ecell.playList
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<WorkoutPlayListData> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<WorkoutPlayListData> = WorkoutPlayListData.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: "WorkoutPlayLists"
        )
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             let nserror = error as NSError
             fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<WorkoutPlayListData>? = nil

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                configureCell(tableView.cellForRow(at: indexPath!)!, withPlayList: anObject as! WorkoutPlayListData)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!)!, withPlayList: anObject as! WorkoutPlayListData)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
            default:
                return
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}

// UIViewController related to the execution of a WorkoutPlayList
class PlayWorkoutPlayController : UIViewController {
    
    @IBOutlet weak var workoutPlayButton: UIButton!
    @IBOutlet weak var workoutsTableView: UITableView!
    var workoutTableController = PlayWorkoutPlayListController()
    var selectedWorkout : StoredWorkoutMusicPlayList? {
        didSet {
            workoutIntensityView.workoutPlayList = selectedWorkout
            workoutIntensityView.setupTimeAxisLabels()
            workoutIntensityView.setNeedsDisplay()
            workoutPlayButton.isEnabled = true
        }
    }
    var editingTable = false
    var playing = false
    var timer : Timer?
    
    @IBOutlet weak var nowPlayingLabel: UILabel!
    @IBOutlet weak var workoutIntensityView: WorkoutIntensityView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        workoutTableController.tableView = workoutsTableView
        workoutsTableView.dataSource = workoutTableController
        workoutsTableView.delegate = workoutTableController
        workoutTableController.mainController = self
        workoutPlayButton.isEnabled = false
        
        MPMusicPlayerController.applicationMusicPlayer.beginGeneratingPlaybackNotifications()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playbackStateChanged),
                                               name: .MPMusicPlayerControllerPlaybackStateDidChange,
                                               object: MPMusicPlayerController.applicationMusicPlayer)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshView),
                                               name: .MPMusicPlayerControllerNowPlayingItemDidChange,
                                               object: MPMusicPlayerController.applicationMusicPlayer)
    }
    
    deinit {
        MPMusicPlayerController.applicationMusicPlayer.endGeneratingPlaybackNotifications()
        
        NotificationCenter.default.removeObserver(self, name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: MPMusicPlayerController.applicationMusicPlayer)
        NotificationCenter.default.removeObserver(self, name: .MPMusicPlayerControllerPlaybackStateDidChange, object: MPMusicPlayerController.applicationMusicPlayer)
        timer = nil
    }
    
    // Execute the playlist linked to the workout
    @IBAction func executeWorkout(_ sender: Any) {
        if( playing == false ) {
            if( selectedWorkout != nil ) {
                globalAppleMusic.playSongs(workoutMusic: selectedWorkout!.tracks)
                playing = true
                workoutPlayButton.setTitle("Pause", for: .normal)
            }
        } else {
            workoutPlayButton.setTitle("Start", for: .normal)
            globalAppleMusic.pausePlaying()
            playing = false
        }
    }
    
    // Put the workout table list view in edit mode so that we can remove some workouts.
    @IBAction func editTable(_ sender: Any) {
        editingTable = !editingTable
        let button = sender as! UIButton
        workoutsTableView.setEditing(editingTable, animated:  true)
        if( editingTable ) {
            button.setTitle("Done", for: .normal)
        } else {
            button.setTitle("Edit", for: .normal)
        }
    }
    
    // Monitor the MusicPlayer current playing item. Check that the player is playing one
    // item of the workout playlist. If it is, change the Now playing label,
    // and set the cursor location in the workoutIntensityView
    @objc
    func refreshView() {
        if( selectedWorkout == nil ) {
            return
        }
        let index  = MPMusicPlayerController.applicationMusicPlayer.indexOfNowPlayingItem
        let item = MPMusicPlayerController.applicationMusicPlayer.nowPlayingItem
        if( index >= 0 && index < selectedWorkout!.tracks.count && item != nil ) {
            let firstIndex = selectedWorkout!.tracks.firstIndex(where: { (wsong) -> Bool in
                wsong.songId == item!.playbackStoreID
            })
            if( firstIndex != nil && firstIndex! == index ) {
                DispatchQueue.main.async {
                    self.nowPlayingLabel.text = "Now playing: \(self.selectedWorkout!.tracks[index].songName)"
                    
                    if( index == 0 ) {
                        if( self.timer == nil ) {
                           self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
                        }
                    } else {
                        // Make sure to set at the right time (when we pause/skip)
                        self.workoutIntensityView.cursorLocationInS =
                            self.selectedWorkout!.startTime(songIndex: index)
                    }
                }
            }
        }
    }
    
    // Monitor the playback status to know when to stop the timer.
    @objc
    func playbackStateChanged() {
        if( selectedWorkout == nil ) {
            return
        }
        
        let state = MPMusicPlayerController.applicationMusicPlayer.playbackState
        if( state == .stopped ) {
            DispatchQueue.main.async {
                self.nowPlayingLabel.text = "Stopped playing"
                self.timer = nil
            }
        } else if( state == .paused ) {
            self.timer = nil
            
        } else if( state == .playing ) {
            if( timer == nil ) {
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
            }
        }
    }
    
    // Update the timer cursor in the workoutIntensityView
    @objc
    func updateTime() {
        DispatchQueue.main.async {
            if( self.workoutIntensityView.cursorLocationInS == nil ) {
               self.workoutIntensityView.cursorLocationInS = self.timer!.timeInterval
            } else if( self.timer != nil ) {
                self.workoutIntensityView.cursorLocationInS = self.workoutIntensityView.cursorLocationInS! + self.timer!.timeInterval
            }
        }
    }
}
