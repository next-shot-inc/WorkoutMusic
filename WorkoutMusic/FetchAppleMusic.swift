//
//  FetechAppleMusic.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/18/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import StoreKit
import MediaPlayer

class FetchAppleMusic {
    var countryCode = String()
    var userToken = String()
    let developerToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NiIsImtpZCI6IlBHWDQ5WUc5UzQifQ.eyJpc3MiOiJBOFNSTTNFTkdOIiwiaWF0IjoxNTc5Mzc5NzIyLjI3MDg0MywiZXhwIjoxNTg0NTYzNzIyLjI3MDg0M30.5l5RtmvtguGz1W0OtoGind1XWHLqJceUeaz3SK4CjrjGGbADB3BpZ2Oih74IxhyF8iqFA71s6x9wGQz48AI_1g"
    var setupCompleted = false
    
    func checkCurrentMusicLibaryCapabilities( completion: @escaping ()->() ) {
        
        func requestMusicLibraryAccess( completion: @escaping ()->() )
        {
            // Asking for permission to access the music library on the device.
            SKCloudServiceController.requestAuthorization( {
                (clk_status: SKCloudServiceAuthorizationStatus) in
                switch(clk_status)
                {
                case .authorized:
                    print("Access granted.")
                    completion()
                case .denied, .restricted:
                     print("Access denied or restricted.")
                case .notDetermined:
                    print("Access cannot be determined.")
                @unknown default:
                   fatalError()
                }
            })
        }
        
        func checkMusicLibraryAuthorizationStatus()
        {
           switch SKCloudServiceController.authorizationStatus()
           {
           case .authorized:
            print("Access granted.")
            completion()
           case .notDetermined:
            requestMusicLibraryAccess( completion: completion)
           case .denied, .restricted:
            print("Access denied or restricted.")
           @unknown default:
               fatalError()
            }
        }
        
        checkMusicLibraryAuthorizationStatus()
    }
    
    func setup( completion: @escaping (_ error: String) -> ()) {
        if( setupCompleted  ) {
            completion("")
            return 
        }
        checkCurrentMusicLibaryCapabilities( completion: {
            let controler = SKCloudServiceController()
            
            func requestCodes() {
                controler.requestStorefrontCountryCode { (countryCode, error) in
                    if( countryCode != nil ) {
                        self.countryCode = countryCode!
                        
                        controler.requestUserToken(forDeveloperToken: self.developerToken) { (userToken, error) in
                            if( userToken != nil ) {
                                self.userToken = userToken!
                                completion("")
                            } else {
                                completion("Cannot access IMusic user credential")
                            }
                            self.setupCompleted = true
                        }
                    } else {
                        completion("Cannot access IMusic store")
                    }
                }
            }
            
            // You can only play music from Apple Music if the user has an account.
            // Once you've requested access to their music library, you can check the user's capabilities.
            controler.requestCapabilities { capabilities, error in
                if capabilities.contains(.musicCatalogPlayback) {
                    // User has Apple Music account
                    requestCodes()
                } else {
                    completion("Need Apple Music subscription to play from Apple Music")
                }
            }
            
        })
    }
    
    struct PlayListInfo {
        var name: String
        var description : String
        var url : String
    }
    
    func searchGlobalPlaylist(searchTerm : String = "workouts", completion : @escaping ([PlayListInfo]) -> ())  {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.music.apple.com"
        components.path = "/v1/catalog/\(countryCode)/search"
        
        components.queryItems = [
            URLQueryItem(name: "term", value: searchTerm),
            URLQueryItem(name: "limit", value: "3"),
            URLQueryItem(name: "types", value: "playlists"),
        ]
        
        guard let url = components.url else {
            return completion([])
        }
        var request = URLRequest(url: url)
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if( data != nil ) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    
                    if let response = json as? [String: Any] {
                        if let results = response["results"] as? [String:Any] {
                            if let playlists = results["playlists"] as? [String:Any] {
                                let datas = playlists["data"] as? [[String:Any]]
                                var playListInfos = [PlayListInfo]()
                                for play_data in datas! {
                                    let attributes = play_data["attributes"] as? [String:Any]
                                    //let artwork = attributes!["artwork"] as? [String:Any]
                                    let url = attributes!["url"] as? String
                                    let name = attributes!["name"] as? String
                                    let description = attributes!["description"] as? [String:Any]
                                    let shortDescription = description!["short"] as? String
                                    playListInfos.append(PlayListInfo(name: name!, description: shortDescription!, url: url!))
                                }
                                completion( playListInfos )
                            }
                        }
                    }
                    
                    let prdata = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
                    let jsonString = NSString(data: prdata, encoding: String.Encoding.utf8.rawValue)
                    print(jsonString!)
                }
                catch {
                    
                }
            }
        }
        task.resume()
    }
    
    func searchAllLibraryPlaylists(completion : @escaping ([PlayListInfo]) -> ()) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.music.apple.com"
        components.path = "/v1/me/library/playlists"
        
        components.queryItems = [
            URLQueryItem(name: "limit", value: "100")
        ]
        
        guard let url = components.url else {
            return completion([])
        }
        var request = URLRequest(url: url)
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if( data != nil ) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    
                    let prdata = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
                    let jsonString = NSString(data: prdata, encoding: String.Encoding.utf8.rawValue)
                    print("Requesting library playlist...")
                    print(jsonString!)
                    
                    if let response = json as? [String: Any] {
                        if let datas = response["data"] as? [[String:Any]] {
                            var playListInfos = [PlayListInfo]()
                            for play_data in datas {
                                let attributes = play_data["attributes"] as? [String:Any]
                                let url = play_data["href"] as? String
                                let name = attributes!["name"] as? String
                                let description = attributes!["description"] as? [String:Any]
                                var shortDescription = ""
                                if( description != nil ) {
                                    shortDescription = description!["standard"] as! String
                                }
                                playListInfos.append(PlayListInfo(name: name!, description: shortDescription, url: url!))
                            }
                            completion( playListInfos )
                        }
                    }
                    
                }
                catch {
                    
                }
            }
        }
        task.resume()
    }
    
    func searchOnePlaylist(searchTerm: String = "workout", exactMatch: Bool, completion : @escaping ([PlayListInfo]) -> ())  {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.music.apple.com"
        components.path = "/v1/me/library/search"
        
        components.queryItems = [
            URLQueryItem(name: "term", value: searchTerm),
            URLQueryItem(name: "limit", value: "3"),
            URLQueryItem(name: "types", value: "library-playlists"),
        ]
        
        guard let url = components.url else {
            return completion([])
        }
        var request = URLRequest(url: url)
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if( data != nil ) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    
                    let prdata = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
                    let jsonString = NSString(data: prdata, encoding: String.Encoding.utf8.rawValue)
                    
                    print("Searching library playlists with search term ", searchTerm)
                    print(jsonString!)
                    
                    if let response = json as? [String: Any] {
                        if let results = response["results"] as? [String:Any] {
                            if let playlists = results["library-playlists"] as? [String:Any] {
                                let datas = playlists["data"] as? [[String:Any]]
                                var playListInfos = [PlayListInfo]()
                                for play_data in datas! {
                                    let url = play_data["href"] as? String
                                    if let attributes = play_data["attributes"] as? [String:Any] {
                                        //let artwork = attributes!["artwork"] as? [String:Any]
                                        let name = attributes["name"] as? String
                                        if( (exactMatch && name! == searchTerm) || exactMatch == false ) {
                                            let descriptionData = attributes["description"] as? [String:Any]
                                            let description = descriptionData?["standard"] as? String
                                            playListInfos.append(PlayListInfo(name: name!, description: description ?? "", url: url!))
                                        }
                                    }
                                }
                                completion( playListInfos )
                            } else {
                                completion( [] )
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
    
    struct MusicTrackInfo {
        let href : String
        let albumName : String
        let genreName : String
        let artistName : String
        let name : String
        let durationInMs : Int
        enum PlayParamId {
            case catalog(String)
            case purchased(String)
            case library(String)
        }
        let playId : PlayParamId
        var bpm = 0
        
        // Sometime song like "Stronger (What ...)" have multiple names - For some queries we need to choose
        // as the same song may be named "What ... (Stronger)
        func shortName() -> String {
            let index = name.firstIndex(of: "(") ?? name.endIndex
            let beginning = name[..<index]
            return String(beginning).trimmingCharacters(in: .whitespaces)
        }
    }
    
    func getTracksForPlaylist(playList: PlayListInfo, completion: @escaping ([MusicTrackInfo]) -> ()) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.music.apple.com"
        components.path = playList.url + "/tracks"
        
        components.queryItems = [
            URLQueryItem(name: "limit", value: "100")
        ]
        
        guard let url = components.url else {
            return completion([])
        }
        var request = URLRequest(url: url)
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if( data != nil ) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    
                    let prdata = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
                    let jsonString = NSString(data: prdata, encoding: String.Encoding.utf8.rawValue)
                    
                    print("Requesting songs for playlist ", playList.name)
                    print(jsonString!)
                    
                    // The response is of type Library.Song (which is different from Song)
                    if let response = json as? [String: Any] {
                        if let datas = response["data"] as? [[String:Any]] {
                            var tracks = [MusicTrackInfo]()
                            for data in datas {
                                let musicTrack = self.readSongData(data: data)
                                if( musicTrack != nil ) {
                                    tracks.append(musicTrack!)
                                }
                            }
                            completion(tracks)
                        } else {
                            completion( [] )
                        }
                    }
                }
                catch {
                    
                }
            }
        }
        task.resume()
    }
    
    func readSongData(data: [String: Any]) -> MusicTrackInfo? {
        let href = data["href"] as? String
        if let attributes = data["attributes"] as? [String:Any] {
            let genreNames = attributes["genreNames"] as? [String]
            let artistName = attributes["artistName"] as? String
            let name = attributes["name"] as? String
            let albumName = attributes["albumName"] as? String
            let duration = attributes["durationInMillis"] as? Int
            
            let playParams = attributes["playParams"] as? [String:Any]
            let purchasedId = playParams!["purchasedId"] as? String
            let catalogId = playParams!["catalogId"] as? String
            let playId : MusicTrackInfo.PlayParamId
            if( purchasedId != nil ) {
                 playId = MusicTrackInfo.PlayParamId.purchased(purchasedId!)
            } else if( catalogId != nil ) {
                 playId = MusicTrackInfo.PlayParamId.catalog(catalogId!)
            } else {
                let id = playParams!["id"] as? String
                let islibrary = playParams!["isLibrary"] as? Bool
                if( islibrary != nil && islibrary! == true ) {
                    playId = MusicTrackInfo.PlayParamId.library(id!)
               } else {
                    playId = MusicTrackInfo.PlayParamId.catalog(id!)
                }
            }
            let musicTrack = MusicTrackInfo(
                href: href!, albumName: albumName!, genreName: genreNames![0], artistName: artistName!, name: name!, durationInMs: duration!,
                playId: playId
            )
            return musicTrack
        }
        return nil
    }
    
    struct SearchSongInfo {
        var name: String
        var artistName : String
        var albumName : String
        
        func white_space_encoded(string: String) -> String {
            string.replacingOccurrences(of: " ", with: "+")
        }
    }
    func searchSongInLibrary(song: SearchSongInfo, completion: @escaping ([MusicTrackInfo]) -> ()) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.music.apple.com"
        components.path = "/v1/me/library/search"
        
        components.queryItems = [
            URLQueryItem(name: "term", value: song.name.replacingOccurrences(of: " ", with: "+")+"+"+song.artistName.replacingOccurrences(of: " ", with: "+")),
            URLQueryItem(name: "limit", value: "3"),
            URLQueryItem(name: "types", value: "library-songs"),
        ]
        
        guard let url = components.url else {
            return completion([])
        }
        var request = URLRequest(url: url)
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if( data != nil ) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    
                    let prdata = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
                    let jsonString = NSString(data: prdata, encoding: String.Encoding.utf8.rawValue)
                    
                    print("Searching library songs with search term ", song.name, song.artistName)
                    print(jsonString!)
                    
                    if let response = json as? [String: Any] {
                        if let results = response["results"] as? [String:Any] {
                            if let songs = results["library-songs"] as? [String:Any] {
                                let songs_datas = songs["data"] as? [[String:Any]]
                                var musicTracks = [MusicTrackInfo]()
                                for song_data in songs_datas! {
                                    let musicTrack = self.readSongData(data: song_data)
                                    if( musicTrack != nil ) {
                                        if( musicTrack!.artistName == song.artistName && musicTrack!.name == song.name
                                            && musicTrack?.albumName == song.albumName
                                        ) {
                                            musicTracks.append(musicTrack!)
                                        }
                                    }
                                }
                                completion( musicTracks )
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
    
    func seachSongInStore(song: SearchSongInfo, completion: @escaping ([MusicTrackInfo]) -> ()) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.music.apple.com"
        components.path = "/v1/catalog/\(countryCode)/search"
        
        components.queryItems = [
            URLQueryItem(name: "term", value: song.name.replacingOccurrences(of: " ", with: "+")+"+"+song.artistName.replacingOccurrences(of: " ", with: "+")),
            URLQueryItem(name: "limit", value: "3"),
            URLQueryItem(name: "types", value: "songs"),
        ]
        
        guard let url = components.url else {
            return completion([])
        }
        var request = URLRequest(url: url)
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if( data != nil ) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    
                    let prdata = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
                    let jsonString = NSString(data: prdata, encoding: String.Encoding.utf8.rawValue)
                    
                    print("Search songs in store with name ", song.name, song.artistName)
                    print(jsonString!)
                    
                    if let response = json as? [String: Any] {
                        if let results = response["results"] as? [String:Any] {
                            if let songs = results["songs"] as? [String:Any] {
                                let songs_datas = songs["data"] as? [[String:Any]]
                                var musicTracks = [MusicTrackInfo]()
                                for song_data in songs_datas! {
                                    let musicTrack = self.readSongData(data: song_data)
                                    if( musicTrack != nil ) {
                                        if( musicTrack!.artistName == song.artistName && musicTrack!.shortName() == song.name ) {
                                             musicTracks.append(musicTrack!)
                                        }
                                    }
                                }
                                completion( musicTracks )
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
    
    func createPlayList(playListName: String, completion: @escaping (PlayListInfo) -> ()) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.music.apple.com"
        components.path = "/v1/me/library/playlists"
        
        guard let url = components.url else {
            return
        }
        var request = URLRequest(url: url)
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "post"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonString = "{ attributes : { name : \"\(playListName)\" , description : \"Created by workout music\" } }"
        request.httpBody = jsonString.data(using: .utf8)

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error)
                return
            }
            if( data != nil ) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    
                    let prdata = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
                    let jsonString = NSString(data: prdata, encoding: String.Encoding.utf8.rawValue)
                    
                    print("Create playlist with name ", playListName )
                    print(jsonString!)
                    
                    // The response is of type Library.Song (which is different from Song)
                    if let response = json as? [String: Any] {
                        if let datas = response["data"] as? [[String:Any]] {
                            if( datas.count > 0 ) {
                                let play_data = datas[0]
                                
                                let url = play_data["href"] as? String
                                let attributes = play_data["attributes"] as? [String:Any]
                                //let artwork = attributes!["artwork"] as? [String:Any]
                                let name = attributes!["name"] as? String
                                let descriptionData = attributes!["description"] as? [String:Any]
                                let description = descriptionData?["standard"] as? String
                               completion(PlayListInfo(name: name!, description: description ?? "", url: url!))
                            }
                        }
                    }
                } catch {
                    
                }
            }
        }
        task.resume()
    }
    
    func addTrackToPlayList(playList: PlayListInfo, track: MusicTrackInfo, completion: @escaping ()->() ) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.music.apple.com"
        components.path = playList.url + "/tracks"
        
        guard let url = components.url else {
            return
        }
        var request = URLRequest(url: url)
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "post"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let storeId : String?
        switch track.playId {
        case let .catalog(id):
            storeId = id
        case let.purchased(id):
            storeId = id
        default:
            storeId = nil
        }
        if( storeId == nil ) {
            return
        }
        
        let jsonString = "{ data : [ {  id : \"\(storeId!)\" , type : \"songs\" } ] }"
        request.httpBody = jsonString.data(using: .utf8)

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error)
                return
            }
            if( data != nil ) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    
                    let prdata = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
                    let jsonString = NSString(data: prdata, encoding: String.Encoding.utf8.rawValue)
                    
                    print("Add song to playlist ", playList.name, track.name )
                    print(jsonString!)
                    
                    completion()
                }
                catch {
                    completion()
                }
            }
        }
        task.resume()
    }
    
    struct TimeInterval {
        let startTime: Double
        let endTime: Double
    }
    
    func playSongs(tracks: [FetchAppleMusic.MusicTrackInfo]) {
        var storeIds = [String]()
        for track in tracks {
            switch track.playId {
            case let .catalog(id):
                storeIds.append(id)
            case let.purchased(id):
                storeIds.append(id)
            default:
                print("got library id only")
            }
        }
        playSongs(storeIds: storeIds, intervals: nil)
    }
    
    func playSongs(workoutMusic: [StoredWorkoutPlayListSong]) {
        var storeIds = [String]()
        var intervals = [TimeInterval]()
        for music in workoutMusic {
            storeIds.append(music.songId)
            intervals.append(TimeInterval(startTime: music.startTime, endTime: music.endTime))
        }
        playSongs(storeIds: storeIds, intervals: intervals)
    }
    
    func playSongs(wtracks : [WorkoutMusicPlayListTrack], complete: Bool) {
        var storeIds = [String]()
        var intervals = [TimeInterval]()
        for track in wtracks {
            switch track.song.playId {
            case let .catalog(id):
                storeIds.append(id)
            case let.purchased(id):
                storeIds.append(id)
            default:
                print("got library id only")
            }
            intervals.append(TimeInterval(startTime: Double(track.startTime), endTime: Double(track.endTime)))
        }
        if( complete ) {
            playSongs(storeIds: storeIds, intervals: nil)
        } else {
            playSongs(storeIds: storeIds, intervals: intervals)
        }
    }
    
    private func playSongs(storeIds: [String], intervals: [TimeInterval]?) {
        let player = MPMusicPlayerController.applicationQueuePlayer
        let queue  = MPMusicPlayerStoreQueueDescriptor(storeIDs: storeIds)
        if( intervals != nil ) {
            for i in 0 ..< intervals!.count {
               queue.setStartTime(intervals![i].startTime, forItemWithStoreID: storeIds[i])
               queue.setEndTime(intervals![i].endTime, forItemWithStoreID : storeIds[i])
            }
        }

        player.setQueue(with: queue)
        player.prepareToPlay()
        player.play()
    }
    
    func stopPlaying() {
        let player = MPMusicPlayerController.applicationQueuePlayer
        player.stop()
    }
    
    func pausePlaying() {
        let player = MPMusicPlayerController.applicationQueuePlayer
        player.pause()
    }
}

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
