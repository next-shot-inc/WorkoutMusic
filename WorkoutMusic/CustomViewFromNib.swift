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
