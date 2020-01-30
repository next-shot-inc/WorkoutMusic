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
}

class SortPlayListMasterViewController : UITableViewController {
    
    var userPlayLists = [FetchAppleMusic.PlayListInfo]()
    var spinnerView : UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        globalAppleMusic.setup( completion: { (error) -> () in
            if( error.isEmpty ) {
               self.insertNewObject(self)
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
    
    func showSpinner(onView : UIView) {
        spinnerView = UIView.init(frame: onView.bounds)
        spinnerView!.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .large)
        ai.startAnimating()
        ai.center = spinnerView!.center
        
        DispatchQueue.main.async {
            self.spinnerView!.addSubview(ai)
            onView.addSubview(self.spinnerView!)
        }
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            self.spinnerView?.removeFromSuperview()
            self.spinnerView = nil
        }
    }

    @objc
    func insertNewObject(_ sender: Any) {
         DispatchQueue.main.async {
            self.showSpinner(onView: self.view)
        }
        
        globalAppleMusic.searchAllLibraryPlaylists( completion: { (playLists) in
            self.userPlayLists = playLists
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.removeSpinner()
            }
        })
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = userPlayLists[indexPath.row]
                let controller = segue.destination as! SortPlayListDetailViewController
                controller.appleMusic = globalAppleMusic
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
        return 1
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
    }
    
}
