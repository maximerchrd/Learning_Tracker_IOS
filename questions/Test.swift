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
    var finishTime = 0.0
    var score = 0.0
    var medalsInstructions = [(String, String)]()
    
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
            finishTime = timeInterval
        }
        return finished
    }
    
    func parseMedalsInstructions(instructions: String) {
        medalsInstructions.removeAll()
        let instructionsArray = instructions.components(separatedBy: ";")
        for instruction in instructionsArray {
            if instruction.count > 0 && instruction != "null" && instruction != "no test found" {
                var time = instruction.components(separatedBy: ":")[1].components(separatedBy: "/")[0]
                if time == "0" || time == "0.0" {
                    time = "1000000"
                }
                let score = instruction.components(separatedBy: ":")[1].components(separatedBy: "/")[1]
                let couple = (time,score)
                medalsInstructions.append(couple)
            }
        }
    }
}
