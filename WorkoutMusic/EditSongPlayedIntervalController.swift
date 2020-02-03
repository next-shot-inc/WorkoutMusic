//
//  EditSongPlayedIntervalController.swift
//  WorkoutMusic
//
//  Created by next-shot on 2/3/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit

class EditSongPlayedIntervalController : UIViewController {
    var wtrack: WorkoutMusicPlayListTrack?
    var appleMusic : FetchAppleMusic?
    
    @IBOutlet weak var timeRangeSlider: RangeSlider!
    
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!
    
    var playing = false
    enum LastEdited { case none, upperValue, lowerValue }
    var lastEdited : LastEdited = .none
    
    @IBAction func timeRangeSliderValueChanged(_ sender: Any) {
        wtrack?.startTime = Int(timeRangeSlider.lowerValue)
        wtrack?.endTime = Int(timeRangeSlider.upperValue)
        if( timeRangeSlider.lowerValueBeingEdited ) {
            lastEdited = .lowerValue
        } else {
            lastEdited = .upperValue
        }
        
        updateLabels()
    }
    
    func updateLabels() {
        let fmt = DateComponentsFormatter()
        fmt.allowedUnits = [.minute, .second]
        fmt.zeroFormattingBehavior = .pad
        let timestringUpper = fmt.string(from: TimeInterval(Double(wtrack!.startTime)))
        startTimeLabel.text = timestringUpper
        
        let timestringLower = fmt.string(from: TimeInterval(Double(wtrack!.endTime)))
        endTimeLabel.text = timestringLower
                      
        let duration = fmt.string(from: Double(wtrack!.durationTime))
        durationTimeLabel.text = duration!
    }
    
    override func viewDidLoad() {
        if( wtrack != nil ) {
            timeRangeSlider.maximumValue = Double(wtrack!.durationTime)
            timeRangeSlider.minimumValue = 0
            timeRangeSlider.lowerValue = Double(wtrack!.startTime)
            timeRangeSlider.upperValue = Double(wtrack!.endTime)
            updateLabels()
            
            title = wtrack!.song.name + " by " + wtrack!.song.artistName
        }
    }
    
    @IBAction func play(_ sender: Any) {
        if( playing ) {
            appleMusic?.stopPlaying()
            playing = false
            (sender as! UIButton).setTitle("Play", for: .normal)
        } else {
            var wtracks = [WorkoutMusicPlayListTrack]()
            if( lastEdited == .lowerValue ) {
                 // Construct a song interval starting from the lower value
                 wtracks.append(wtrack!)
            } else {
                // Construct a song interval starting from the upper Value
                let pw = WorkoutMusicPlayListTrack(song: wtrack!.song)
                pw.startTime = wtrack!.endTime
                pw.endTime = wtrack!.song.durationInMs*1000
                wtracks.append(pw)
            }
            appleMusic?.playSongs(wtracks: wtracks, complete: false)
            (sender as! UIButton).setTitle("Stop", for: .normal)
            playing = true
        }
    }
    
    @IBAction func lowerStartAction(_ sender: Any) {
        timeRangeSlider.lowerValue -= 5
        wtrack?.startTime = Int(timeRangeSlider.lowerValue)
        updateLabels()
    }
    
    @IBAction func increaseEndAction(_ sender: Any) {
        timeRangeSlider.upperValue += 5
        wtrack?.endTime = Int(timeRangeSlider.upperValue)
        updateLabels()
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindFromEditSongPlayedInterval", sender: self)
    }
}
