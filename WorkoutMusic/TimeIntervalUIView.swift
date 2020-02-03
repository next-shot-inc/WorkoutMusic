//
//  TimeIntervalUIView.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/20/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit

class TimeIntervalViewTrackLayer: CALayer {
    weak var rangeSlider: TimeIntervalUIView?
    
    override func draw(in ctx: CGContext) {
        guard let slider = rangeSlider else {
            return
        }
        
        // Clip
        let cornerRadius = bounds.height * slider.curvaceousness / 2.0
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        ctx.addPath(path.cgPath)
        
        // Fill the track
        ctx.setFillColor(slider.trackTintColor.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        
        // Fill the highlighted range
        ctx.setFillColor(slider.trackHighlightTintColor.cgColor)
        let lowerValuePosition = CGFloat(slider.positionForValue(slider.lowerValue))
        let upperValuePosition = CGFloat(slider.positionForValue(slider.upperValue))
        let rect = CGRect(x: lowerValuePosition, y: 0.0, width: upperValuePosition - lowerValuePosition, height: bounds.height)
        ctx.fill(rect)
    }
}

@IBDesignable
class TimeIntervalUIView : UIView {
    @IBInspectable public var minimumValue: Double = 0.0 {
        willSet(newValue) {
            assert(newValue < maximumValue, "RangeSlider: minimumValue should be lower than maximumValue")
        }
        didSet {
            updateLayerFrames()
        }
    }
    
    @IBInspectable public var maximumValue: Double = 1.0 {
        willSet(newValue) {
            assert(newValue > minimumValue, "RangeSlider: maximumValue should be greater than minimumValue")
        }
        didSet {
            updateLayerFrames()
        }
    }
    
    @IBInspectable public var lowerValue: Double = 0.2 {
        didSet {
            if lowerValue < minimumValue {
                lowerValue = minimumValue
            }
            updateLayerFrames()
        }
    }
    
    @IBInspectable public var upperValue: Double = 0.8 {
        didSet {
            if upperValue > maximumValue {
                upperValue = maximumValue
            }
            updateLayerFrames()
        }
    }
    
    @IBInspectable public var trackTintColor: UIColor = UIColor(white: 0.9, alpha: 1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var trackHighlightTintColor: UIColor = UIColor(red: 0.0, green: 0.45, blue: 0.94, alpha: 1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var curvaceousness: CGFloat = 1.0 {
        didSet {
            if curvaceousness < 0.0 {
                curvaceousness = 0.0
            }
            
            if curvaceousness > 1.0 {
                curvaceousness = 1.0
            }
            
            trackLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable  public var labelFont : UIFont = UIFont.systemFont(ofSize: 10) {
        didSet {
            lowerTextView?.font = labelFont
            upperTextView?.font = labelFont
        }
    }
    
    var lowerTextView : UILabel?
    var upperTextView : UILabel?
    
    var lowerTextValue : String? {
        didSet {
            if( lowerTextView == nil ) {
                createLowerTextView()
            }
            lowerTextView?.text = lowerTextValue
            lowerTextView?.setNeedsDisplay()
        }
    }
    var upperTextValue : String? {
        didSet {
            if( upperTextView == nil ) {
                createUpperTextView()
            }
            upperTextView?.text = upperTextValue
            upperTextView?.setNeedsDisplay()
        }
    }
    
    override public var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initializeLayers()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeLayers()
    }
    
    override public func layoutSublayers(of: CALayer) {
        super.layoutSublayers(of:layer)
        updateLayerFrames()
    }
    
    fileprivate func initializeLayers() {
        layer.backgroundColor = UIColor.clear.cgColor
        
        trackLayer.rangeSlider = self
        trackLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(trackLayer)
    }
    
    func createLowerTextView() {
        lowerTextView = UILabel()
        lowerTextView?.font = labelFont
        lowerTextView?.frame = frame
        addSubview(lowerTextView!)
    }
    
    func createUpperTextView() {
        upperTextView = UILabel()
        upperTextView?.font = labelFont
        upperTextView?.frame = frame
        addSubview(upperTextView!)
    }
    
    func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        trackLayer.frame = bounds.insetBy(dx: 0.0, dy: bounds.height/3)
        trackLayer.setNeedsDisplay()
        
        let textWidth : CGFloat = 20
        
        let lowerThumbCenter = CGFloat(positionForValue(lowerValue))
        lowerTextView?.frame = CGRect(x: max(lowerThumbCenter - textWidth/2.0, 0.0), y: 0.0, width: thumbWidth, height: bounds.height/3)
        lowerTextView?.setNeedsDisplay()
        
        let upperThumbCenter = CGFloat(positionForValue(upperValue))
        upperTextView?.frame = CGRect(x:
            max(min(upperThumbCenter - textWidth/2.0, bounds.width-textWidth), lowerThumbCenter + textWidth/2.0), y: 0.0, width: thumbWidth, height: bounds.height/3)
        upperTextView?.setNeedsDisplay()
        
        CATransaction.commit()
    }
    
    fileprivate let trackLayer = TimeIntervalViewTrackLayer()
    
    fileprivate var thumbWidth: CGFloat {
        return CGFloat(bounds.height)
    }
    
    func positionForValue(_ value: Double) -> Double {
        return Double(bounds.width) * (value - minimumValue) /
            (maximumValue - minimumValue) 
    }
}
