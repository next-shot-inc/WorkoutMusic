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

class SearchSongGenreCell : UICollectionViewCell {
    weak var controller: SearchSongGenresCollectionViewController?
    
    @IBAction func toggleButtonPushed(_ sender: Any) {
        toggleButton.isSelected = !toggleButton.isSelected
        controller?.set(genre: toggleButton.title(for: .normal) ?? "", selected: toggleButton.isSelected)
    }
    @IBOutlet weak var toggleButton: UIButton!
}

class SearchSongGenresCollectionViewController : UICollectionViewController {
    var genres = ["electronic", "rock", "heavy metal", "pop", "jazz", "country", "hip hop", "rap", "classical"]
    var selectedGenres = [String:Bool]()
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return genres.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GenreCollectionViewCell", for: indexPath) as! SearchSongGenreCell
        
        cell.toggleButton.setTitle(genres[indexPath.row], for: .normal)
        cell.toggleButton.setTitle(genres[indexPath.row], for: .selected)
        if let state = selectedGenres[genres[indexPath.row]] {
            cell.toggleButton.isSelected = state
        }
        cell.controller = self
        return cell
    }
    func set(genre: String, selected: Bool) {
        selectedGenres[genre] = selected
    }
}

class SearchSongTableCell : UITableViewCell {
    weak var controller: SearchSongTableViewControler?
    
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var authorName: UILabel!
    @IBOutlet weak var foundMusicWidget: UIImageView!
    @IBOutlet weak var addedToPlaylistWidget: UIImageView!
    @IBOutlet weak var notFoundMusicWidget: UIImageView!
}

class SearchSongTableViewControler : UITableViewController {
    class SearchedSong {
        let song: FetchSongBPM.Song
        var track: FetchAppleMusic.MusicTrackInfo?
        enum SearchStatus { case notSearched, searchedAndFound, searchedAndNotFound }
        var search : SearchStatus = .notSearched
        var added = false
        init(song: FetchSongBPM.Song) {
            self.song = song
        }
    }
    var songs = [SearchedSong]()
    var playing = false
    weak var searchSongViewController : SearchSongViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchSongTableCell", for: indexPath) as! SearchSongTableCell
        
        configureCell(cell: cell, row : indexPath.row)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchSongViewController?.setSelectedSong(song: songs[indexPath.row])
    }
    
    func configureCell(cell: SearchSongTableCell, row: Int) {
        cell.songName.text = songs[row].song.name
        cell.authorName.text = songs[row].song.authorName
        cell.controller = self
        cell.addedToPlaylistWidget.isHidden = !songs[row].added
        cell.foundMusicWidget.isHidden = songs[row].search != .searchedAndFound
        cell.notFoundMusicWidget.isHidden =
            songs[row].search != .searchedAndNotFound
    }
}

class SearchSongViewController : UIViewController {
    @IBOutlet weak var bpmStepper: UIStepper!
    @IBOutlet weak var bpmValue: UILabel!
    @IBOutlet weak var songsTableView: UITableView!
    @IBOutlet weak var genreCollectionView: UICollectionView!
    
    @IBOutlet weak var playMusicButton: UIButton!
    
    @IBOutlet weak var searchButtton: UIButton!
    @IBOutlet weak var addMusicButton: UIButton!
    @IBOutlet weak var searchResultLabel : UILabel!
    
    var searchSongTableViewController = SearchSongTableViewControler()
    var genreCollectionViewController = SearchSongGenresCollectionViewController()
    var existingWorkoutPlayListTracks = [FetchAppleMusic.MusicTrackInfo]()
    
    var currentSelection : SearchSongTableViewControler.SearchedSong?
    var playing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable search button until the apple music service is on.
        searchButtton.isEnabled = false
        
        appleMusic.setup( completion: { () -> () in
            // Retrieve the current content of the workout play list
            // So that we do not add the same song multiple time
            let playListName = "workout music playlist"
            appleMusic.searchOnePlaylist(searchTerm: playListName, exactMatch: true, completion: { (playListInfos) in
                if( playListInfos.count == 1 ) {
                    appleMusic.getTracksForPlaylist(playList: playListInfos[0]) { (musicTracks) in
                        self.existingWorkoutPlayListTracks = musicTracks
                    }
                }
                DispatchQueue.main.async {
                    self.searchButtton.isEnabled = true
                }
            })
        })
        
        setPlayButtonState()
        
        searchSongTableViewController.searchSongViewController = self
        
        songsTableView.delegate = searchSongTableViewController
        songsTableView.dataSource = searchSongTableViewController
        searchSongTableViewController.tableView = songsTableView
        
        genreCollectionView.delegate = genreCollectionViewController
        genreCollectionView.dataSource = genreCollectionViewController
        for g in genreCollectionViewController.genres {
            genreCollectionViewController.selectedGenres[g] = true
        }
    }
    
    @IBAction func bpmValueChanged(_ sender: Any) {
        bpmValue.text = String(Int(bpmStepper.value))
    }
    
    @IBAction func searchButtonClicked(_ sender: Any) {
        let fetchSong = FetchSongBPM()
        let bpm = Int(bpmStepper.value)
        fetchSong.getSongForBPM(bpm: bpm) { (songs) in
            let filtered_songs = songs.filter({ (song) -> Bool in
                for genre in song.genres {
                    let state = self.genreCollectionViewController.selectedGenres[genre]
                    if( state != nil && state! ) {
                       return true
                    }
                }
                return false
            })
            let tableViewCtrler = self.searchSongTableViewController
            tableViewCtrler.songs.removeAll()
            for song in filtered_songs {
                tableViewCtrler.songs.append(SearchSongTableViewControler.SearchedSong(song: song))
            }
            DispatchQueue.main.async {
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
    
    func setSelectedSong( song: SearchSongTableViewControler.SearchedSong) {
        currentSelection = song
        if( song.track == nil && song.search == .notSearched ) {
            checkSongAvailability()
        }
        setPlayButtonState()
    }
    
    func reloadCurrentSelectedRow() {
        let index = searchSongTableViewController.songs.firstIndex { (song) -> Bool in
            currentSelection === song
        }
        if( index != nil ) {
            self.songsTableView.reloadRows(at: [IndexPath(row: index!, section: 0)], with: .none)
        }
    }
    
    // If the current song has been found with the correct
    // play information, enable the play and add button
    func setPlayButtonState() {
        self.playMusicButton.isEnabled = false
        self.addMusicButton.isEnabled = false
        
        if( currentSelection?.track != nil ) {
            let musicTrack = currentSelection!.track!
            
            // See if it is not already in the existing workout list
            let firstIndex = existingWorkoutPlayListTracks.firstIndex { (ex_musicTrack) -> Bool in
                ex_musicTrack.albumName == musicTrack.albumName && ex_musicTrack.name == musicTrack.name
            }
            currentSelection!.added = firstIndex != nil
            
            switch musicTrack.playId {
            case .catalog:
                self.playMusicButton.isEnabled = true
                currentSelection!.search = .searchedAndFound
                self.addMusicButton.isEnabled = !currentSelection!.added
            case .purchased:
                self.playMusicButton.isEnabled = true
                currentSelection!.search = .searchedAndFound
                self.addMusicButton.isEnabled = !currentSelection!.added
            default:
                print("got library id only")
            }
        }
    }
    
    func checkSongAvailability() {
        guard let insong = currentSelection?.song  else {
            return
        }
        let song = FetchAppleMusic.SearchSongInfo(
            name: insong.name, artistName: insong.authorName, albumName: insong.albumName
        )
            
        /*
        appleMusic.searchSongInLibrary(song: song, completion: { (musicTracks) in
            if( musicTracks.count == 1 ) {
                self.currentSelection!.track = musicTracks[0]
            }
        })
        */
           
        appleMusic.seachSongInStore(song: song, completion: { (musicTracks) in
            DispatchQueue.main.async {
                if( musicTracks.count >= 1 ) {
                    self.currentSelection!.track = musicTracks[0]
                    self.setPlayButtonState()
                    self.reloadCurrentSelectedRow()
                } else {
                    self.currentSelection!.search = .searchedAndNotFound
                    self.reloadCurrentSelectedRow()
                }
            }
        })
    }
       
    @IBAction func playMusicTrack(_ sender: Any) {
        if( playing ) {
            appleMusic.stopPlaying()
            
            playMusicButton.setTitle("Play", for: .normal)
            playing = false
        } else {
            if( currentSelection?.track != nil ) {
                appleMusic.playSongs(tracks: [currentSelection!.track!])
                
                // Change the "role of the button"
                playMusicButton.setTitle("Stop", for: .normal)
                playing = true
            }
        }
    }
    
    @IBAction func addMusicToPlaylist(_ sender: Any) {
        let playListName = "workout music playlist"
        appleMusic.searchOnePlaylist(searchTerm: playListName, exactMatch: true, completion: { (playListInfos) in
            if( playListInfos.count == 0 ) {
                appleMusic.createPlayList(playListName: playListName, completion: { (playListInfo) in
                    appleMusic.addTrackToPlayList(
                        playList: playListInfos[0], track: self.currentSelection!.track!, completion : {
                            DispatchQueue.main.async {
                                self.currentSelection?.added = true
                                self.reloadCurrentSelectedRow()
                            }
                    })
                })
            } else {
                appleMusic.addTrackToPlayList(playList: playListInfos[0], track: self.currentSelection!.track!, completion: {
                      DispatchQueue.main.async {
                          self.currentSelection?.added = true
                          self.reloadCurrentSelectedRow()
                      }
                })
            }
        })
        
    }
}
