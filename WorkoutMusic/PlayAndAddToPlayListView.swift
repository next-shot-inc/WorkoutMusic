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
    func changedCurrentPlaylist(playListName: String)
    
    var searchAndSortHelper : SearchAndSortPlaylistSongHelper! { get set }
    var appleMusic : FetchAppleMusic? { get set }
}

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

class PlayAndAddToPlayListViewController {
    var currentPlayListName = "workout music playlist"
    var currentSelectedSong : SearchAndSortPlaylistSongHelper.PlayListSong?
    var playing = false
    
    let view: UIPlayAndAddToPlayListView
    var pickViewController = UIPlayListPickerViewController()
    
    init(view: UIPlayAndAddToPlayListView, playListNames: [String]) {
        self.view = view
        pickViewController.controller = self
        view.playListPickerView.dataSource = pickViewController
        view.playListPickerView.delegate = pickViewController
        pickViewController.playListNames = playListNames
        
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

    func setPlayListNames(playlistNames: [String]) {
        pickViewController.playListNames = playlistNames
        setupPlayListsPickerView()
    }
    
    func changeSelectedPlayList(row: Int) {
        let name = pickViewController.playListNames[row]
        currentPlayListName = name
        
        view.delegate?.searchAndSortHelper.retrieveCurrentPlayListTracks( playListName: name, completion: { (_) in
            self.view.delegate?.changedCurrentPlaylist(playListName: name)
        })
    }

}

class UIPlayAndAddToPlayListView : UIView {
    
    var delegate : PlayAndAddToPlayListViewDelegate?
    var mainController : UIViewController?
    var controller: PlayAndAddToPlayListViewController!
    
    @IBOutlet weak var addMusicButton: UIButton!
    @IBOutlet weak var playMusicButton: UIButton!
    @IBOutlet weak var selectedSongLabel: UILabel!
    @IBOutlet weak var playListPickerView: UIPickerView!

    func initialize(playListNames: [String], mainController: UIViewController) {
        controller = PlayAndAddToPlayListViewController(view: self, playListNames: playListNames)
        self.mainController = mainController
    }
    
    func setPlayLists(playListNames: [String]) {
        controller.setPlayListNames(playlistNames: playListNames)
    }
    
    func setSelectedSong( song: SortPlayListDetailViewTableController.Song) {
        setPlayButtonState(song: song)
        
        if( controller.playing && song !== controller.currentSelectedSong ) {
            // stop current song
            playMusicTrack(self)
        }
        controller.currentSelectedSong = song
        self.selectedSongLabel.text = song.songName()
    }
    
    func setPlayButtonState(song: SortPlayListDetailViewTableController.Song) {
        
        self.playMusicButton.isEnabled = false
        self.addMusicButton.isEnabled = false
        
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
        
        delegate?.searchAndSortHelper.retrieveCurrentPlayListTracks( playListName: name, completion: { _ in 
            self.delegate?.changedCurrentPlaylist(playListName: name)
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
        let playListName = controller.currentPlayListName
        guard let song = controller.currentSelectedSong else {
            return
        }
        
        delegate?.searchAndSortHelper.addToPlayList(playListName: playListName, song: song) { (_) in
            self.delegate?.addedToPlayList(playListName: playListName, song: song)
        }
    }
}
