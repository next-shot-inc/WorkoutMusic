//
//  SearchSongByPBM.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/20/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

/// Class associated to the UITableViewCell to display songName, author, and different
/// status indicators.
class SearchSongTableCell : UITableViewCell {
    weak var controller: SearchSongTableViewControler?
    
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var authorName: UILabel!
    @IBOutlet weak var foundMusicWidget: UIImageView!
    @IBOutlet weak var addedToPlaylistWidget: UIImageView!
    @IBOutlet weak var notFoundMusicWidget: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
}

/// The controller linked to the table listing the song retrieve from the
/// FetchSongBPM query.

class SearchSongTableViewControler : UITableViewController {
    class SearchedSong : SearchAndSortPlaylistSongHelper.PlayListSong {
        let song: FetchSongBPM.Song
        enum SearchStatus { case notSearched, searchedAndFound, searchedAndNotFound }
        var search : SearchStatus = .notSearched
        
        init(song: FetchSongBPM.Song) {
            self.song = song
            super.init()
        }
        
        override func songName() -> String? {
            return track == nil ? song.name : track!.name
        }
        override func albumName() -> String? {
            return track == nil ? song.albumName : track!.albumName
        }
    }
    var genres = [String]()
    var songs = [Int: [SearchedSong]]()
    var playing = false
    weak var searchSongViewController : SearchSongViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setSongs(songs: [FetchSongBPM.Song]) {
        self.genres.removeAll()
        self.songs.removeAll()
        for song in songs {
            let genre = song.genres[0].capitalized
            var sectionIndex = genres.firstIndex(of: genre)
            if( sectionIndex == nil ) {
                genres.append(genre)
                sectionIndex = genres.count-1
            }
            var songsInGenre = self.songs[sectionIndex!]
            if( songsInGenre == nil ) {
                songsInGenre = [SearchedSong]()
            }
            songsInGenre!.append(SearchedSong(song: song))
            self.songs[sectionIndex!] = songsInGenre!
        }
    }
    
    func findSong(song: SearchedSong) -> IndexPath? {
        for songList in self.songs.values.enumerated() {
            let firstIndex = songList.element.firstIndex { (isong) -> Bool in
                isong === song
            }
            if( firstIndex != nil ) {
                return IndexPath(row: firstIndex!, section: songList.offset)
            }
        }
        return nil
    }
    
    func getSong(index: IndexPath) -> SearchedSong? {
        if let songList = self.songs[index.section] {
            if( index.row >= 0 && index.row < songList.count ) {
                return songList[index.row]
            }
        }
        return nil
    }
    
    func reloadSong(song: SearchedSong) {
        if let index = findSong(song: song) {
            if let cell = tableView.cellForRow(at: index) as? SearchSongTableCell {
                configureCell(cell: cell, song: song)
                cell.stackView.setNeedsLayout()
                cell.layoutIfNeeded()
            } else {
                self.tableView.reloadRows(at: [index], with: .middle)
            }
        }
    }
    
    func changeCurrentPlayListName() {
        for songList in self.songs.values.enumerated() {
            for song in songList.element.enumerated() {
                song.element.inPlayList = false
            }
        }
        tableView.reloadData()
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        let youHaveData = searchSongViewController?.appleMusic != nil
        if youHaveData {
            tableView.separatorStyle = .singleLine
            tableView.backgroundView = nil
            return genres.count
        } else {
            let noDataLabel: UILabel  = UILabel(frame: CGRect(x: 20, y: 0, width: tableView.bounds.size.width - 20, height: tableView.bounds.size.height))
            noDataLabel.text = "Apple Music service not available"
            noDataLabel.textColor     = UIColor.black
            noDataLabel.textAlignment = .center
            noDataLabel.numberOfLines = 0
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if( genres.count == 0 ) {
            return ""
        }
        return genres[section]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if( searchSongViewController?.appleMusic == nil ) {
            return 0
        }
        return songs[section]!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchSongTableCell", for: indexPath) as! SearchSongTableCell
        
        configureCell(cell: cell, indexPath : indexPath)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let song = getSong(index: indexPath) {
            searchSongViewController?.setSelectedSong(song: song)
        }
    }
    
    func configureCell(cell: SearchSongTableCell, indexPath: IndexPath) {
        if let song = getSong(index: indexPath) {
            configureCell(cell: cell, song: song)
        }
    }
    
    func configureCell(cell: SearchSongTableCell, song: SearchedSong) {
        cell.songName.text = song.song.name
        cell.authorName.text = song.song.authorName
        cell.controller = self
        cell.addedToPlaylistWidget.isHidden = !song.inPlayList
        cell.foundMusicWidget.isHidden = song.search != .searchedAndFound
        cell.notFoundMusicWidget.isHidden = song.search != .searchedAndNotFound
        
        if( searchSongViewController?.selectedSong === song ) {
            cell.isSelected = true
        }
    }
}

/// The controller managing the tableView, the search button and the add to play list widget.

class SearchSongViewController : UIViewController, PlayAndAddToPlayListViewDelegate {
    let defaultPlayList = "workout music playlist"
    
    var appleMusic: FetchAppleMusic? {
        didSet {
            appleMusicOrViewInitialized()
        }
    }
    
    @IBOutlet weak var bpmStepper: UIStepper!
    @IBOutlet weak var bpmValue: UILabel!
    @IBOutlet weak var songsTableView: UITableView!
    
    @IBOutlet weak var searchButtton: UIButton!
    @IBOutlet weak var searchResultLabel : UILabel!
    
    @IBOutlet weak var customContainerView: UIView!
    var searchSongTableViewController = SearchSongTableViewControler()
    
    var searchAndSortHelper : SearchAndSortPlaylistSongHelper!
    var playAndAddToPlayListView: UIPlayAndAddToPlayListView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchSongTableViewController.searchSongViewController = self
        
        songsTableView.delegate = searchSongTableViewController
        songsTableView.dataSource = searchSongTableViewController
        searchSongTableViewController.tableView = songsTableView
        
        playAndAddToPlayListView = loadNibView(nibName: "PlayAndAddToPlayListView", into:customContainerView) as? UIPlayAndAddToPlayListView
        playAndAddToPlayListView.delegate = self
        playAndAddToPlayListView.initialize(playListNames: [defaultPlayList], mainController: self, fromPlayList: String())
        
        appleMusicOrViewInitialized()
    }
    
    func appleMusicOrViewInitialized() {
        if( viewIfLoaded == nil ) {
            return
        }
        if( appleMusic == nil ) {
            return 
        }
        searchAndSortHelper = SearchAndSortPlaylistSongHelper(appleMusic: appleMusic!)
        
        self.searchAndSortHelper.retrieveCurrentPlayListTracks( playListName: defaultPlayList, completion: { musicTracks in
            DispatchQueue.main.async {
                self.searchAndSortHelper.existingPlayListTracks = musicTracks
                self.searchButtton.isEnabled = true
                self.checkForSongsInPlayList(update: false)
            }
        })
        
        self.appleMusic?.searchAllLibraryPlaylists( completion: { (playLists) in
            DispatchQueue.main.async {
                self.playAndAddToPlayListView.setPlayLists(playListNames: playLists.map({ (info) -> String in
                    info.name
                }), fromPlayList: String())
            }
        })
    }
    
    @IBAction func bpmValueChanged(_ sender: Any) {
        bpmValue.text = String(Int(bpmStepper.value))
    }
    
    @IBAction func searchButtonClicked(_ sender: Any) {
        let fetchSong = FetchSongBPM()
        let bpm = Int(bpmStepper.value)
        searchButtton.isHighlighted = true
        fetchSong.getSongForBPM(bpm: bpm) { (songs) in
            let filtered_songs = songs.filter({ (song) -> Bool in
                if( song.genres.count == 0 ) {
                    return false
                }
                let genre = song.genres[0]
                // To have song in only one genre so that there is only one tableCell associated to a song
                // simplifying the cell update process when the song music is retrieved, added to a playlist, etc.
                //for genre in song.genres {
                    let state = genreSettings.genresPreference[genre]
                    if( state != nil && state! ) {
                       return true
                    }
                //}
                return false
            })
            let tableViewCtrler = self.searchSongTableViewController
            tableViewCtrler.songs.removeAll()
            tableViewCtrler.setSongs(songs: filtered_songs)
            
            DispatchQueue.main.async {
                self.checkForSongsInPlayList(update: false)
                self.searchButtton.isHighlighted = false
                self.songsTableView.reloadData()
                if( filtered_songs.count > 1 ) {
                    self.searchResultLabel.text = "Found \(filtered_songs.count) songs"
                } else if( filtered_songs.count == 1 ) {
                    self.searchResultLabel.text = "Found one song"
                } else {
                    self.searchResultLabel.text = "No songs found"
                }
            }
        }
    }
    
    /// MARK - PlayAndAddToPlayListViewDelegate related functions
    
    func addedToPlayList(playListName: String, song: SearchAndSortPlaylistSongHelper.PlayListSong) {
        DispatchQueue.main.async {
            self.searchSongTableViewController.reloadSong(song: song as! SearchSongTableViewControler.SearchedSong)
            
            // Save the song in the BPM store as we are going to use it later in a playlist..
            let bpmStore = SongBPMStore()
            bpmStore.save(song: song.track!)
        }
    }
    
    func changedCurrentPlaylist(playListName: String, musicTracks: [FetchAppleMusic.MusicTrackInfo]) {
        DispatchQueue.main.async {
            self.searchAndSortHelper.existingPlayListTracks = musicTracks
            self.searchSongTableViewController.changeCurrentPlayListName()
            self.checkForSongsInPlayList(update: true)
        }
    }
    
    /// MARK - TableView related operations
    
    var selectedSong : SearchSongTableViewControler.SearchedSong? {
        get {
            return playAndAddToPlayListView?.selectedSong as? SearchSongTableViewControler.SearchedSong
        }
    }
    
    func setSelectedSong( song: SearchSongTableViewControler.SearchedSong) {
        playAndAddToPlayListView.setSelectedSong(song: song)
        
        if( song.track == nil && song.search == .notSearched ) {
            checkSongAvailability(song: song)
        }
    }
    
    private func checkSongAvailability(song: SearchSongTableViewControler.SearchedSong) {
        let search_song = FetchAppleMusic.SearchSongInfo(
            name: song.song.name, artistName: song.song.authorName, albumName: song.song.albumName
        )
            
        /*
        appleMusic.searchSongInLibrary(song: song, completion: { (musicTracks) in
            if( musicTracks.count == 1 ) {
                self.currentSelection!.track = musicTracks[0]
            }
        })
        */
           
        appleMusic?.seachSongInStore(song: search_song, completion: { (musicTracks) in
            DispatchQueue.main.async {
                if( musicTracks.count >= 1 ) {
                    song.track = musicTracks[0]
                    // Assign the track BPM from the BPMSong's BPM
                    song.track?.bpm = song.song.bpm
                    
                    // See if it is not already in the existing workout list
                    self.searchAndSortHelper.setInPlayListFlag(song: song)
                    
                    if( musicTracks[0].storeId != nil ) {
                        song.search = .searchedAndFound
                    }
                    
                    if( self.selectedSong === song ) {
                        // If the current song is still the same as when we called this function...
                        self.playAndAddToPlayListView.setPlayButtonState(song: song)
                    }
                    self.searchSongTableViewController.reloadSong(song: song)
                } else {
                    song.search = .searchedAndNotFound
                    self.searchSongTableViewController.reloadSong(song: song)
                }
            }
        })
    }
    
    // Cross-reference songs in current playlist
    private func checkForSongsInPlayList(update: Bool) {
        for songsPerGenre in searchSongTableViewController.songs.values {
            for song in songsPerGenre {
                for musicTrack in self.searchAndSortHelper.existingPlayListTracks {
                    if( musicTrack.artistName == song.song.authorName && musicTrack.albumName == song.song.albumName && musicTrack.shortName() == song.songName() ) {
                        if( musicTrack.storeId != nil ) {
                            song.search = .searchedAndFound
                            song.inPlayList = true
                            song.track = musicTrack
                            song.track?.bpm = song.song.bpm
                            if( update ) {
                                searchSongTableViewController.reloadSong(song: song)
                            }
                            break
                        }
                    }
                }
            }
        }
    }
    
}
