//
//  RunningStickFigureView.swift
//  WorkoutMusic
//
//  Created by next-shot on 2/9/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class RunningStickFigureView : UIView {
    struct Path {
        let moveTo : CGPoint
        let lineTo : [CGPoint]
        
        func getPath() -> UIBezierPath {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: moveTo.x, y: moveTo.y))
            
            for p in lineTo {
                path.addLine(to: CGPoint(x: p.x, y: p.y))
            }
            return path
        }
    }
    let backLegPath = Path(
        moveTo: CGPoint(x: 7.501, y: 107.112),
        lineTo: [CGPoint(x: 35.633, y: 106.324),
                 CGPoint(x: 59.395, y: 73.722)]
    )
    let frontLegPath = Path(
        moveTo: CGPoint(x: 76.693, y: 150.281),
        lineTo: [CGPoint(x:84.516, y: 103.214 ),
                 CGPoint( x: 60.767, y: 75.512)]
       )
    let backArmPath = Path(
        moveTo: CGPoint(x: 37.272, y: 59.261),
        lineTo: [CGPoint(x: 57.210, y: 32.444 ),
                 CGPoint( x: 84.249, y: 33.233)]
    )
    let frontArmPath = Path(
        moveTo: CGPoint(x: 123.579, y: 40.857),
        lineTo: [CGPoint(x: 107.192,y: 60.639 ),
                 CGPoint( x: 84.249, y : 33.233)]
    )
    let torso = Path(
        moveTo: CGPoint(x: 62.945, y: 73.196),
        lineTo: [CGPoint(x: 82.337, y: 39.280)]
    )
    
    struct Circle {
        let center: CGPoint
        let radius : CGFloat
    }
    let head = Circle(center: CGPoint(x: 92.56, y: 12.63), radius: 13)
    
    let frontLegLayer = CAShapeLayer()
    let backLegLayer = CAShapeLayer()
    let frontArmLayer = CAShapeLayer()
    let backArmLayer = CAShapeLayer()
    
    @IBInspectable public var scaling: Float = 0.8 {
        didSet {
            setup(animate: false)
        }
    }
    
    @IBInspectable public var animatedPathTintColor: UIColor = UIColor(red: 0.0, green: 0.45, blue: 0.94, alpha: 1.0) {
        didSet {
            frontLegLayer.setNeedsDisplay()
            backLegLayer.setNeedsDisplay()
            frontArmLayer.setNeedsDisplay()
            backArmLayer.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialConfig()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialConfig()
    }
    
    func initialConfig() {
        self.backgroundColor = .clear
        self.layer.addSublayer(self.frontLegLayer)
        self.layer.addSublayer(self.backLegLayer)
        self.layer.addSublayer(self.frontArmLayer)
        self.layer.addSublayer(self.backArmLayer)
        self.setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        stopAnimation()
        
        self.setShape(layer: frontLegLayer, with: frontLegPath)
        self.setShape(layer: backLegLayer, with: backLegPath)
        self.setShape(layer: frontArmLayer, with: frontArmPath)
        self.setShape(layer: backArmLayer, with: backArmPath)
    }
    
    func stopAnimation() {
        self.frontLegLayer.removeAllAnimations()
        self.backLegLayer.removeAllAnimations()
        self.frontArmLayer.removeAllAnimations()
        self.backArmLayer.removeAllAnimations()
    }
    
    func setup(animate: Bool = false, bpm: Int = 120, duration: Int = 30) {
        if animate {
            self.animateShape(layer: frontLegLayer, with: backLegPath, bpm: bpm, duration: duration)
            self.animateShape(layer: backLegLayer, with: frontLegPath, bpm: bpm, duration: duration)
            self.animateShape(layer: frontArmLayer, with: backArmPath, bpm: bpm, duration: duration)
            self.animateShape(layer: backArmLayer, with: frontArmPath, bpm: bpm, duration: duration)
        } else {
            self.setShape(layer: frontLegLayer, with: frontLegPath)
            self.setShape(layer: backLegLayer, with: backLegPath)
            self.setShape(layer: frontArmLayer, with: frontArmPath)
            self.setShape(layer: backArmLayer, with: backArmPath)
        }
    }
    
    private func animateShape(layer: CAShapeLayer, with: Path, bpm: Int, duration: Int) {
        let newShapePath = with.getPath().cgPath
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = Double(60)/Double(bpm)
        animation.repeatCount = Float(duration)/Float(animation.duration)
        animation.toValue = newShapePath
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        
        layer.add(animation, forKey: "path")
    }
    
    func setShape(layer: CAShapeLayer, with: Path) {
        layer.strokeColor = animatedPathTintColor.cgColor
        layer.path = with.getPath().cgPath
        layer.lineWidth = 10
        layer.lineCap = .round
        layer.fillColor = nil
        
        layer.setAffineTransform(
            CGAffineTransform.init(scaleX: CGFloat(scaling), y: CGFloat(scaling)).concatenating(
                CGAffineTransform.init(translationX: 0, y: 10)
            )
        )
    }
    
    override func draw(_ rect: CGRect) {
        
        if let context = UIGraphicsGetCurrentContext() {
            func drawPath(inputPath: Path) {
                
                context.move(to: CGPoint(x: inputPath.moveTo.x, y: inputPath.moveTo.y))
                
                for p in inputPath.lineTo {
                    context.addLine(to: CGPoint(x: p.x, y: p.y))
                }
                context.drawPath(using: .stroke)
                
            }
            
            context.setStrokeColor(UIColor.label.cgColor)
            
            context.translateBy(x: 0, y: 10)
            context.scaleBy(x: CGFloat(scaling), y: CGFloat(scaling))
            
            context.setLineWidth(10)
            context.setLineCap(.round)
            
            //drawPath(inputPath: backArmPath)
            //drawPath(inputPath: frontArmPath)
            //drawPath(inputPath: backLegPath)
            //drawPath(inputPath: frontLegPath)
            
            context.setLineWidth(15)
            drawPath(inputPath: torso)
            
            context.setFillColor(UIColor.label.cgColor)
            context.fillEllipse(in: CGRect(x: head.center.x - head.radius, y: head.center.y - head.radius, width: head.radius*2, height: head.radius*2
            ))
            
            context.scaleBy(x: 1/CGFloat(scaling), y: 1/CGFloat(scaling))
            context.translateBy(x: 0, y: -10)
            
            context.setLineWidth(1)
            let rect = CGRect(x: 2, y: 2, width: frame.width-2, height: frame.height-2)
            context.stroke(rect)
            
        }
    }
}
