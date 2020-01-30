//
//  MasterViewController.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/18/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import UIKit
import CoreData

class MasterViewPlayListCell : UITableViewCell {
    
    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var comment: UILabel!
}

class MasterViewController: UITableViewController {

    var userPlayLists = [FetchAppleMusic.PlayListInfo]()
    var appleMusic : FetchAppleMusic? {
        didSet {
            if( viewIfLoaded != nil ) {
                self.getUserPlayList(self)
            }
        }
    
    }
    var spinnerCtrler = ShowSpinnerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // Add the "Edit" button on the navigationBar (left Button)
        //navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.title = "Build From User's playlist"

        // Add the "+" button on the navigationbar (right Button)
        //let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        //navigationItem.rightBarButtonItem = addButton
        //navigationItem.leftItemsSupplementBackButton = true
        
        if( appleMusic != nil ) {
            self.getUserPlayList(self)
        }
    }

    @objc
    func getUserPlayList(_ sender: Any) {
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
                let controller = segue.destination as! DetailViewTableViewControler
                controller.appleMusic = appleMusic
                controller.detailItem = object
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
                noDataLabel.text = "Apple Music service not available. Cannot construct a workout playlist."
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "MasterViewPlayListCell", for: indexPath)
        let event = userPlayLists[indexPath.row]
        configureCell(cell, withPlayList: event)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    func configureCell(_ cell: UITableViewCell, withPlayList playlist: FetchAppleMusic.PlayListInfo) {
        let ecell = cell as? MasterViewPlayListCell
        ecell!.name!.text = playlist.name
        ecell!.comment!.text = playlist.description
    }
}

