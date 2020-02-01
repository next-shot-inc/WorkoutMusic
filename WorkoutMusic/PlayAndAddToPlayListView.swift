//
//  PlayAndAddToPlayListView.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/27/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit

protocol PlayAndAddToPlayListViewDelegate {
    func addedToPlayList(playListName: String, song: SearchAndSortPlaylistSongHelper.PlayListSong)
    func changedCurrentPlaylist(playListName: String, musicTracks: [FetchAppleMusic.MusicTrackInfo])
    
    var searchAndSortHelper : SearchAndSortPlaylistSongHelper! { get set }
    var appleMusic : FetchAppleMusic? { get set }
}

// Display the possible playlist names
class UIPlayListPickerViewController : NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    var playListNames = [String]()
    weak var controller : PlayAndAddToPlayListViewController?
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return playListNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return playListNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        controller?.changeSelectedPlayList(row: row)
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {

        var pickerLabel = view as? UILabel;

        if (pickerLabel == nil) {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont(name: "Montserrat", size: 16)
            pickerLabel?.textAlignment = NSTextAlignment.center
        }

        pickerLabel?.text = playListNames[row]

        return pickerLabel!
    }
}

// Class that manages the UIPlayAndAddToPlayListView
// It manages the play list selection and the current song selection.

class PlayAndAddToPlayListViewController {
    var currentPlayListName = "workout music playlist"
    var currentSelectedSong : SearchAndSortPlaylistSongHelper.PlayListSong?
    var playing = false
    
    let view: UIPlayAndAddToPlayListView
    var pickViewController = UIPlayListPickerViewController()
    
    init(view: UIPlayAndAddToPlayListView, playListNames: [String], fromPlayList: String) {
        self.view = view
        pickViewController.controller = self
        view.playListPickerView.dataSource = pickViewController
        view.playListPickerView.delegate = pickViewController
        pickViewController.playListNames = playListNames
        if let firstIndex = pickViewController.playListNames.firstIndex(of: fromPlayList) {
            pickViewController.playListNames.remove(at: firstIndex)
        }
        
        setupPlayListsPickerView()
    }
    
    func setupPlayListsPickerView() {
        var firstIndex = pickViewController.playListNames.firstIndex(of: currentPlayListName)
        if( firstIndex == nil ) {
            pickViewController.playListNames.append(currentPlayListName)
            firstIndex = pickViewController.playListNames.count-1
        }
        view.playListPickerView.reloadAllComponents()
        view.playListPickerView.selectRow(firstIndex!, inComponent: 0, animated: false)
    }

    func setPlayListNames(playlistNames: [String], fromPlayList: String) {
        pickViewController.playListNames = playlistNames
        if let firstIndex = pickViewController.playListNames.firstIndex(of: fromPlayList) {
            pickViewController.playListNames.remove(at: firstIndex)
        }
        setupPlayListsPickerView()
    }
    
    func changeSelectedPlayList(row: Int) {
        let name = pickViewController.playListNames[row]
        currentPlayListName = name
        
        view.delegate?.searchAndSortHelper.retrieveCurrentPlayListTracks( playListName: name, completion: { (musicTracks) in
            self.view.delegate?.changedCurrentPlaylist(playListName: name, musicTracks: musicTracks)
        })
    }

}

// Class associated to .xib that defines the UI to play a song and add it to a playlist.
// Also allows a new playlist to be created.
class UIPlayAndAddToPlayListView : UIView {
    
    var delegate : PlayAndAddToPlayListViewDelegate?
    var mainController : UIViewController?
    var controller: PlayAndAddToPlayListViewController!
    
    @IBOutlet weak var addMusicButton: UIButton!
    @IBOutlet weak var playMusicButton: UIButton!
    @IBOutlet weak var selectedSongLabel: UILabel!
    @IBOutlet weak var playListPickerView: UIPickerView!
    @IBOutlet weak var artworkImageView: UIImageView!
    
    func initialize(playListNames: [String], mainController: UIViewController, fromPlayList: String) {
        controller = PlayAndAddToPlayListViewController(view: self, playListNames: playListNames, fromPlayList: fromPlayList)
        self.mainController = mainController
    }
    
    func setPlayLists(playListNames: [String], fromPlayList: String) {
        controller.setPlayListNames(playlistNames: playListNames, fromPlayList: fromPlayList)
    }
    
    func setSelectedSong( song: SearchAndSortPlaylistSongHelper.PlayListSong) {
        setPlayButtonState(song: song)
        
        if( controller.playing && song !== controller.currentSelectedSong ) {
            // stop current song
            playMusicTrack(self)
        }
        controller.currentSelectedSong = song
    }
    
    var selectedSong : SearchAndSortPlaylistSongHelper.PlayListSong? {
        get {
            return controller.currentSelectedSong
        }
    }
    
    func setPlayButtonState(song: SearchAndSortPlaylistSongHelper.PlayListSong) {
        
        self.playMusicButton.isEnabled = false
        self.addMusicButton.isEnabled = false
        self.selectedSongLabel.text = song.songName()
        
        if( song.track != nil ) {
            let musicTrack = song.track!
            
            switch musicTrack.playId {
            case .catalog:
                self.playMusicButton.isEnabled = true
                self.addMusicButton.isEnabled = !song.inPlayList
            case .purchased:
                self.playMusicButton.isEnabled = true
                self.addMusicButton.isEnabled = !song.inPlayList
            default:
                print("got library id only")
            }
            
            displayArtwork(song: song)
        }
    }
    
    func displayArtwork(song: SearchAndSortPlaylistSongHelper.PlayListSong) {
        if let artworkURL = song.track?.artworkUrl {
            let artwork = AppleMusicArtwork(url: artworkURL)
            self.artworkImageView.load(url: artwork.imageURL(size: CGSize(width: 64, height: 64)))
        }
    }
    
    @IBAction func addNewPlaylist(_ sender: Any) {
        let ac = UIAlertController(title: "Enter new play list name", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0]
            if( answer.text != nil && answer.text!.count > 0 ) {
                self.doChangeCurrentPlayList(name: answer.text!)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        ac.addAction(submitAction)
        ac.addAction(cancelAction)
        
        mainController?.present(ac, animated: true)
    }
    
    func doChangeCurrentPlayList(name: String) {
        controller.currentPlayListName = name
        
        delegate?.searchAndSortHelper.retrieveCurrentPlayListTracks( playListName: name, completion: { musicTracks in
            self.delegate?.changedCurrentPlaylist(playListName: name, musicTracks: musicTracks)
        })
        controller.setupPlayListsPickerView()
    }
    
    @IBAction func playMusicTrack(_ sender: Any) {
        if( controller.playing ) {
            delegate?.appleMusic?.stopPlaying()
            
            playMusicButton.setTitle("Play", for: .normal)
            controller.playing = false
        } else {
            guard let track = controller.currentSelectedSong?.track else {
                return
            }
            delegate?.appleMusic?.playSongs(tracks: [track])
                
            // Change the "role of the button"
            playMusicButton.setTitle("Stop", for: .normal)
            controller.playing = true
        }
    }
    
    @IBAction func addToPlayList(_ sender: Any) {
        addMusicButton.isHighlighted = true
        let playListName = controller.currentPlayListName
        guard let song = controller.currentSelectedSong else {
            return
        }
        
        delegate?.searchAndSortHelper.addToPlayList(playListName: playListName, song: song) { (_) in
            self.delegate?.addedToPlayList(playListName: playListName, song: song)
            DispatchQueue.main.async {
                self.addMusicButton.isHighlighted = false
            }
        }
    }
}
