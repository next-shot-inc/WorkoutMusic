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
    
    var songs = [SearchAndSortPlaylistSongHelper.PlayListSong]()
    var filtered_songs = [SearchAndSortPlaylistSongHelper.PlayListSong]()
    var filter_applied = false
    
    func setTracks(tracks: [FetchAppleMusic.MusicTrackInfo]) {
        for track in tracks {
            let song = Song(track: track)
            songs.append(song)
        }
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
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if( filter_applied && filtered_songs.count == 0 ) {
            return 0
        }
        if( filter_applied == false ) {
            return songs.count
        } else {
            return filtered_songs.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SortPlayListDetailTableCell", for: indexPath) as! SortPlayListDetailTableCell
        
        if( filter_applied == false ) {
            configureCell(cell, with: songs[indexPath.row])
        } else {
            configureCell(cell, with: filtered_songs[indexPath.row])
        }
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
        if( filter_applied ) {
            return filtered_songs[index.row]
        } else {
            return songs[index.row]
        }
    }
    
    func findSong(song: Song) -> IndexPath? {
        let index : Int?
        if( filter_applied ) {
            index = filtered_songs.firstIndex(where: { (isong) -> Bool in
                isong === song
            })
        } else {
            index = songs.firstIndex { (isong) -> Bool in
                isong === song
            }
        }
        if( index != nil ) {
            return IndexPath(item: index!, section: 0)
        } else {
            return nil
        }
    }
    
    func reloadSong(song: SearchAndSortPlaylistSongHelper.PlayListSong) {
        if let index = findSong(song: song) {
            self.tableView.reloadRows(at: [index], with: .none)
            
            if( sortSongViewController?.playAndAddToPlayListView.controller.currentSelectedSong === song ) {
                self.tableView.selectRow(at: index, animated: false, scrollPosition: .none)
            }
        }
    }
    
    func reselectSongAfterReloadTable() {
        if let song = sortSongViewController?.playAndAddToPlayListView.controller.currentSelectedSong {
            let index = findSong(song: song)
            self.tableView.selectRow(at: index, animated: false, scrollPosition: .none)
        }
    }

}

class SortPlayListDetailViewController : UIViewController, PlayAndAddToPlayListViewDelegate {
    weak var appleMusic : FetchAppleMusic?
    var playListNames = [String]()
    var fromPlayListName = String()
    
    @IBOutlet weak var songsDetailView: UITableView!
    @IBOutlet weak var bpmValueLabel: UILabel!
    @IBOutlet weak var bpmStepper: UIStepper!
    @IBOutlet weak var applyFilterButton: UIButton!
    
    @IBOutlet weak var customContainerView: UIView!
    
    var playAndAddToPlayListView: UIPlayAndAddToPlayListView!
    
    var sortPlayListDetailViewTableController = SortPlayListDetailViewTableController()
    var searchAndSortHelper : SearchAndSortPlaylistSongHelper!
    
    var detailItem: FetchAppleMusic.PlayListInfo?
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            let playList = FetchAppleMusic.PlayListInfo(name: detail.name, description: detail.description, url: detail.url)
            
            appleMusic?.getTracksForPlaylist(playList:  playList, completion: { (tracks) in
               
                DispatchQueue.main.async {
                    self.sortPlayListDetailViewTableController.setTracks(tracks: tracks)
                    self.songsDetailView.reloadData()
                    
                    let songs = self.sortPlayListDetailViewTableController.songs
                     
                    // See which of the track exist in the current play list track
                    self.searchAndSortHelper.retrieveCurrentPlayListTracks( playListName: self.playAndAddToPlayListView.controller.currentPlayListName, completion: { musicTracks in
                        DispatchQueue.main.async {
                            self.searchAndSortHelper.existingPlayListTracks = musicTracks
                            for song in songs {
                                self.searchAndSortHelper.setInPlayListFlag(song: song)
                            }
                            self.songsDetailView.reloadData()
                            self.sortPlayListDetailViewTableController.reselectSongAfterReloadTable()
                        }
                    })
                    
                    // Get PBM for each song
                    for song in songs {
                        let songBpm = FetchSongBPM()
                        songBpm.getSongPBM(song: song.track!, completion: { (bpm) in
                            song.track!.bpm = bpm
                            
                            DispatchQueue.main.async {
                                self.sortPlayListDetailViewTableController.reloadSong(song: song)
                            }
                        })
                    }
                
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
        navigationItem.title = "Filter and Add tracks"
        
        playAndAddToPlayListView = loadNibView(nibName: "PlayAndAddToPlayListView", into:customContainerView) as? UIPlayAndAddToPlayListView
        playAndAddToPlayListView.delegate = self
        playAndAddToPlayListView.initialize(playListNames: playListNames, mainController: self, fromPlayList: fromPlayListName)
        
        // Do any additional setup after loading the view.
        configureView()
    }
    
    @IBAction func bpmValueChanged(_ sender: Any) {
        bpmValueLabel.text = String(Int(bpmStepper.value))
    }
    
    @IBAction func filterSongsByPBM(_ sender: Any) {
        let value = Int(bpmStepper.value)
        sortPlayListDetailViewTableController.filtered_songs = sortPlayListDetailViewTableController.songs.filter({ (song) -> Bool in
            song.track!.bpm < value + 9 && song.track!.bpm > value - 9
        })
        sortPlayListDetailViewTableController.filter_applied = true
        songsDetailView.reloadData()
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
            for song in self.sortPlayListDetailViewTableController.songs {
                self.searchAndSortHelper.setInPlayListFlag(song: song)
            }
            self.songsDetailView.reloadData()
            self.sortPlayListDetailViewTableController.reselectSongAfterReloadTable()
        }
    }
}
