//
//  DetailViewController.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/18/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import UIKit
import MediaPlayer
import CoreData

/// Class that contains the list of WorkoutMusicPlayListTrack
/// Its main role is to compute the total duration.
class WorkoutMusicPlayList {
    var tracks = [WorkoutMusicPlayListTrack]()
    
    init() {
    }
    
    init(songs: [FetchAppleMusic.MusicTrackInfo]) {
        for song in songs {
            tracks.append(WorkoutMusicPlayListTrack(song: song))
        }
    }
    
    /// Return "33:00 Workout" for example if the total duration is 33 minutes.
    func detailText() -> String {
        let fmt = DateComponentsFormatter()
        fmt.zeroFormattingBehavior = .pad
        fmt.allowedUnits = [.minute, .second]
        let timestring = fmt.string(from: totalDuration)
        return timestring! + " Workout"
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
    
    func indexOf(track: WorkoutMusicPlayListTrack) -> Int? {
        return tracks.firstIndex(where: { (iwt) -> Bool in
            iwt === track
        })
    }
}

/// Contains the track of Music to play and its interval (start time and end time).
class WorkoutMusicPlayListTrack {
    var song : FetchAppleMusic.MusicTrackInfo
    var startTime = 0  // In seconds
    var durationTime = 0 // In seconds
    init(song: FetchAppleMusic.MusicTrackInfo) {
        self.song = song
        durationTime = song.durationInMs/1000
    }
    
    var endTime : Int {
        get {
            return startTime + durationTime
        }
        set {
            durationTime = newValue - startTime
        }
    }
}

/// UITableViewCell for a WorkoutPlayListMusicTrack
class DetailViewTrackListCell : UITableViewCell {
    var wtrack : WorkoutMusicPlayListTrack?
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var songAuthor: UILabel!
    @IBOutlet weak var songBPMLabel: UILabel!
    @IBOutlet weak var timeInterval: TimeIntervalUIView!
    @IBOutlet weak var playedIntervalLabel: UILabel!
}

/// Encapsulate the multi-threading management of the full track list creation.
class TracksDownloadManager {
    private var unsafeTracks = [FetchAppleMusic.MusicTrackInfo]()
    
    private let concurrentTracksQueue = DispatchQueue(
      label: "com.www.next-shot-inc.WorkoutMusic.tracksQueue",
      attributes: .concurrent
    )
    
    func add(tracks: [FetchAppleMusic.MusicTrackInfo]) {
        concurrentTracksQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }
            self.unsafeTracks.append(contentsOf: tracks)
        }
    }
    
    var tracks: [FetchAppleMusic.MusicTrackInfo] {
      var tracksCopy: [FetchAppleMusic.MusicTrackInfo]!
      concurrentTracksQueue.sync {
        tracksCopy = self.unsafeTracks
      }
      return tracksCopy
    }
}

/// Show for each music track, the time interval selected to play
/// This controller can be called from two places: either from an existing WorkoutPlayList
/// or from a collection of playlists to pick songs from.
class DetailViewTableViewControler : UITableViewController {
    weak var appleMusic : FetchAppleMusic?
    var wplaylist = WorkoutMusicPlayList()
    var tracksDownloadManager = TracksDownloadManager()

    var detailItem: [FetchAppleMusic.PlayListInfo]?
    var object: WorkoutPlayListData?
    var hasChanges = false
    
    /// Configure the table when coming from a list of playlists to build a new workout playlist
    func configureViewFromPlayLists() {
        if( detailItem == nil ) {
            return
        }
        
        // First collect all the tracks from the different playlists.
        let downloadGroup = DispatchGroup()
        for detail in detailItem! {
            let playList = FetchAppleMusic.PlayListInfo(name: detail.name, description: detail.description, url: detail.url)
            downloadGroup.enter()
            appleMusic?.getTracksForPlaylist(playList:  playList, completion: { (tracks, offset) in
                self.tracksDownloadManager.add(tracks: tracks)
                downloadGroup.leave()
            })
        }
        
        // At the end of the download group - Do the other tasks.
        downloadGroup.notify(queue: DispatchQueue.main) {
            self.wplaylist = WorkoutMusicPlayList(songs: self.tracksDownloadManager.tracks)
            self.configureView()
        }
    }
    
    /// Configure the table when coming from an existing workout playlist
    func configureViewFromPlayListData() {
        guard let playListData = object else {
            return
        }
        // First collect all the tracks from the WorkoutPLayList storeIds.
        let downloadGroup = DispatchGroup()
        for elt in playListData.elements!.array {
            if let wsongData = elt as? WorkoutSongData {
                downloadGroup.enter()
                appleMusic?.seachSongInStore(storeId: wsongData.storedId!, completion: { (track) in
                    if( track != nil ) {
                        self.tracksDownloadManager.add(tracks: [track!])
                    }
                    downloadGroup.leave()
                })
            }
        }
        
        // At the end of the download group - Do the other tasks.
        downloadGroup.notify(queue: DispatchQueue.main) {
            self.wplaylist = WorkoutMusicPlayList(songs: self.tracksDownloadManager.tracks)
            self.configureView()
        }
    }
    
    /// Finalize the configration of the view shared between the two entry paths
    func configureView() {
        DispatchQueue.main.async {
            // Your UI Updation here
            self.title = self.wplaylist.detailText()
            self.tableView.reloadData()
            
            let songBPStorage = SongBPMStore()
            
            // Proceed carefully as the task completion may return while rows have already been deleted
            let tracks = self.wplaylist.tracks // Copy
            for track in tracks {
                if let songBPM = songBPStorage.retrieve(song: track.song) {
                    track.song.bpm = songBPM
                } else {
                    let songBpm = FetchSongBPM()
                    songBpm.getSongPBM(song: track.song, completion: { (bpm) in
                        if let offset = self.wplaylist.indexOf(track: track) {
                            self.wplaylist.tracks[offset].song.bpm = bpm
                            DispatchQueue.main.async {
                                songBPStorage.save(song: track.song)
                            }
                        }
                    })
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // On the navigation bar: we have on the right, the back button and on the left, the edit and save button
       // navigationItem.rightBarButtonItem = self.editButtonItem
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveWPlayList(_:)))
        navigationItem.rightBarButtonItems = [self.editButtonItem, saveButton]
        //navigationItem.leftItemsSupplementBackButton = true
        
        // Do any additional setup after loading the view.
        if( detailItem != nil ) {
            configureViewFromPlayLists()
        } else if( object != nil ) {
            configureViewFromPlayListData()
        }
    }

    // MARK: UITableViewController stubs
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wplaylist.tracks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailViewTrackListCell", for: indexPath) as! DetailViewTrackListCell
        
        configureCell(cell, with: wplaylist.tracks[indexPath.row], row : indexPath.row)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Delete rows enabled
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        wplaylist.tracks.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        hasChanges = true
        updateTitle()
    }
    
    // Enable movement up/down of the songs.
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = self.wplaylist.tracks[sourceIndexPath.row]
        wplaylist.tracks.remove(at: sourceIndexPath.row)
        wplaylist.tracks.insert(movedObject, at: destinationIndexPath.row)
        hasChanges = true
        updateTitle()
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func configureCell(_ cell: DetailViewTrackListCell, with: WorkoutMusicPlayListTrack, row: Int) {
        cell.songName.text = with.song.name
        cell.songAuthor.text = with.song.artistName
        cell.wtrack = with
        
        if( with.song.bpm != 0 ) {
            cell.songBPMLabel.text = "BPM: \(with.song.bpm)"
        }
        
        cell.timeInterval.minimumValue = 0
        cell.timeInterval.maximumValue = Double(with.song.durationInMs/1000)
        cell.timeInterval.lowerValue = Double(with.startTime)
        cell.timeInterval.upperValue = Double(with.endTime)
        
        let fmt = DateComponentsFormatter()
        fmt.allowedUnits = [.minute, .second]
        let uppertimestring = fmt.string(from: cell.timeInterval.upperValue)
        cell.timeInterval.upperTextValue = uppertimestring
    
        let lowertimestring = fmt.string(from: cell.timeInterval.lowerValue)
        cell.timeInterval.lowerTextValue = lowertimestring
        
        fmt.zeroFormattingBehavior = .pad
        let duration = fmt.string(from: Double(with.durationTime))
        cell.playedIntervalLabel.text = duration!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editSongPlayedInterval" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = wplaylist.tracks[indexPath.row]
                let controller = segue.destination as! EditSongPlayedIntervalController
                controller.appleMusic = appleMusic
                controller.wtrack = object
            }
        }
    }
    
    @IBAction func unwindToViewControllerFromEditInterval(segue: UIStoryboardSegue) {
        if segue.identifier == "unwindFromEditSongPlayedInterval" {
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }

    
    // MARK - Actions
    
    func updateTitle() {
        let stared = hasChanges ? "* " : ""
        title = stared + wplaylist.detailText()
    }
    
    func play( wtracks: [WorkoutMusicPlayListTrack], complete: Bool = false) {
        appleMusic?.playSongs(wtracks: wtracks, complete: complete)
    }
    
    func hitPlayForEdit(row: Int) {
        var wtracks = [WorkoutMusicPlayListTrack]()
        wtracks.append(wplaylist.tracks[row])
        play(wtracks: wtracks, complete: true)
    }
    
    @objc
    func saveWPlayList(_ sender : Any) {
        
        if( object != nil ) {
            saveWPlayList(playlistData: object!)
            
        } else {
            let ac = UIAlertController(title: "Enter workout name", message: nil, preferredStyle: .alert)
            ac.addTextField()
            
            let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned ac] _ in
                let answer = ac.textFields![0]
                self.saveWPlayList(name: answer.text!)
            }
            
            ac.addAction(submitAction)
            
            present(ac, animated: true)
        }
    }
    
    func saveWPlayList(name: String) {
        guard let managedContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            return
        }
        
        // Verify if a playlist of that name does not already exist
        func getPlayListData() -> WorkoutPlayListData? {
            let fetchRequest: NSFetchRequest<WorkoutPlayListData> = WorkoutPlayListData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name == %@", name as CVarArg)
            do {
                let objects = try managedContext.fetch(fetchRequest)
                if( objects.count >= 1 ) {
                    return objects[0]
                } else {
                    return nil
                }
            } catch {
                return nil
            }
        }
        var playlistData = getPlayListData()
        if( playlistData == nil ) {
            playlistData = WorkoutPlayListData(context: managedContext)
            playlistData!.name = name
        }
        
        saveWPlayList(playlistData: playlistData!)
    }
    
    func saveWPlayList(playlistData: WorkoutPlayListData) {
        guard let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            return
        }
        var array = [WorkoutSongData]()
        let wtracks = wplaylist.tracks
         for wtrack in wtracks {
            let storeId: String?
            switch wtrack.song.playId {
            case let .catalog(id):
                storeId = id
            case let.purchased(id):
                storeId = id
            default:
                storeId = nil
            }
            
            if( storeId != nil ) {
                let wsongData = WorkoutSongData(context: managedObjectContext)
                wsongData.songName = wtrack.song.name
                wsongData.storedId = storeId!
                wsongData.startTime = Double(wtrack.startTime)
                wsongData.endTime = Double(wtrack.endTime)
                wsongData.tempo = Int32(wtrack.song.bpm)
                array.append(wsongData)
            }
         }
         playlistData.elements = NSOrderedSet(array: array)
        
        // Save the context.
        do {
            try managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        hasChanges = false
        updateTitle()
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindFromEditWorkout", sender: self)
    }
}

