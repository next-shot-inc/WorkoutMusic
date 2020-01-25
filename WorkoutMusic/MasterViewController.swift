//
//  MasterViewController.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/18/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import UIKit
import CoreData

var appleMusic = FetchAppleMusic()

class MasterViewPlayListCell : UITableViewCell {
    
    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var comment: UILabel!
}

class MasterViewController: UITableViewController {

    var userPlayLists = [FetchAppleMusic.PlayListInfo]()
    var spinnerView : UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appleMusic.setup( completion: { () -> () in
            self.insertNewObject(self)
        })
        
        // Do any additional setup after loading the view.
        // Add the "Edit" button on the navigationBar (left Button)
        //navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.title = "Build From User's playlist"

        // Add the "+" button on the navigationbar (right Button)
        //let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        //navigationItem.rightBarButtonItem = addButton
        //navigationItem.leftItemsSupplementBackButton = true
        
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
        
        appleMusic.searchAllLibraryPlaylists( completion: { (playLists) in
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
                let controller = segue.destination as! DetailViewTableViewControler
                controller.appleMusic = appleMusic
                controller.detailItem = object
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

