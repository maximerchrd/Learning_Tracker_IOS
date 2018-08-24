//
//  Test.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 09.05.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation

class Test {
    var testID = ""
    var testName = ""
    var testMap = [[String]]()
    var questionIDs = [String]()
    var IDactive = [String: Bool]()
    var answeredIds = [String]()
    var IDresults = [String: Float32]()
    var startTime: TimeInterval?
    var score = 0.0
    
    func buildIDsArraysFromMap() {
        for id in questionIDs {
            IDactive[id] = true
            IDresults[id] = -1.0
        }
        for relation in testMap {
            if !(relation[2] == "") {
                IDactive[relation[1]] = false
            }
        }
    }
    
    func refreshActiveIds() {
        for relation in testMap {
            let singlerelations = relation[2].components(separatedBy: ";")
            for singlerelation in singlerelations {
                if singlerelation.contains("EVALUATION<") {
                    let threshold = Float32(singlerelation.replacingOccurrences(of: "EVALUATION<", with: "")) ?? -1.0
                    let result = IDresults[relation[0]] ?? -1.0
                    if result >= 0.0 && result < threshold {
                        IDactive[relation[1]] = true
                    }
                }
            }
        }
    }
    
    func calculateScoreAndCheckIfOver() -> Bool {
        var finished = false
        var nbActiveQuestions = 0
        score = 0.0
        for (id, active) in IDactive {
            if active {
                score = score + Double(IDresults[id] ?? 0.0)
                nbActiveQuestions = nbActiveQuestions + 1
            }
        }
        if nbActiveQuestions == answeredIds.count {
            finished = true
            score = score / Double(answeredIds.count)
            //stop timer
            var timeInterval = Date.timeIntervalSinceReferenceDate - (startTime ?? 0)
            timeInterval = Double(round(10*timeInterval)/10)
            do {
                try DbTableIndividualQuestionForResult.insertIndividualQuestionForResult(questionID: Int64(testID) ?? 0, quantitativeEval: String(score), qualitativeEval: "no medal", type: 3, timeForSolving: String(timeInterval))
            } catch let error {
                print(error)
            }
        }
        return finished
    }
}
