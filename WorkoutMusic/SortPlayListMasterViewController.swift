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
    }
    
}
