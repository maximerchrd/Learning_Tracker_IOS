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
    var checkedImage: UIImage
    var uncheckedImage: UIImage
    
    //Constructor
    required init() {
        // set myValue before super.init is called
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        var size = CGSize()
        size.width = screenWidth / 16
        size.height = screenWidth / 16
        checkedImage = UIImage(named: "check_box")! as UIImage
        uncheckedImage = UIImage(named: "check_box_blank")! as UIImage
        
        super.init(frame: .zero)
        checkedImage = resizeImage(image: checkedImage, targetSize: size)
        uncheckedImage = resizeImage(image: uncheckedImage, targetSize: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Bool property
    var isChecked: Bool = false {
        didSet{
            let buttonWidth = self.frame.width
            if isChecked == true {
                self.setImage(checkedImage, for: UIControlState.normal)
                self.imageView!.contentMode = UIViewContentMode.scaleAspectFit;
                if UIDevice.current.userInterfaceIdiom == .phone {
                    self.contentEdgeInsets = UIEdgeInsetsMake(0, -buttonWidth / 4, 0, 0)
                    self.titleEdgeInsets = UIEdgeInsetsMake(0, -buttonWidth / 4, 0, 0)
                }
                self.contentHorizontalAlignment = .left
            } else {
                self.setImage(uncheckedImage, for: UIControlState.normal)
                self.imageView!.contentMode = UIViewContentMode.scaleAspectFit;
                if UIDevice.current.userInterfaceIdiom == .phone {
                    self.contentEdgeInsets = UIEdgeInsetsMake(0, -buttonWidth / 4, 0, 0)
                    self.titleEdgeInsets = UIEdgeInsetsMake(0, -buttonWidth / 4, 0, 0)
                }
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
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
