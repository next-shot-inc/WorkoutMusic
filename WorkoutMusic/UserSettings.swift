//
//  UserSettings.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/26/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit

class SearchSongGenreCell : UICollectionViewCell {
    weak var controller: SearchSongGenresCollectionViewController?
    
    @IBAction func toggleButtonPushed(_ sender: Any) {
        toggleButton.isSelected = !toggleButton.isSelected
        controller?.set(genre: genre, selected: toggleButton.isSelected)
    }
    @IBOutlet weak var toggleButton: UIButton!
    var genre = String()
}

class SearchSongGenresCollectionViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var genres = ["electronic", "rock", "heavy metal", "pop", "jazz", "country", "hip hop", "rap", "classical", "punk", "funk", "folk", "blues", "latin"]
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return genres.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GenreCollectionViewCell", for: indexPath) as! SearchSongGenreCell
        
        cell.genre = genres[indexPath.row]
        cell.toggleButton.setTitle(genres[indexPath.row].capitalized, for: .normal)
        cell.toggleButton.setTitle(genres[indexPath.row].capitalized, for: .selected)
        if let state = genreSettings.genresPreference[genres[indexPath.row]] {
            cell.toggleButton.isSelected = state
        }
        cell.controller = self
        return cell
    }
    
    func set(genre: String, selected: Bool) {
        genreSettings.genresPreference[genre] = selected
        genreSettings.save()
    }
    
    lazy var cstCellSize : CGSize = {
        // Use longest label to size all, so that all the cells are properly aligned.
        let itemSize = "Heavy Metal".size(withAttributes: [
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)
        ])
        return CGSize(width: itemSize.width + 46, height: max(itemSize.height, 28))
    }()
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cstCellSize
    }
}

class GenreSettings {
    var genresPreference : [String:Bool] = [
        "electronic" : true, "rock" : true, "heavy metal" : true,
        "pop" : true, "jazz": true , "country" : true, "hip hop" : true,
        "rap" : true, "classical": true , "punk" : true , "funk" : true,
        "folk" : true, "blues" : true, "latin": true
    ]
    init() {
        let defaults = UserDefaults.standard
        let defaultGenres = defaults.dictionary(forKey: "preferredGenres")
        if( defaultGenres != nil ) {
            genresPreference = defaultGenres as! [String:Bool]
        }
    }
    func save() {
        let defaults = UserDefaults.standard
        defaults.set(genresPreference, forKey: "preferredGenres")
    }
    
    private var appleMusicGenresToGenres : [String: [String]] = [
        "Electronic" : ["electronic"], "Rock" : ["rock"], "Metal" : ["heavy metal"],
        "Hard Rock " : [" heavy metal" ], 
        "Pop" : ["pop"], "Jazz": ["jazz"] , "Country Rock" : ["country"], "Hip hop" : ["hip hop"],
        "Alternative" : ["pop", "rock"],
        "Rap" : [ "rap"], "Classical": ["classical"] , "Punk" : ["punk" ], "Funk" : ["funk"],
        "Folk" : ["folk"], "Blues" : ["blues"], "Latin" : ["latin"]
    ]
    
    // Return true if the genres is to be included in the list
    func genresPreference(appleGenreName: String) -> Bool {
        if let simpleGenres = appleMusicGenresToGenres[appleGenreName] {
            var genrePrefUnion = false
            for genre in simpleGenres {
                if let pref = genresPreference[genre]  {
                    genrePrefUnion = genrePrefUnion || pref
                }
            }
            return genrePrefUnion
        }
        return true
    }
}

let genreSettings = GenreSettings()

class UserSettingUIController : UIViewController {
     @IBOutlet weak var genreCollectionView: UICollectionView!
    
     var genreCollectionViewController = SearchSongGenresCollectionViewController()
    
     override func viewDidLoad() {
        genreCollectionView.delegate = genreCollectionViewController
        genreCollectionView.dataSource = genreCollectionViewController
        
        genreCollectionViewController.genres.sort()
    }
}
