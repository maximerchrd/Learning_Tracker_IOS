//
//  ResultsTargetRepresentationViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class ResultsTargetRepresentationViewController: UIViewController {
    var evaluations_low = [String]()
    var evaluations_middle = [String]()
    var evaluations_high = [String]()
    var evaluations_top = [String]()
    var labelsArray = [UILabel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTargetRepresentation(subject: "All Subjects")
    }
    
    public func updateTargetRepresentation(subject: String) {
        for singleLabel in labelsArray {
            singleLabel.removeFromSuperview()
        }
        evaluations_low.removeAll(keepingCapacity: true)
        evaluations_middle.removeAll(keepingCapacity: true)
        evaluations_high.removeAll(keepingCapacity: true)
        evaluations_top.removeAll(keepingCapacity: true)
        var allEvals = [[String]]()
        do {
            allEvals = try DbTableLearningObjective.getResultsPerObjective(subject: subject)
        } catch let error {
            print(error)
        }
        var allObjectives = allEvals[0]
        var allResults = allEvals[1]
        for i in 0..<allObjectives.count {
            if Double(allResults[i]) ?? 0 < 40.0 {
                evaluations_low.append(allObjectives[i])
            } else if Double(allResults[i]) ?? 0 < 50.0 {
                evaluations_middle.append(allObjectives[i])
            } else if Double(allResults[i]) ?? 0 < 60.0 {
                evaluations_high.append(allObjectives[i])
            } else {
                evaluations_top.append(allObjectives[i])
            }
        }
        displayObjectives(objectives: evaluations_low, color: UIColor.red, performanceFactor: 0.5)
        displayObjectives(objectives: evaluations_middle, color: UIColor(red: 0, green: 0.6392, blue: 0.0314, alpha: 1.0), performanceFactor: 0.3)
        displayObjectives(objectives: evaluations_high, color: UIColor.blue, performanceFactor: 0.1)
        displayObjectives(objectives: evaluations_top, color: UIColor.magenta, performanceFactor: 0.0)
    }
    
    private func displayObjectives(objectives: [String], color: UIColor, performanceFactor: Double) {
        let screenSize = UIScreen.main.bounds
        let width = Int(screenSize.width)
        let height = Int(screenSize.height)
        for i in 0..<objectives.count {
            //calculate coordinates
            let stepper = 1 - (i % 3);
            let horizontalStep = width/3 * (stepper) + 100;
            let leftMargin = width / 3 + horizontalStep;
            let verticalStep = (i / 3) * height/20 + 100;
            let topMargin = Int(Double(height) * performanceFactor + Double(verticalStep));    //should increase one step every 3 textViews
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.center = CGPoint(x: leftMargin, y: topMargin)
            label.textAlignment = .center
            label.textColor = color
            label.text = objectives[i]
            self.view.addSubview(label)
            labelsArray.append(label)
            
            //add action listener to the label
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapFunction))
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(tap)
        }
    }
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        let label = sender.view as? UILabel
        let center = label?.center
        if label?.numberOfLines != 10 {
            label?.numberOfLines = 10
            label?.backgroundColor = UIColor.white
            label?.sizeToFit()
            label?.center = center!
            label?.layer.zPosition = 1;
        } else {
            label?.backgroundColor = UIColor.clear
            label?.textAlignment = .center
            label?.numberOfLines = 1
            label?.bounds = CGRect(x: 0, y: 0, width: 200, height: 21)
            label?.center = center!
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
