//
//  WorkoutIntensityView.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/23/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class WorkoutIntensityView : UIView {
    @IBInspectable public var barColor: UIColor = UIColor(red: 0.0, green: 0.45, blue: 0.94, alpha: 1.0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable public var barLineColor: UIColor = UIColor(white: 0.9, alpha: 1.0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable  public var labelFont : UIFont = UIFont.systemFont(ofSize: 10) {
        didSet {
            timeLabel?.font = labelFont
        }
    }
    
    var workoutPlayList : StoredWorkoutMusicPlayList?
    var timeLabel : UILabel?
    var timeAxisHeight : CGFloat = 0
    var timeAxisLabelViews = [UIView]()
    
    var cursorLocationInS : Double? {
        didSet {
            setupTimeLabel()
            setNeedsDisplay()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupTimeLabel() {
        if( timeLabel == nil ) {
           timeLabel    = UILabel()
           timeLabel?.font = labelFont
           timeLabel?.frame = frame
           addSubview(timeLabel!)
        }
        
        let fmt = DateComponentsFormatter()
        fmt.zeroFormattingBehavior = .pad
        fmt.allowedUnits = [.minute, .second]
        let timestring = fmt.string(from: cursorLocationInS!)
        timeLabel!.text = timestring!
        
        guard  let playList = workoutPlayList else {
            return
        }
        let margin : CGFloat = 2
        let duration = playList.totalDuration
        let xPerSeconds = (frame.width - 2*margin)/CGFloat(duration)
        let curX = margin + CGFloat(cursorLocationInS!) * xPerSeconds
        timeLabel?.frame = CGRect(x: curX + 2*margin, y: margin, width: 30, height: bounds.height/3)
        timeLabel?.setNeedsDisplay()
    }
    
    func setupTimeAxisLabels() {
        // Remove previous axis labels
        for axisLabel in timeAxisLabelViews {
            axisLabel.removeFromSuperview()
        }
        timeAxisLabelViews.removeAll()
        
        guard  let playList = workoutPlayList else {
            return
        }
        let margin : CGFloat = 2
        let duration = playList.totalDuration
        var labelStep = 60
        var nbLabels = Int(duration/Double(labelStep))
        let xPerSeconds = (frame.width - 2*margin)/CGFloat(duration)
        let labelWidth : CGFloat = 30
        let nbMaxLabels = Int(frame.width/(labelWidth + margin))
        
        if( nbLabels > nbMaxLabels ) {
            // Instead of every mins, try a label every 5 mns
            labelStep = 60*5
            nbLabels = Int(duration/Double(labelStep))
            if( nbLabels > nbMaxLabels ) {
                // try a label every 10mns
                labelStep = 60*10
                nbLabels = Int(duration/Double(labelStep))
            }
        }
        
        let fmt = DateComponentsFormatter()
        fmt.unitsStyle = .abbreviated
        fmt.allowedUnits = [.minute]
               
        if( nbLabels <= nbMaxLabels ) {
            for label in 1 ... nbLabels {
                let curX = margin + CGFloat(labelStep*label)*xPerSeconds
                let timestring = fmt.string(from: Double(labelStep*label))
                
                let xLabel  = UILabel()
                xLabel.font = labelFont
                xLabel.text = timestring
                xLabel.frame = CGRect(x: curX - labelWidth/2, y: frame.height - margin, width: labelWidth, height: 20)
                xLabel.textAlignment = .center
                addSubview(xLabel)
                timeAxisLabelViews.append(xLabel)
            }
            timeAxisHeight = 12
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard  let playList = workoutPlayList else {
            return
        }
        let margin : CGFloat = 2
        let minHeight = frame.height/20
        let height = frame.height - 2*margin - minHeight - timeAxisHeight
        let bpms = playList.tracks.map { (track) -> Int in
            return track.bpm
        }
        let bpm_min = bpms.min()! - 10
        let bpm_max = bpms.max()!
        let duration = playList.totalDuration
        let xPerSeconds = (frame.width - 2*margin)/CGFloat(duration)
        let yPerBPM = height/CGFloat(bpm_max - bpm_min)
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(barColor.cgColor)
            context.setStrokeColor(barLineColor.cgColor )
            var curX = margin
            for track in playList.tracks {
                let w = CGFloat(track.durationTime)*xPerSeconds
                let h = minHeight + yPerBPM*CGFloat(track.bpm - bpm_min)
                let rect = CGRect(x: curX, y: frame.height - margin - h - timeAxisHeight, width: w, height: h)
                context.fill(rect)
                context.stroke(rect)
                curX = curX + w
            }
            
            if( cursorLocationInS != nil ) {
                context.setFillColor(barLineColor.cgColor )
                let curX = margin + CGFloat(cursorLocationInS!) * xPerSeconds
                let rect = CGRect(x: curX-margin/2, y: margin, width: margin, height: frame.height-2*margin)
                context.fill(rect)
                context.stroke(rect)
            }
            
            for xlabel in timeAxisLabelViews {
                context.setStrokeColor(UIColor.black.cgColor)
                let xframe = xlabel.frame
                let bottom_stick = CGPoint(x: xframe.origin.x + xframe.width/2, y: frame.height - margin - timeAxisHeight)
                let top_stick = CGPoint(x: bottom_stick.x, y: bottom_stick.y + 5)
                context.move(to: bottom_stick)
                context.addLine(to: top_stick)
                context.drawPath(using: .stroke)
            }
        }
    }
}
