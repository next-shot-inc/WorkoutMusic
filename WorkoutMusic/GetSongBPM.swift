//
//  GetSongBPM.swift
//  WorkoutMusic
//
//  Created by next-shot on 2/1/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation

/***********************************************************************************************/

// Using https://getsongbpm.com/api

class FetchSongBPM {
    let api_key = "18c8f804a043762df117e7fb79b2f9e3"
    
    func getSongPBM(song: FetchAppleMusic.MusicTrackInfo, completion: @escaping (Int)->() ) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.getsongbpm.com"
        components.path = "/search/"
        
        components.queryItems = [
            URLQueryItem(name: "api_key", value: api_key),
            URLQueryItem(name: "type", value: "both"),
            URLQueryItem(name: "lookup", value: "song:"+song.shortName()+"artist:"+song.artistName)
        ]
        
        guard let url = components.url else {
            return
        }
        print(url)
        let request = URLRequest(url: url)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if( data != nil ) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    
                    print("Searching for song \(song.name) from \(song.artistName) in GetSongBPM Database")
                    let prdata = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
                    let jsonString = NSString(data: prdata, encoding: String.Encoding.utf8.rawValue)
                    print(jsonString!)
                    
                    // Returns a search result object
                    if let response = json as? [String: Any] {
                        if let search_datas = response["search"] as? [[String:Any]] {
                            for data in search_datas {
                                let song_title = data["song_title"] as? String
                                if let artist = data["artist"] as? [String:Any] {
                                    let artistName = artist["name"] as? String
                                    // If we have an exact match or there is only one result.
                                    if( (artistName == song.artistName && song_title! == song.name) ||
                                        (search_datas.count == 1)
                                    ) {
                                        if let asongBPM = data["tempo"] as? String {
                                            if let songBPM = Int(asongBPM) {
                                                completion(songBPM)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                catch {
                   
                }
            }
        }
        task.resume()
    }
    
    struct Song {
        var name : String
        var authorName: String
        var albumName : String
        var genres : [String]
        var year : String
        var bpm : Int
    }
    
    func getSongForBPM(bpm: Int, completion: @escaping ([Song])->()) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.getsongbpm.com"
        components.path = "/tempo/"
        
        components.queryItems = [
            URLQueryItem(name: "api_key", value: api_key),
            URLQueryItem(name: "bpm", value: String(bpm))
        ]
        
        guard let url = components.url else {
            completion([])
            return
        }
        print(url)
        let request = URLRequest(url: url)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if( data != nil ) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    
                    print("Searching for song in GetSongBPM Database")
                    let prdata = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
                    let jsonString = NSString(data: prdata, encoding: String.Encoding.utf8.rawValue)
                    print(jsonString!)
                    
                    // Returns a search result object
                    if let response = json as? [String: Any] {
                        if let datas = response["tempo"] as? [[String:Any]] {
                            var songs = [Song]()
                            for data in datas {
                                let songName = data["song_title"] as? String
                                
                                let albumData = data["album"] as? [String:Any]
                                let albumName = albumData?["title"] as? String
                                let releaseYear = albumData?["year"] as? String
                                if let artist = data["artist"] as? [String:Any] {
                                    let artistName = artist["name"] as? String
                                    let genres = artist["genres"] as? [String]
                                    if( artistName != nil && songName != nil ) {
                                        songs.append(Song(name: songName!, authorName: artistName!, albumName: albumName ?? "", genres : genres ?? [], year: releaseYear ?? "", bpm: bpm))
                                    }
                                }
                            }
                            completion(songs)
                        }
                    }
                }
                catch {
                    
                }
            }
        }
        task.resume()
    }
}
