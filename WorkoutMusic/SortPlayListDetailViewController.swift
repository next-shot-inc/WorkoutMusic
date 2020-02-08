//
//  SortPLayListDetailViewController.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/26/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit

class SortPlayListDetailTableCell : UITableViewCell {
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var authorName: UILabel!
    
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var inPlayListImage: UIImageView!
    @IBOutlet weak var storeIdMissingImage: UIImageView!
}

class SortPlayListDetailViewTableController : UITableViewController {
    typealias Song = SearchAndSortPlaylistSongHelper.PlayListSong
    
    weak var sortSongViewController : SortPlayListDetailViewController?
    
    var genres = [String]()
    var songs = [Int: [Song]]()
    
    var filtered_songs = [Int: [Song]]()
    var filter_applied = false
    
    func addTracks(tracks: [FetchAppleMusic.MusicTrackInfo]) -> [Song] {
        var added = [Song]()
        
        for track in tracks {
            let genre = track.genreName
            var sectionIndex = genres.firstIndex(of: genre)
            if( sectionIndex == nil ) {
                genres.append(genre)
                sectionIndex = genres.count-1
            }
            var songsInGenre = self.songs[sectionIndex!]
            if( songsInGenre == nil ) {
                songsInGenre = [Song]()
            }
            let song = Song(track: track)
            songsInGenre!.append(song)
            added.append(song)
            self.songs[sectionIndex!] = songsInGenre!
        }
        return added
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if( filter_applied && filtered_songs.count == 0 ) {
            let noDataLabel: UILabel  = UILabel(frame: CGRect(x: 20, y: 0, width: tableView.bounds.size.width - 20, height: tableView.bounds.size.height))
            noDataLabel.text          = "No songs found in the playlist at this BPM rate"
            noDataLabel.textColor     = UIColor.black
            noDataLabel.textAlignment = .center
            noDataLabel.numberOfLines = 0
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
            return 1
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
            return genres.count
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if( genres.count == 0 ) {
            return ""
        }
        return genres[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if( filter_applied && filtered_songs.count == 0 ) {
            return 0
        }
        if( filter_applied == false ) {
            if( genres.count == 0 ) {
                return 0
            }
            return songs[section]!.count
        } else {
            return filtered_songs[section]!.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SortPlayListDetailTableCell", for: indexPath) as! SortPlayListDetailTableCell
        
        configureCell(cell, with: getSong(index: indexPath)!)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let song = getSong(index: indexPath) {
            sortSongViewController?.playAndAddToPlayListView.setSelectedSong(song: song)
        }
    }
    
    func configureCell(_ cell: SortPlayListDetailTableCell, with: Song) {
        guard let track = with.track else {
            return
        }
        cell.songName.text  = track.name
        cell.authorName.text = track.artistName
        if( track.bpm != 0 ) {
            cell.bpmLabel.text = "BPM: \(track.bpm)"
        }
        cell.inPlayListImage.isHidden = !with.inPlayList
        
        switch track.playId {
        case .catalog:
            cell.storeIdMissingImage.isHidden = true
        case .purchased:
            cell.storeIdMissingImage.isHidden = true
        default:
            cell.storeIdMissingImage.isHidden = false
        }
    }
    
    func getSong(index: IndexPath) -> Song? {
        let songList : [Song]?
        if( filter_applied ) {
            songList = filtered_songs[index.section]
        } else {
            songList = songs[index.section]
        }
        if( songList != nil ) {
            if( index.row >= 0 && index.row < songList!.count ) {
               return songList![index.row]
            }
        }
        return nil
    }
    
    func findSong(song: Song) -> IndexPath? {
        func find(table: [Int: [Song]]) -> IndexPath? {
            for songList in table.values.enumerated() {
                let firstIndex = songList.element.firstIndex { (isong) -> Bool in
                    isong === song
                }
                if( firstIndex != nil ) {
                    return IndexPath(row: firstIndex!, section: songList.offset)
                }
             }
            return nil
        }
        if( filter_applied ) {
            return find(table: filtered_songs)
        } else {
            return find(table: songs)
        }
    }
    
    func reloadSong(song: SearchAndSortPlaylistSongHelper.PlayListSong) {
        if let index = findSong(song: song) {
            if let cell = tableView.cellForRow(at: index) as? SortPlayListDetailTableCell {
                configureCell(cell, with: song)
                cell.layoutIfNeeded()
            } else {
                self.tableView.reloadRows(at: [index], with: .none)
                
                if( sortSongViewController?.currentSong === song ) {
                    self.tableView.selectRow(at: index, animated: false, scrollPosition: .none)
                }
            }
            
        } else {
            // Song not found - If the filtered is applied see if the songs should not be added to that list
            if( filter_applied ) {
                let filterValue = Int(sortSongViewController!.bpmStepper.value)
                let songBpm = song.track?.bpm ?? 0
                if( songBpm < filterValue + 5 || songBpm >= filterValue - 5 ) {
                    if let section = genres.firstIndex(of: song.track!.genreName) {
                        var array = filtered_songs[section] ?? [Song]()
                        array.append(song)
                        filtered_songs[section] = array
                        let newIndexPath = IndexPath(row: array.count-1, section: section)
                        tableView.beginUpdates()
                        tableView.insertRows(at: [newIndexPath], with: .fade)
                        tableView.endUpdates()
                    }
                }
            }
        }
    }
    
    func reselectSongAfterReloadTable() {
        if let song = sortSongViewController?.playAndAddToPlayListView.controller.currentSelectedSong {
            let index = findSong(song: song)
            self.tableView.selectRow(at: index, animated: false, scrollPosition: .none)
        }
    }
    
    func filter(bpm: Int) {
        for elements in songs {
            let array = elements.value.filter({ (song) -> Bool in
                song.track!.bpm <= bpm + 5 && song.track!.bpm > bpm - 5
            })
            filtered_songs[elements.key] = array
        }
        filter_applied = true
        self.tableView.reloadData()
    }
    
    func allSongs() -> [Song] {
        var songs = [Song]()
        for list in self.songs.values {
            songs.append(contentsOf: list)
        }
        return songs
    }
}

/// Class to manage the multi-threading download counter of the BPM songs value
/// We need to protect the counter manipulation inside a specific queue.
class BPMLoadingDownCounter {
    var unsafeCounter = 0
    weak var label : UILabel?
    var counter : Int {
        return unsafeCounter
    }
    init() {
    }
    
    private let concurrentCounterQueue =
        DispatchQueue(label: "com.next-shot-inc.com.WorkoutMusic.bpmLoadingQueue", attributes: .concurrent)
    
    func add() {
        concurrentCounterQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }
            self.unsafeCounter = self.unsafeCounter - 1
        }
        DispatchQueue.main.async { [weak self] in
            self?.postContentAddedNotification()
        }
    }
    func postContentAddedNotification() {
        if( self.counter > 0 ) {
            self.label?.text = "\(self.counter) without BPMs information"
        } else {
            self.label?.text = ""
        }
    }
}

class SortPlayListDetailViewController : UIViewController, PlayAndAddToPlayListViewDelegate {
    weak var appleMusic : FetchAppleMusic?
    var playListNames = [String]()
    var fromPlayListName = String()
    var songsWithoutBPMs = BPMLoadingDownCounter()
    
    @IBOutlet weak var songsDetailView: UITableView!
    @IBOutlet weak var bpmValueLabel: UILabel!
    @IBOutlet weak var bpmStepper: UIStepper!
    @IBOutlet weak var applyFilterButton: UIButton!
    
    @IBOutlet weak var stillLoadingBPMLabel: UILabel!
    @IBOutlet weak var customContainerView: UIView!
    
    var playAndAddToPlayListView: UIPlayAndAddToPlayListView!
    
    var sortPlayListDetailViewTableController = SortPlayListDetailViewTableController()
    var searchAndSortHelper : SearchAndSortPlaylistSongHelper!
    
    var detailItem: FetchAppleMusic.PlayListInfo?
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            let playList = FetchAppleMusic.PlayListInfo(name: detail.name, description: detail.description, url: detail.url)
            fetchPlayListData(playList: playList, beginAt: 0)
           
            // See which of the track exist in the current play list track
            self.searchAndSortHelper.retrieveCurrentPlayListTracks( playListName: self.playAndAddToPlayListView.controller.currentPlayListName, completion: { musicTracks in
                DispatchQueue.main.async {
                    self.searchAndSortHelper.existingPlayListTracks = musicTracks
                    self.checkForSongsInPlayList()
                    self.sortPlayListDetailViewTableController.reselectSongAfterReloadTable()
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        songsDetailView.dataSource = self.sortPlayListDetailViewTableController
        songsDetailView.delegate = self.sortPlayListDetailViewTableController
        sortPlayListDetailViewTableController.tableView = songsDetailView
        
        sortPlayListDetailViewTableController.sortSongViewController = self
        
        searchAndSortHelper = SearchAndSortPlaylistSongHelper(appleMusic: appleMusic!)
        
        navigationItem.backBarButtonItem?.title = "Back"
        navigationItem.title = "Select from \"" + fromPlayListName + "\" & Add to ..."
        
        playAndAddToPlayListView = loadNibView(nibName: "PlayAndAddToPlayListView", into:customContainerView) as? UIPlayAndAddToPlayListView
        playAndAddToPlayListView.delegate = self
        playAndAddToPlayListView.initialize(playListNames: playListNames, mainController: self, fromPlayList: fromPlayListName)
        
        songsWithoutBPMs.label = stillLoadingBPMLabel
        
        // Do any additional setup after loading the view.
        configureView()
    }
    
    @IBAction func bpmValueChanged(_ sender: Any) {
        bpmValueLabel.text = String(Int(bpmStepper.value))
    }
    
    @IBAction func filterSongsByPBM(_ sender: Any) {
        let value = Int(bpmStepper.value)
        sortPlayListDetailViewTableController.filter(bpm: value)
        applyFilterButton.isSelected = true
    }
    
    @IBAction func filterButtonPushed(_ sender: Any) {
        applyFilterButton.isSelected = !applyFilterButton.isSelected
        sortPlayListDetailViewTableController.filter_applied = applyFilterButton.isSelected
        songsDetailView.reloadData()
    }
    
    // MARK - Protocol for PlayAndAddToPlayListViewDelegate
    
    func addedToPlayList(playListName: String, song: SearchAndSortPlaylistSongHelper.PlayListSong) {
        DispatchQueue.main.async {
           self.sortPlayListDetailViewTableController.reloadSong(song: song)
        }
    }
    
    func changedCurrentPlaylist(playListName: String, musicTracks: [FetchAppleMusic.MusicTrackInfo]) {
        DispatchQueue.main.async {
            self.searchAndSortHelper.existingPlayListTracks = musicTracks
            for songs in self.sortPlayListDetailViewTableController.songs.values {
                for song in songs {
                    self.searchAndSortHelper.setInPlayListFlag(song: song)
                }
            }
            self.songsDetailView.reloadData()
            self.sortPlayListDetailViewTableController.reselectSongAfterReloadTable()
        }
    }
    
    var currentSong : SearchAndSortPlaylistSongHelper.PlayListSong? {
        get {
            return playAndAddToPlayListView.selectedSong
        }
    }
    
    func fetchPlayListData(playList: FetchAppleMusic.PlayListInfo, beginAt: Int = 0) {
        
        appleMusic?.getTracksForPlaylist(playList:  playList, limit: 100, beginAt: beginAt, completion: { (tracks, moreToFetch) in
            
            DispatchQueue.main.async {
                let filtered_tracks = tracks.filter({ (track) -> Bool in
                    if( track.genreName.isEmpty ) {
                        return true
                    }
                    return genreSettings.genresPreference(appleGenreName: track.genreName)
                })
                
                let songs = self.sortPlayListDetailViewTableController.addTracks(tracks: filtered_tracks)
                self.checkForSongsInPlayList()
                self.songsDetailView.reloadData()
                
                self.songsWithoutBPMs.unsafeCounter += songs.count
                self.songsWithoutBPMs.postContentAddedNotification()
                
                // Get PBM for each song
                let songBPStorage = SongBPMStore()
                for song in songs {
                    if let songBPM = songBPStorage.retrieve(song: song.track!) {
                        self.songsWithoutBPMs.add()
                        song.track!.bpm = songBPM
                        continue
                    }
                    let fetchSongBpm = FetchSongBPM()
                    fetchSongBpm.getSongPBM(song: song.track!, completion: { (bpm) in
                        song.track!.bpm = bpm
                        self.songsWithoutBPMs.add()
                        
                        DispatchQueue.main.async {
                            self.sortPlayListDetailViewTableController.reloadSong(song: song)
                            songBPStorage.save(song: song.track!)
                        }
                    })
                }
            }
            
            if( moreToFetch > 0 ) {
                self.fetchPlayListData(playList: playList, beginAt: moreToFetch)
            }
        })
    }
    
    private func checkForSongsInPlayList() {
        for song in self.sortPlayListDetailViewTableController.allSongs() {
            self.searchAndSortHelper.setInPlayListFlag(song: song)
        }
        self.songsDetailView.reloadData()
    }
}
