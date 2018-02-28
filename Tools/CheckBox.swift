//
//  CheckBox.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 26.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class CheckBox: UIButton {
    // Images
    let checkedImage = UIImage(named: "check_box")! as UIImage
    let uncheckedImage = UIImage(named: "check_box_blank")! as UIImage
    
    // Bool property
    var isChecked: Bool = false {
        didSet{
            if isChecked == true {
                self.setImage(checkedImage, for: UIControlState.normal)
                self.imageView!.contentMode = UIViewContentMode.scaleAspectFit;
                self.contentHorizontalAlignment = .left
            } else {
                self.setImage(uncheckedImage, for: UIControlState.normal)
                self.imageView!.contentMode = UIViewContentMode.scaleAspectFit;
                self.contentHorizontalAlignment = .left
            }
        }
    }
    
    override func awakeFromNib() {
        self.addTarget(self, action:#selector(buttonClicked(sender:)), for: UIControlEvents.touchUpInside)
        self.isChecked = false
    }
    
    @objc public func buttonClicked(sender: UIButton) {
        if sender == self {
            isChecked = !isChecked
        }
    }
}