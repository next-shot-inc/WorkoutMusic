//
//  DetailViewController.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/18/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import UIKit
import MediaPlayer

class WorkoutMusicPlayList {
    var tracks = [WorkoutMusicPlayListTrack]()
    
    init() {
    }
    
    init(songs: [FetchAppleMusic.MusicTrackInfo]) {
        for song in songs {
            tracks.append(WorkoutMusicPlayListTrack(song: song))
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
        return timestring! + " Workout"
    }
}

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

class DetailViewTrackListCell : UITableViewCell {
    weak var detailViewTableViewControler : DetailViewTableViewControler?
    weak var wtrack: WorkoutMusicPlayListTrack?
    var row = 0
    var timer: Timer?
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var songAuthor: UILabel!
    @IBOutlet weak var songBPMLabel: UILabel!
    @IBOutlet weak var timeInterval: TimeIntervalUIView!
    @IBOutlet weak var playedIntervalLabel: UILabel!
    
    @IBAction func startPlayToEditStartAndEnd(_ sender: Any) {
        let editor = detailViewTableViewControler!.playSongIntervalEditor
        editor.row = row
        
        switch editor.defineBoundState {
        case .none:
            detailViewTableViewControler?.hitPlayForEdit(row: editor.row)
            editor.defineBoundState = .start
            editButton.setTitle( "Set start time", for: .normal)
            editor.startDate = Date()
            
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
            
        case .start:
            editor.defineBoundState = .end
            editButton.setTitle( "Set end time", for : .normal)
            let timeOfStart = -editor.startDate.timeIntervalSince(Date())
            timeInterval.lowerValue = timeOfStart
            wtrack?.startTime = Int(timeOfStart)
            
            let fmt = DateComponentsFormatter()
            fmt.allowedUnits = [.minute, .second]
            let timestring = fmt.string(from: timeInterval.lowerValue)
            timeInterval.lowerTextValue = timestring
            
        case .end:
            editor.defineBoundState = .none
            editor.row = -1
            editButton.setTitle( "Edit Interval", for: .normal)
            
            let timeOfEnd = -editor.startDate.timeIntervalSince(Date())
            timeInterval.upperValue = timeOfEnd
            wtrack?.endTime = Int(timeOfEnd)
            
            let fmt = DateComponentsFormatter()
            fmt.allowedUnits = [.minute, .second]
            let timestring = fmt.string(from: timeInterval.upperValue)
            timeInterval.upperTextValue = timestring
            
            fmt.zeroFormattingBehavior = .pad
            let duration = fmt.string(from: Double(wtrack!.durationTime))
            playedIntervalLabel.text = duration!
            
            appleMusic.stopPlaying()
            timer = nil
        }
    }
    
    @objc
    func updateTime() {
        if( self.detailViewTableViewControler == nil ) {
            timer = nil
            return
        }
        DispatchQueue.main.async {
            let editor = self.detailViewTableViewControler!.playSongIntervalEditor
            switch editor.defineBoundState {
            case .none:
                self.timer = nil
                return
            case .start:
                let timeOfStart = -editor.startDate.timeIntervalSince(Date())
                self.timeInterval.lowerValue = timeOfStart
                
                let fmt = DateComponentsFormatter()
                fmt.allowedUnits = [.minute, .second]
                let timestring = fmt.string(from: self.timeInterval.lowerValue)
                self.timeInterval.lowerTextValue = timestring
            case .end:
                let timeOfEnd = -editor.startDate.timeIntervalSince(Date())
                self.timeInterval.upperValue = timeOfEnd
                
                let fmt = DateComponentsFormatter()
                fmt.allowedUnits = [.minute, .second]
                let timestring = fmt.string(from: self.timeInterval.upperValue)
                self.timeInterval.upperTextValue = timestring
            }
        }
    }
    
    func configureEditing() {
        let editor = detailViewTableViewControler!.playSongIntervalEditor
        
        switch editor.defineBoundState {
        case .none:
            editButton.setTitle("Set start time", for: .normal)
        case .start:
            editButton.setTitle( "Set end time", for: .normal)
        case .end:
            editButton.setTitle( "Edit Interval", for: .normal)
        }
    }
}

class PlaySongIntervalEditor {
    enum DefineBoundState { case none, start, end }
    var defineBoundState = DefineBoundState.none
    var startDate = Date()
    var row = -1
}

class DetailViewTableViewControler : UITableViewController {
    weak var appleMusic : FetchAppleMusic?
    var wplaylist = WorkoutMusicPlayList()
    var playSongIntervalEditor = PlaySongIntervalEditor()
    
    @IBOutlet weak var playSelectedButtonItem: UIBarButtonItem!

    var detailItem: FetchAppleMusic.PlayListInfo? {
        didSet {
            // Update the view.
            configureView()
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            let playList = FetchAppleMusic.PlayListInfo(name: detail.name, description: detail.description, url: detail.url)
            appleMusic?.getTracksForPlaylist(playList:  playList, completion: { (tracks) in
                var totalDuration : Double = 0
                for track in tracks {
                    totalDuration += Double(track.durationInMs)
                }
                
                self.wplaylist = WorkoutMusicPlayList(songs: tracks)
                
                DispatchQueue.main.async {
                    // Your UI Updation here
                    self.title = self.wplaylist.detailText()
                    self.tableView.reloadData()
                    
                    for track in tracks.enumerated() {
                        let songBpm = FetchSongBPM()
                        songBpm.getSongPBM(song: track.element, completion: { (bpm) in
                            self.wplaylist.tracks[track.offset].song.bpm = bpm
                            
                            DispatchQueue.main.async {
                                if( self.playSongIntervalEditor.row != track.offset ) {
                                     self.tableView.reloadRows(at: [IndexPath(row: track.offset, section: 0)], with: .none)
                                }
                            }
                        })
                    }
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       // navigationItem.rightBarButtonItem = self.editButtonItem
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveWPlayList(_:)))
        navigationItem.rightBarButtonItems = [self.editButtonItem, saveButton]
        navigationItem.leftItemsSupplementBackButton = true
        
        playSelectedButtonItem.isEnabled = false
        
        // Do any additional setup after loading the view.
        configureView()
    }

    
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
    }
    
    // Enable movement up/down of the songs.
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = self.wplaylist.tracks[sourceIndexPath.row]
        wplaylist.tracks.remove(at: sourceIndexPath.row)
        wplaylist.tracks.insert(movedObject, at: destinationIndexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func configureCell(_ cell: DetailViewTrackListCell, with: WorkoutMusicPlayListTrack, row: Int) {
        cell.wtrack = with
        cell.row = row
        cell.detailViewTableViewControler = self
        
        cell.songName.text = with.song.name
        cell.songAuthor.text = with.song.artistName
        
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
        
        if( row == playSongIntervalEditor.row ) {
            cell.configureEditing()
        }
        if( tableView.isEditing ) {
            cell.timeInterval.isHidden = true
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        playSelectedButtonItem.isEnabled = true
    }
    
    func play( wtracks: [WorkoutMusicPlayListTrack], complete: Bool = false) {
        appleMusic?.playSongs(wtracks: wtracks, complete: complete)
        
        /*
        let playListQuery = MPMediaQuery.playlists()
        let collections = playListQuery.collections
        for collection in collections! {
            print(collection.description)
            for item in collection.items {
                print(item.albumTitle)
                print(item.playbackStoreID)
            }
        }
        */
    }
    
    func hitPlayForEdit(row: Int) {
        var wtracks = [WorkoutMusicPlayListTrack]()
        wtracks.append(wplaylist.tracks[row])
        play(wtracks: wtracks, complete: true)
    }
    
    @IBAction func hitPlaySelected(_ sender: Any) {
        var wtracks = [WorkoutMusicPlayListTrack]()
        let selectedRows = tableView.indexPathsForSelectedRows
        if( selectedRows == nil ) {
            wtracks = wplaylist.tracks
        } else {
            for row in selectedRows! {
                wtracks.append(wplaylist.tracks[row.row])
            }
        }
        play(wtracks: wtracks)
    }
    
    @IBAction func hitPlay(_ sender: Any) {
        let wtracks = wplaylist.tracks
        play(wtracks: wtracks)
    }
    
    @objc
    func saveWPlayList(_ sender : Any) {
        
        let ac = UIAlertController(title: "Enter workout name", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0]
            self.saveWPlayList(name: answer.text!)
        }
        
        ac.addAction(submitAction)
        
        present(ac, animated: true)
    }
    
    func saveWPlayList(name: String) {
        guard let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            return
        }
        
        let playlistData = WorkoutPlayListData(context: managedObjectContext)
        playlistData.name = name
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
    }
}

