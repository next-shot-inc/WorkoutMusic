//
//  CustomViewFromNib.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/27/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func anchorAllEdgesToSuperview() {
        self.translatesAutoresizingMaskIntoConstraints = false
        for attribute : NSLayoutConstraint.Attribute in [.left, .top, .right, .bottom] {
            anchorToSuperview(attribute: attribute)
        }
    }

    func anchorToSuperview(attribute: NSLayoutConstraint.Attribute) {
        addSuperviewConstraint(constraint: NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: superview, attribute: attribute, multiplier: 1.0, constant: 0.0))
    }

    func addSuperviewConstraint(constraint: NSLayoutConstraint) {
        superview?.addConstraint(constraint)
    }
}

extension UIViewController {
    func loadNibView(nibName: String, into: UIView) -> UIView? {
       if let customView = Bundle.main.loadNibNamed(nibName, owner: into, options: nil)?.first as? UIView {
            customView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            customView.translatesAutoresizingMaskIntoConstraints = true
            into.addSubview(customView)
            customView.anchorAllEdgesToSuperview()
            customView.setNeedsLayout()
            return customView
        }
        return nil
    }
}

class ShowSpinnerController {
    var spinnerView : UIView?
    var labelView : UIView?
    
    func showSpinner(onView : UIView, withLabel : String? = nil) {
        spinnerView = UIView.init(frame: onView.bounds)
        spinnerView!.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .large)
        ai.startAnimating()
        ai.center = spinnerView!.center

        initLabelView(onView: onView, label: withLabel)
        
        DispatchQueue.main.async {
            if( self.labelView != nil ) {
                self.spinnerView?.addSubview(self.labelView!)
            }
            self.spinnerView!.addSubview(ai)
            onView.addSubview(self.spinnerView!)
        }
    }
    
    func initLabelView(onView: UIView, label: String?)  {
        if( label != nil ) {
            spinnerView!.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
            let labelHeight : CGFloat = 100
            let activityIndicatorHeight : CGFloat = 40
            // Place the label to be just below the activity Indicator.
            let noDataLabel: UILabel  = UILabel(frame: CGRect(x: 20, y: onView.bounds.size.height/2 - labelHeight/2 + activityIndicatorHeight, width: onView.bounds.size.width - 20, height: labelHeight))
            noDataLabel.textColor     = UIColor.label
            noDataLabel.textAlignment = .center
            noDataLabel.numberOfLines = 0
            noDataLabel.text = label
            labelView = noDataLabel
        }
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            self.spinnerView?.removeFromSuperview()
            self.labelView?.removeFromSuperview()
            self.spinnerView = nil
            self.labelView = nil
        }
    }
}
