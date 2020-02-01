//
//  RoundedButton.swift
//  WorkoutMusic
//
//  Created by next-shot on 1/30/20.
//  Copyright © 2020 next-shot. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class UIRoundButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = 10 {
        didSet{
            self.layer.cornerRadius = cornerRadius
        }
    }

    @IBInspectable var borderWidth: CGFloat = 0{
        didSet{
            self.layer.borderWidth = borderWidth
        }
    }

    @IBInspectable var borderColor: UIColor = UIColor.clear{
        didSet{
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var bgColor: UIColor = UIColor.clear{
        didSet {
            let image = createImage(color: bgColor)
            setBackgroundImage(image, for: UIControl.State.normal)
            clipsToBounds = true
        }
    }
    
    func createImage(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1), true, 0.0)
        color.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        return image
    }
    
    // Overwrite intrinsicContentSize for the labels not to be clipped.
    // From the documentation: The insets you specify are applied to the title rectangle after that rectangle has been sized to fit the button’s text.
    // Thus, positive inset values may actually clip the title text.
    override open var intrinsicContentSize: CGSize {
        let intrinsicContentSize = super.intrinsicContentSize

        let adjustedWidth = intrinsicContentSize.width + titleEdgeInsets.left + titleEdgeInsets.right + contentEdgeInsets.left + contentEdgeInsets.right
        let adjustedHeight = intrinsicContentSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom + contentEdgeInsets.bottom + contentEdgeInsets.top

        return CGSize(width: adjustedWidth, height: adjustedHeight)
    }
    
    /// Function called when going from dark to light mode
    /// recreate the bg image according to the new color trait
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
         let image = createImage(color: bgColor)
         setBackgroundImage(image, for:.normal)
    }
}
