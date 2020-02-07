//
//  UIWorkoutMusicTabBarController.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/27/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit

/// Master view controller which is used to setup the music service
/// and distribute the music service to all its sub-controllers

class UIWorkoutMusicTabBarController : UITabBarController {
    var appleMusic = FetchAppleMusic()
    var spinnerCtrler = ShowSpinnerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show a spinner while waiting for appleMusic setup.
        spinnerCtrler.showSpinner(onView: view, withLabel: "Connecting to Apple Music ...")
        
        appleMusic.setup( completion: { (error) -> () in
            self.spinnerCtrler.removeSpinner()
            
            if( error.isEmpty ) {
                // Distribute the music service to all its sub-controllers
                for viewController in self.viewControllers! {
                    if let navigationCtrler = viewController as? UINavigationController {
                        // When the controller is a navigation controller
                        // get the navigation top view controller to find the specific controller
                        let subController = navigationCtrler.topViewController
                        if let buildCtrler = subController as? MasterViewController {
                             buildCtrler.appleMusic = self.appleMusic
                        } else if let sortCtrler = subController as? SortPlayListMasterViewController {
                            sortCtrler.appleMusic = self.appleMusic
                        } else if let playCtrler = subController as? PlayWorkoutPlayController {
                            playCtrler.appleMusic = self.appleMusic
                        }
                    
                    } else if let seachCtrler = viewController as? SearchSongViewController {
                        seachCtrler.appleMusic = self.appleMusic
                    
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                    
                    let submitAction = UIAlertAction(title: "OK", style: .default)
                    ac.addAction(submitAction)
                    
                    self.present(ac, animated: true)
                }
            }
        })
    }
    
    
}
