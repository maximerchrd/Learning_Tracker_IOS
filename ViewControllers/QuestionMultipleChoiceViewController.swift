//
//  QuestionMultipleChoiceViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 24.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class QuestionMultipleChoiceViewController: UIViewController {
    var questionMultipleChoice: QuestionMultipleChoice
    var screenHeight: Float
    var screenWidth: Float
    
    @IBOutlet weak var QuestionLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        questionMultipleChoice = QuestionMultipleChoice()
        screenHeight = 0
        screenWidth = 0
        super.init(coder: aDecoder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let screenSize = UIScreen.main.bounds
        screenWidth = Float(screenSize.width)
        screenHeight = Float(screenSize.height)
        
        QuestionLabel.text = questionMultipleChoice.Question
        
        questionMultipleChoice.removeEmptyOptions()
        var i = 1
        for singleOption in questionMultipleChoice.Options {
            let computedX = Int(screenWidth / 15)
            let computedY = Int(Float(QuestionLabel.frame.maxY) + (screenHeight / 15) * Float(i))
            let computedWidth = Int(screenWidth * 0.9)
            let computedHeight = Int(screenHeight / 20)
            let checkBox = CheckBox(frame: CGRect(x: computedX, y: computedY, width: computedWidth, height: computedHeight))
            checkBox.isChecked = false
            checkBox.setTitle(singleOption, for: .normal)
            checkBox.addTarget(checkBox, action: #selector(checkBox.buttonClicked(sender:)), for: .touchUpInside)
            checkBox.setTitleColor(.black, for: .normal)
            self.view.addSubview(checkBox)

            i = i + 1
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
