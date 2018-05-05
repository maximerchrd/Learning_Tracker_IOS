//
//  ReceptionProtocol.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 27.04.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import UIKit

class ReceptionProtocol {
    static func receivedQID(prefix: String) {
        DispatchQueue.main.async {
            var questionMultipleChoice = QuestionMultipleChoice()
            var questionShortAnswer = QuestionShortAnswer()
            if (prefix.components(separatedBy: ":")[1].contains("MLT")) {
                let id_global = Int(prefix.components(separatedBy: "///")[1])
                let directCorrection = Int(prefix.components(separatedBy: "///")[2]) ?? 0
                do {
                    questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: id_global!)
                    
                    if questionMultipleChoice.Question.count > 0 && questionMultipleChoice.Question != "none" {
                        AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showMultipleChoiceQuestion(question:  questionMultipleChoice, isCorr: false, directCorrection: directCorrection)
                    } else {
                        questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: id_global!)
                        AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showShortAnswerQuestion(question: questionShortAnswer, isCorr: false, directCorrection: directCorrection)
                    }
                } catch let error {
                    print(error)
                }
            }
        }
    }
    
    static func receivedEVAL(prefix: String) {
        do {
            try DbTableIndividualQuestionForResult.insertIndividualQuestionForResult(questionID: Int(prefix.components(separatedBy: "///")[2])!, answer: (AppDelegate.wifiCommunicationSingleton?.pendingAnswer)!, quantitativeEval: prefix.components(separatedBy: "///")[1])
        } catch let error {
            print(error)
        }
    }
    
    static func receivedUPDEV(prefix: String) {
        do {
            try DbTableIndividualQuestionForResult.setEvalForQuestionAndStudentIDs(eval: prefix.components(separatedBy: "///")[1], idQuestion: prefix.components(separatedBy: "///")[2])
        } catch let error {
            print(error)
        }
    }
    
    static func receivedCORR(prefix: String) {
        DispatchQueue.main.async {
            var questionMultipleChoice = QuestionMultipleChoice()
            var questionShortAnswer = QuestionShortAnswer()
            let id_global = Int(prefix.components(separatedBy: "///")[1])
            do {
                questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: id_global!)
                
                if questionMultipleChoice.Question.count > 0 && questionMultipleChoice.Question != "none" {
                    AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showMultipleChoiceQuestion(question:  questionMultipleChoice, isCorr: true)
                } else {
                    questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: id_global!)
                    AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showShortAnswerQuestion(question: questionShortAnswer, isCorr: true)
                }
            } catch let error {
                print(error)
            }
        }
    }
    
    static func receivedTESTFromServer(prefix: String) {
        if prefix.components(separatedBy: ":").count > 1 {
            let textSize = Int(prefix.components(separatedBy: ":")[1].trimmingCharacters(in: CharacterSet(charactersIn: "01234567890.").inverted)) ?? 0
            var dataText = [UInt8]()
            while dataText.count < textSize {
                dataText += AppDelegate.wifiCommunicationSingleton?.client!.read(textSize) ?? [UInt8]()
            }
            let dataTextString = String(bytes: dataText, encoding: .utf8) ?? "oops, problem reading test: dataText to string yields nil"
            if dataTextString.contains("oops") {
                DbTableLogs.insertLog(log: dataTextString)
            }
            do {
                if dataTextString.components(separatedBy: "///").count > 3 {
                    let testID = Int(dataTextString.components(separatedBy: "///")[0]) ?? 0
                    let test = dataTextString.components(separatedBy: "///")[1]
                    let objectivesArray = dataTextString.components(separatedBy: "///")[2].components(separatedBy: "|||")
                    var objectiveIDS = [Int]()
                    var objectives = [String]()
                    for objectiveANDid in objectivesArray {
                        if objectiveANDid.count > 0 {
                            objectiveIDS.append(Int(objectiveANDid.components(separatedBy: "/|/")[0]) ?? 0)
                            if objectiveANDid.components(separatedBy: "/|/").count > 1 {
                                objectives.append(objectiveANDid.components(separatedBy: "/|/")[1])
                            } else {
                                let error = "problem reading objectives for test: objective - ID pair not complete"
                                print(error)
                                DbTableLogs.insertLog(log: error)
                            }
                        }
                    }
                    try DbTableTests.insertTest(testID: testID, test: test, objectiveIDs: objectiveIDS, objectives: objectives)
                } else {
                    let error = "problem reading test: text array to short"
                    print(error)
                    DbTableLogs.insertLog(log: error)
                }
            } catch let error {
                print(error)
            }
        }
    }
    
    static func receivedTESYNFromServer(prefix: String) {
        
        if prefix.components(separatedBy: ":").count > 2 {
            let textSize = Int(prefix.components(separatedBy: ":")[1].trimmingCharacters(in: CharacterSet(charactersIn: "01234567890.").inverted)) ?? 0
            let directCorrection = Int(prefix.components(separatedBy: ":")[2].trimmingCharacters(in: CharacterSet(charactersIn: "01234567890.").inverted)) ?? 0
            var dataText = [UInt8]()
            while dataText.count < textSize {
                dataText += AppDelegate.wifiCommunicationSingleton?.client!.read(textSize) ?? [UInt8]()
            }
            let dataTextString = String(bytes: dataText, encoding: .utf8) ?? "oops, problem reading test: data to string yields nil"
            if dataTextString.contains("oops") {
                DbTableLogs.insertLog(log: dataTextString)
            }
            if dataTextString.components(separatedBy: "///").count > 2 {
                let questionIDs = dataTextString.components(separatedBy: "///")
                var IDs = [Int]()
                for questionID in questionIDs {
                    let ID = Int(questionID) ?? -1
                    if ID != -1 {
                        IDs.append(ID)
                    }
                }
                DispatchQueue.main.async {
                    AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showTest(questionIDs: IDs, directCorrection: directCorrection)
                }
            } else {
                let error = "problem reading test: no question ID"
                print(error)
                DbTableLogs.insertLog(log: error)
            }
        }
        
    }
}
