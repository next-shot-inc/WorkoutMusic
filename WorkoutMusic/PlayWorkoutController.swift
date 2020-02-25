//
//  PlayWorkoutController.swift
//  WorkoutMusic
//
//  Created by next-shot on 2/14/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class PlayWorkoutUIController : UIViewController, AVAudioPlayerDelegate {
    var appleMusic: FetchAppleMusic? {
        didSet {
            // Attach the observer to the player controller used to play the songs.
            // Cannot do that in viewDidLoad as appleMusic is still nil there.
            appleMusic?.playerController.beginGeneratingPlaybackNotifications()
            
            NotificationCenter.default.addObserver(
                self, selector: #selector(playbackStateChanged), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: appleMusic?.playerController)
            
            NotificationCenter.default.addObserver(
                self, selector: #selector(refreshView), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: appleMusic?.playerController)
        }
    }
    
    @IBOutlet weak var currentMusicArtworkImageView: UIImageView!
    @IBOutlet weak var workoutPlayButton: UIButton!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var songCountDown: UILabel!
    @IBOutlet weak var nowPlayingLabel: UILabel!
    @IBOutlet weak var workoutIntensityView: WorkoutIntensityView!
    @IBOutlet weak var stickFigureView: RunningStickFigureView!
    @IBOutlet weak var animatedPlayingImageView: UIImageView!
    @IBOutlet weak var nextSongLabel: UILabel!
    
    var selectedWorkout : StoredWorkoutMusicPlayList?
    
    enum PlayingState { case stopped, paused, running }
    var playingState : PlayingState = .stopped
    var timer : Timer?
    
    class PlayAlongAudioRecording {
        var songRemainingTimeInS : Double
        enum AudioType {
            case systemSound(Int)
            case soundFile(name: String, type: String)
        }
        var audio : AudioType
        var audioPlayer: AVAudioPlayer?
        
        init(remainingTime: Double, audio: String, fileType: String) {
            self.songRemainingTimeInS = remainingTime
            self.audio = AudioType.soundFile(name: audio, type: fileType)
        }
        init(remainingTime: Double, systemSound: Int) {
            self.songRemainingTimeInS = remainingTime
            self.audio = AudioType.systemSound(systemSound)
        }
        func playAudio(delegate: AVAudioPlayerDelegate) {
            switch audio {
            case let .soundFile(audio, fileType) :
                playSoundFile(audioResourceName: audio, fileType: fileType, delegate: delegate)
            case let .systemSound(id):
                playSystemSound(systemSound: id)
            }
        }
        
    func playSystemSound(systemSound: Int) {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSession.Category.ambient, options: [.duckOthers])
                try audioSession.setActive(true)
                AudioServicesPlayAlertSound(SystemSoundID(systemSound))
                try audioSession.setActive(false)
            } catch {
                    
            }
        }
        
    func playSoundFile(audioResourceName: String, fileType: String, delegate: AVAudioPlayerDelegate) {
            guard let asset = NSDataAsset(name: audioResourceName) else {
                return
            }
            do {
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(AVAudioSession.Category.ambient, options: [.duckOthers])
                    try audioSession.setActive(true)
                    do {
                        audioPlayer = try AVAudioPlayer(data:asset.data, fileTypeHint: fileType)
                        audioPlayer!.delegate = delegate
                        audioPlayer!.volume = 1
                        if( !audioPlayer!.prepareToPlay() ) {
                            try audioSession.setActive(false)
                        } else {
                            if( !audioPlayer!.play() ) {
                               try audioSession.setActive(false)
                            }
                        }
                    } catch {
                        print("Could not load the file")
                    }
                } catch {
                    
                }
            }
        }
    }
    var audioRecordings = [PlayAlongAudioRecording]()
    
    struct StickFigureState {
        var duration = 0
        var bpm = 0
        mutating func setupAnimation(stickFigureView: RunningStickFigureView, bpm: Int, duration: Int) {
            self.bpm = bpm
            self.duration = duration
            stickFigureView.setup(animate: true, bpm: bpm, duration: duration)
        }
        mutating func resumeAnimation(stickFigureView: RunningStickFigureView, duration: Int) {
            self.duration = duration
            stickFigureView.setup(animate: true, bpm: bpm, duration: duration)
        }
    }
    var stickFigureState = StickFigureState()
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        setSelectedWorkout()
        
        animatedPlayingImageView.animationImages = [
            UIImage(named: "music-playing-1")!,
            UIImage(named: "music-playing-2")!,
            UIImage(named: "music-playing-3")!,
            UIImage(named: "music-playing-4")!
        ]
        animatedPlayingImageView.animationDuration = 1
        
        audioRecordings.append(
            PlayAlongAudioRecording(remainingTime: 4, audio: "countdown-321", fileType: "wav")
            //PlayAlongAudioRecording(remainingTime: 5, systemSound: 1106)
        )

    }
    
    deinit {
        appleMusic?.playerController.endGeneratingPlaybackNotifications()
        
        NotificationCenter.default.removeObserver(self, name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: appleMusic?.playerController)
        NotificationCenter.default.removeObserver(self, name: .MPMusicPlayerControllerPlaybackStateDidChange, object: appleMusic?.playerController)
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        timer?.invalidate()
        timer = nil
    }
    
    /// Re-initialize UI when selecting a workout
    func setSelectedWorkout() {
        if( selectedWorkout == nil ) {
            return
        }
        
        workoutIntensityView.workoutPlayList = selectedWorkout
        workoutIntensityView.setupTimeAxisLabels()
        workoutIntensityView.cursorLocationInS = 0
        workoutIntensityView.setNeedsDisplay()
        currentMusicArtworkImageView.image = nil
        nowPlayingLabel.text = nil
        workoutPlayButton.setTitle("Start", for: .normal)
        animatedPlayingImageView.isHidden = true
        stickFigureView.isHidden = true
        
        let leftTime = self.selectedWorkout!.totalDuration
        showRemainingTime(leftTime: leftTime)
        
        let wsong = self.selectedWorkout!.tracks[0]
        nextSongLabel.text = "Playing next: \(wsong.songName)"
        
        navigationItem.title = "\(selectedWorkout!.name) Workout"
    }
    
    func showRemainingTime(leftTime: Double) {
        let fmt = DateComponentsFormatter()
        fmt.zeroFormattingBehavior = .pad
        fmt.allowedUnits = [.minute, .second]
        let timestring = fmt.string(from: leftTime)
        self.countdownLabel.text = timestring
        
        let songLeftTime = selectedWorkout!.endTimeToCurSong(elapsedTime: selectedWorkout!.totalDuration - leftTime)
        let songtimestring = fmt.string(from: songLeftTime)
        self.songCountDown.text = songtimestring
    }
    
    func getSongRemainingDuration() -> Double {
        if( selectedWorkout != nil && workoutIntensityView.cursorLocationInS != nil ) {
           return self.selectedWorkout!.totalDuration - self.workoutIntensityView.cursorLocationInS!
        }
        return 0
    }
    
    // Starts playback of the next item in the queue
    @IBAction func skipToNextSong(_ sender: Any) {
        if( playingState == .running ) {
            appleMusic?.skipToNextSong()
        }
    }
    
    /// Execute the playlist linked to the workout
    @IBAction func executeWorkout(_ sender: Any) {
        if( playingState == .stopped ) {
            if( selectedWorkout != nil ) {
                appleMusic?.playSongs(workoutMusic: selectedWorkout!.tracks)
                playingState = .running
                workoutPlayButton.setTitle("Pause", for: .normal)
                animatedPlayingImageView.isHidden = false
                animatedPlayingImageView.startAnimating()
                stickFigureView.isHidden = false
            }
        } else if ( playingState == .paused ) {
            appleMusic?.resumePlaying()
            workoutPlayButton.setTitle("Pause", for: .normal)
            playingState = .running
            animatedPlayingImageView.startAnimating()
            
            self.stickFigureState.resumeAnimation(stickFigureView: self.stickFigureView, duration: Int(self.getSongRemainingDuration()))
        } else {
            workoutPlayButton.setTitle("Resume", for: .normal)
            appleMusic?.pausePlaying()
            playingState = .paused
            self.stickFigureView.stopAnimation()
            animatedPlayingImageView.stopAnimating()
        }
    }
    
    /// MARK: Handle background/foreground operations
    
    /// Stop timers
    @objc func didEnterBackground() {
        if( playingState == .running ) {
            timer?.invalidate()
            timer = nil
        }
    }
    
    /// Update UI to reflect current song, time already played, etc.
    @objc func willEnterForeground() {
        if( playingState == .running ) {
            
            let currentItem = appleMusic!.playerController.nowPlayingItem
            if( currentItem != nil ) {
                 // Verify the validity of the index
                 let songIndex = selectedWorkout!.tracks.firstIndex(where: { (wsong) -> Bool in
                     wsong.songId == currentItem!.playbackStoreID
                 })
                if( songIndex != nil ) {
                    // Update UI
                    DispatchQueue.main.async {
                        
                        let wsong = self.selectedWorkout!.tracks[songIndex!]
                        
                        self.nowPlayingLabel.text = "Now playing: \(wsong.songName)"
                        if( songIndex! < self.selectedWorkout!.tracks.count-1 ) {
                            self.nextSongLabel.text = "Playing next: \(self.selectedWorkout!.tracks[songIndex!+1].songName)"
                        }
                        
                        // Handle the current play time
                        let elapseTimeOnCurrentItem = self.appleMusic!.playerController.currentPlaybackTime - wsong.startTime
                        
                        // Put the cursor at the right time
                        self.workoutIntensityView.cursorLocationInS =
                            self.selectedWorkout!.startTime(songIndex: songIndex!) + elapseTimeOnCurrentItem
                        
                        // Starts the timer
                        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
                        
                        // Grab current Item's artwork
                        let image : UIImage? = currentItem?.artwork?.image(at: CGSize(width: 80, height: 80))
                        self.currentMusicArtworkImageView.image = image
                        
                        // Handle the animation
                        self.stickFigureState.setupAnimation(stickFigureView: self.stickFigureView, bpm: wsong.bpm, duration: Int(wsong.durationTime - elapseTimeOnCurrentItem))
                    }
                }
            }
        }
    }
    
    /// MARK: Handle AppleMusic Player callbacks
    
    /// Monitor the MusicPlayer current playing item. Check that the player is playing one
    /// item of the workout playlist. If it is, change the Now playing label,
    /// and set the cursor location in the workoutIntensityView. This is called when the playing song has changed.
    @objc func refreshView() {
        if( selectedWorkout == nil ) {
            return
        }
        let itemIndex = appleMusic!.playerController.indexOfNowPlayingItem
        let item = appleMusic!.playerController.nowPlayingItem
        if( itemIndex >= 0 && itemIndex < selectedWorkout!.tracks.count ) {
            var songIndex : Int?
            if( item != nil ) {
                // Verify the validity of the index
                let firstIndex = selectedWorkout!.tracks.firstIndex(where: { (wsong) -> Bool in
                    wsong.songId == item!.playbackStoreID
                })
                if( firstIndex != nil && firstIndex! == itemIndex ) {
                    songIndex = itemIndex
                }
            } else {
                songIndex = itemIndex
            }
            if( songIndex != nil ) {
                let wsong = self.selectedWorkout!.tracks[songIndex!]
                
                DispatchQueue.main.async {
                    self.nowPlayingLabel.text = "Now playing: \(wsong.songName)"
                    
                    if( songIndex! == 0 ) {
                        if( self.timer == nil ) {
                           self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
                        }
                    } else {
                        // Make sure to set at the right time (when we pause/skip)
                        self.workoutIntensityView.cursorLocationInS = self.selectedWorkout!.startTime(songIndex: songIndex!)
                    }
                    //Grab current Item's artwork
                    let image : UIImage? = item?.artwork?.image(at: CGSize(width: 80, height: 80))
                    self.currentMusicArtworkImageView.image = image
                    
                    // Handle animation
                    self.stickFigureView.stopAnimation()
                    self.stickFigureState.setupAnimation(stickFigureView: self.stickFigureView, bpm: wsong.bpm, duration: Int(wsong.durationTime))
                    
                    // Set next item to be played
                    if( songIndex! < self.selectedWorkout!.tracks.count-1 ) {
                        self.nextSongLabel.text = "Playing next: \(self.selectedWorkout!.tracks[songIndex!+1].songName)"
                    } else {
                        self.nextSongLabel.text = ""
                    }
                }
            }
        }
    }
    
    /// Monitor the playback status to know when to stop the timer.
    @objc func playbackStateChanged() {
        if( selectedWorkout == nil ) {
            return
        }
        
        let state = MPMusicPlayerController.applicationMusicPlayer.playbackState
        if( state == .stopped ) {
            DispatchQueue.main.async {
                self.nowPlayingLabel.text = "Stopped playing"
                self.timer?.invalidate()
                self.timer = nil
                self.stickFigureView.stopAnimation()
                self.animatedPlayingImageView.stopAnimating()
            }
        } else if( state == .paused ) {
            self.timer?.invalidate()
            self.timer = nil
            self.stickFigureView.stopAnimation()
            self.animatedPlayingImageView.stopAnimating()
            
        } else if( state == .playing ) {
            if( timer == nil ) {
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
            }
            self.stickFigureState.resumeAnimation(stickFigureView: self.stickFigureView, duration: Int(self.getSongRemainingDuration()))
            self.animatedPlayingImageView.startAnimating()
        }
    }
    
    /// MARK: Timer callback
    
    /// Update the timer cursor in the workoutIntensityView
    @objc func updateTime() {
        DispatchQueue.main.async {
            if( self.workoutIntensityView.cursorLocationInS == nil ) {
               self.workoutIntensityView.cursorLocationInS = self.timer!.timeInterval
            } else if( self.timer != nil ) {
                self.workoutIntensityView.cursorLocationInS = self.workoutIntensityView.cursorLocationInS! + self.timer!.timeInterval
            }
            if( self.selectedWorkout != nil ) {
                let totalLeftTime = self.selectedWorkout!.totalDuration - self.workoutIntensityView.cursorLocationInS!
                self.showRemainingTime(leftTime: totalLeftTime)
                
                let songLeftTime = self.selectedWorkout!.endTimeToCurSong(elapsedTime: self.workoutIntensityView.cursorLocationInS!)
                for audioRecording in self.audioRecordings {
                    if( abs(songLeftTime-audioRecording.songRemainingTimeInS) < 1 ) {
                        audioRecording.playAudio(delegate: self)
                    }
                }
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            
        }
    }
}
