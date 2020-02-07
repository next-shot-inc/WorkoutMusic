//
//  SortPlayListMasterViewController.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/26/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit

class SortPlayListMasterCell : UITableViewCell {
    @IBOutlet weak var playListName: UILabel!
    @IBOutlet weak var playListDescription: UILabel!
    @IBOutlet weak var artworkPlaylistCollectionView: UICollectionView!
    var musicArtworkCollectionDelegate : MusicArtworkCollectionDelegate?
}

class SortPlayListMasterViewController : UITableViewController {
    var appleMusic : FetchAppleMusic? {
        didSet {
            if viewIfLoaded != nil {
                self.insertNewObject(self)
            }
        }
    }
    var userPlayLists = [FetchAppleMusic.PlayListInfo]()
    var spinnerCtrler = ShowSpinnerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if( appleMusic != nil ) {
            insertNewObject(self)
        }
    }

    @objc
    func insertNewObject(_ sender: Any) {
         DispatchQueue.main.async {
            self.spinnerCtrler.showSpinner(onView: self.view)
        }
        
        appleMusic?.searchAllLibraryPlaylists( completion: { (playLists) in
            self.userPlayLists = playLists
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.spinnerCtrler.removeSpinner()
            }
        })
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = userPlayLists[indexPath.row]
                let controller = segue.destination as! SortPlayListDetailViewController
                controller.appleMusic = appleMusic
                controller.detailItem = object
                controller.playListNames = userPlayLists.map({ (info) -> String in
                    info.name
                })
                controller.fromPlayListName = object.name
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        let youHaveData = userPlayLists.count != 0
        if youHaveData {
            tableView.separatorStyle = .singleLine
            tableView.backgroundView = nil
            return 1
        } else {
            let noDataLabel: UILabel  = UILabel(frame: CGRect(x: 20, y: 0, width: tableView.bounds.size.width - 20, height: tableView.bounds.size.height))
            if( appleMusic == nil ) {
                noDataLabel.text = "Apple Music service not available. Cannot fetch and sort playlists"
            } else {
                noDataLabel.text = "No Music library playlist available"
            }
            noDataLabel.textColor     = UIColor.black
            noDataLabel.textAlignment = .center
            noDataLabel.numberOfLines = 0
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userPlayLists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SortPlayListMasterCell", for: indexPath)
        let event = userPlayLists[indexPath.row]
        configureCell(cell, withPlayList: event)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    func configureCell(_ cell: UITableViewCell, withPlayList playlist: FetchAppleMusic.PlayListInfo) {
        let ecell = cell as? SortPlayListMasterCell
        ecell!.playListName!.text = playlist.name
        ecell!.playListDescription!.text = playlist.description
        
        ecell!.musicArtworkCollectionDelegate = MusicArtworkCollectionDelegate()
        ecell!.musicArtworkCollectionDelegate!.collectionView = ecell!.artworkPlaylistCollectionView
        ecell!.artworkPlaylistCollectionView.dataSource = ecell!.musicArtworkCollectionDelegate
        ecell!.musicArtworkCollectionDelegate!.appleMusic = appleMusic
        ecell!.musicArtworkCollectionDelegate!.playlist = playlist
    }
    
}

/**********************************************************/

// Display a collection of Albums image of the playlist.
class MusicArtworkCollectionViewCell : UICollectionViewCell {
    @IBOutlet weak var image: UIImageView!
    
}

class MusicArtworkCollectionDelegate : NSObject, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return artworks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MusicArtworkCollectionViewCell", for: indexPath) as! MusicArtworkCollectionViewCell
        
        let artwork = artworks[indexPath.row]
        cell.image.load(url: artwork.imageURL(size: CGSize(width: 24, height: 24)))
        return cell
    }
   
    var artworks = [AppleMusicArtwork]()
    var appleMusic : FetchAppleMusic?
    weak var collectionView : UICollectionView?
    
    var playlist : FetchAppleMusic.PlayListInfo? {
        didSet {
            appleMusic?.getTracksForPlaylist(playList: playlist!, limit : 4, completion: { (tracks) in
                for track in tracks {
                    if( track.artworkUrl != nil && !track.artworkUrl!.isEmpty ) {
                        self.artworks.append(AppleMusicArtwork(url: track.artworkUrl!))
                    }
                }
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
            })
        }
    }
}
