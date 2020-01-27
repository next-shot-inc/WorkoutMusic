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
        controller?.set(genre: toggleButton.title(for: .normal) ?? "", selected: toggleButton.isSelected)
    }
    @IBOutlet weak var toggleButton: UIButton!
}

class SearchSongGenresCollectionViewController : UICollectionViewController {
    var genres = ["electronic", "rock", "heavy metal", "pop", "jazz", "country", "hip hop", "rap", "classical", "punk", "funk", "folk", "blues", "latin"]
    
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
    
    var genresToAppleMusicGenres : [String:String] = [
        "electronic" : "Electronic", "rock" : "Rock", "heavy metal" : "Metal",
        "pop" : "Pop", "jazz": "Jazz" , "country" : "Country Rock", "hip hop" : "Hip hop",
        "rap" : "Rap", "classical": "Classical" , "punk" : "Punk" , "funk" : "Funk",
        "folk" : "Folk", "blues" : "Blues", "latin" : "Latin"
    ]
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
