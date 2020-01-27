//
//  SearchAndSortHelper.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/26/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit

class SearchAndSortPlaylistSongHelper {
    var existingPlayListTracks = [FetchAppleMusic.MusicTrackInfo]()
    
    class PlayListSong {
        var track: FetchAppleMusic.MusicTrackInfo?
        var inPlayList = false
        init(track: FetchAppleMusic.MusicTrackInfo) {
            self.track = track
        }
        init() {
            self.track = nil
        }
        func songName() -> String? {
            return track?.name
        }
        func albumName() -> String? {
            return track?.albumName
        }
    }
    
    let appleMusic : FetchAppleMusic
    init(appleMusic: FetchAppleMusic) {
        self.appleMusic = appleMusic
    }
    
    func addToPlayList(playListName: String, song: PlayListSong, completion: @escaping (PlayListSong) -> ()) {
        guard let track = song.track else {
            return
        }
        appleMusic.searchOnePlaylist(searchTerm: playListName, exactMatch: true, completion: { (playListInfos) in
            if( playListInfos.count == 0 ) {
                self.appleMusic.createPlayList(playListName: playListName, completion: { (playListInfo) in
                    self.appleMusic.addTrackToPlayList(
                        playList: playListInfos[0], track: track, completion : {
                            DispatchQueue.main.async {
                                song.inPlayList = true
                                completion(song)
                            }
                    })
                })
            } else {
                self.appleMusic.addTrackToPlayList(playList: playListInfos[0], track: track, completion: {
                      DispatchQueue.main.async {
                          song.inPlayList = true
                          completion(song)
                      }
                })
            }
        })
    }
    
    func retrieveCurrentPlayListTracks( playListName: String, completion: @escaping ([FetchAppleMusic.MusicTrackInfo]) -> ()) {
        existingPlayListTracks.removeAll()
        
        appleMusic.searchOnePlaylist(searchTerm: playListName, exactMatch: true, completion: { (playListInfos) in
            if( playListInfos.count == 1 ) {
                self.appleMusic.getTracksForPlaylist(playList: playListInfos[0]) { (musicTracks) in
                    self.existingPlayListTracks = musicTracks
                    completion(musicTracks)
                }
            } else {
                self.existingPlayListTracks = []
                completion([])
            }
        })
    }
    
    func setInPlayListFlag(song: PlayListSong) {
        guard let track = song.track else {
            return
        }
        
        let firstIndex = self.existingPlayListTracks.firstIndex { (ex_musicTrack) -> Bool in
            ex_musicTrack.albumName == track.albumName && ex_musicTrack.name == track.name
        }
        song.inPlayList = firstIndex != nil
    }
    
}
