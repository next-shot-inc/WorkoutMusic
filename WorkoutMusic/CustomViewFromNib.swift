//
//  CustomViewFromNib.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/27/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit

class NibLoadingView: UIView {

    weak var view: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        nibSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        nibSetup()
    }

    private func nibSetup() {
        backgroundColor = .clear

        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true

        addSubview(view)
    }

    private func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of:self))
        let nib = UINib(nibName: String(describing: type(of:self)), bundle: bundle)
        let nibView = nib.instantiate(withOwner: self, options: nil).first as! UIView
        nibView.anchorAllEdgesToSuperview()
        return nibView
    }

}

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
