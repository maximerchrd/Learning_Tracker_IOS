//
//  WifiCommunication.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 24.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit
import SwiftSocket

class WifiCommunication {
    let PORT_NUMBER = 9090
    var host = "xxx.xxx.x.xxx"
    var client: TCPClient?
    var classroomActivityViewController: ClassroomActivityViewController?
    var pendingAnswer = "none"
    
    init(classroomActivityViewControllerArg: ClassroomActivityViewController) {
        classroomActivityViewController = classroomActivityViewControllerArg
    }
    init() {
    }
    
    public func connectToServer() -> Bool {
        do { try host = DbTableSettings.retrieveMaster() } catch {}
        client = TCPClient(address: host, port: Int32(PORT_NUMBER))
        let dataConverter = DataConverstion()
        
        switch client!.connect(timeout: 10) {
        case .success:
            switch client!.send(data: dataConverter.connection()) {
                case .success:
                    (UIApplication.shared.delegate as! AppDelegate).wifiCommunicationAppDelegate = self
                    listenToServer()
                    return true
                case .failure(let error):
                    DbTableLogs.insertLog(log: error.localizedDescription)
                    print(error)
                    return false
            }
        case .failure(let error):
            if error.localizedDescription.contains("3") {
                DbTableLogs.insertLog(log: error.localizedDescription + "(could connect to ip but server not running?)")
            } else {
                DbTableLogs.insertLog(log: error.localizedDescription + "(ip not valid?)")
            }
            print(error)
            return false
        }
    }
    
    private func listenToServer() {
        var prefix = "not initialized"
        DispatchQueue.global(qos: .background).async {
            var ableToRead = true
            while (self.client != nil && ableToRead) {
                let data = self.client!.read(40, timeout: 5400)
                if data != nil {
                    prefix = String(bytes: data!, encoding: .utf8) ?? "oops, problem in listenToServer(): prefix is nil"
                    if prefix.contains("oops") {
                        DbTableLogs.insertLog(log: prefix)
                        break
                    }
                    print(prefix)
                    let typeID = prefix.components(separatedBy: ":")[0]
                    
                    if typeID.range(of:"MULTQ") != nil {
                        self.readAndStoreQuestion(prefix: prefix, typeOfQuest: typeID)
                    } else if typeID.range(of:"SHRTA") != nil {
                        self.readAndStoreQuestion(prefix: prefix, typeOfQuest: typeID)
                    } else if typeID.range(of:"QID") != nil {
                        DispatchQueue.main.async {
                            var questionMultipleChoice = QuestionMultipleChoice()
                            var questionShortAnswer = QuestionShortAnswer()
                            if (prefix.components(separatedBy: ":")[1].contains("MLT")) {
                                let id_global = Int(prefix.components(separatedBy: "///")[1])
                                do {
                                    questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: id_global!)
                                    
                                    if questionMultipleChoice.Question.count > 0 && questionMultipleChoice.Question != "none" {
                                        self.classroomActivityViewController?.showMultipleChoiceQuestion(question:  questionMultipleChoice, isCorr: false)
                                    } else {
                                        questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: id_global!)
                                        self.classroomActivityViewController?.showShortAnswerQuestion(question: questionShortAnswer, isCorr: false)
                                    }
                                } catch let error {
                                    print(error)
                                }
                            }
                        }
                    } else if typeID.range(of:"EVAL") != nil {
                        do {
                            try DbTableIndividualQuestionForResult.insertIndividualQuestionForResult(questionID: Int(prefix.components(separatedBy: "///")[2])!, answer: self.pendingAnswer, quantitativeEval: prefix.components(separatedBy: "///")[1])
                        } catch let error {
                            print(error)
                        }
                    } else if typeID.range(of:"UPDEV") != nil {
                        do {
                        try DbTableIndividualQuestionForResult.setEvalForQuestionAndStudentIDs(eval: prefix.components(separatedBy: "///")[1], idQuestion: prefix.components(separatedBy: "///")[2])
                        } catch let error {
                            print(error)
                        }
                    } else if typeID.range(of:"CORR") != nil {
                        DispatchQueue.main.async {
                            var questionMultipleChoice = QuestionMultipleChoice()
                            var questionShortAnswer = QuestionShortAnswer()
                            let id_global = Int(prefix.components(separatedBy: "///")[1])
                            do {
                                questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: id_global!)
                                
                                if questionMultipleChoice.Question.count > 0 && questionMultipleChoice.Question != "none" {
                                    self.classroomActivityViewController?.showMultipleChoiceQuestion(question:  questionMultipleChoice, isCorr: true)
                                } else {
                                    questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: id_global!)
                                    self.classroomActivityViewController?.showShortAnswerQuestion(question: questionShortAnswer, isCorr: true)
                                }
                            } catch let error {
                                print(error)
                            }
                        }
                    } else if typeID.range(of:"TEST") != nil {
                        if prefix.components(separatedBy: ":").count > 1 {
                            let textSize = Int(prefix.components(separatedBy: ":")[1].trimmingCharacters(in: CharacterSet(charactersIn: "01234567890.").inverted)) ?? 0
                            var dataText = [UInt8]()
                            while dataText.count < textSize {
                                dataText += self.client!.read(textSize) ?? [UInt8]()
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
                                                print("problem reading objectives for test: objective - ID pair not complete")
                                            }
                                        }
                                    }
                                    try DbTableTests.insertTest(testID: testID, test: test, objectiveIDs: objectiveIDS, objectives: objectives)
                                } else {
                                    print("problem reading test: text array to short")
                                }
                            } catch let error {
                                print(error)
                            }
                        }
                    } else if typeID.range(of:"TESYN") != nil {
                        DispatchQueue.main.async {
                            if prefix.components(separatedBy: ":").count > 1 {
                                let textSize = Int(prefix.components(separatedBy: ":")[1].trimmingCharacters(in: CharacterSet(charactersIn: "01234567890.").inverted)) ?? 0
                                var dataText = [UInt8]()
                                while dataText.count < textSize {
                                    dataText += self.client!.read(textSize) ?? [UInt8]()
                                }
                                let dataTextString = String(bytes: dataText, encoding: .utf8) ?? "oops, problem reading test: dataText to string yields nil"
                                if dataTextString.contains("oops") {
                                    DbTableLogs.insertLog(log: dataTextString)
                                }
                                if dataTextString.components(separatedBy: "///").count > 2 {
                                    let questionIDs = dataTextString.components(separatedBy: "///")
                                    var IDs = [Int]()
                                    for questionID in questionIDs {
                                        IDs.append(Int(questionID) ?? -1)
                                    }
                                    self.classroomActivityViewController?.showTest(questionIDs: IDs)
                                } else {
                                    print("problem reading test: no question ID")
                                }
                            }
                        }
                    }
                } else {
                    ableToRead = false
                }
            }
        }
    }
    
    public func sendAnswerToServer(answer: String, globalID: Int, questionType: String) {
        pendingAnswer = answer
        var message = ""
        do {
            var question = ""
            if questionType == "ANSW0" {
                let questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: globalID)
                question = questionMultipleChoice.Question
            } else if questionType == "ANSW1" {
                let questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: globalID)
                question = questionShortAnswer.Question
            }
            let name = try DbTableSettings.retrieveName()
            message = questionType + "///" + UIDevice.current.identifierForVendor!.uuidString + "///" + name + "///"
            message += (answer + "///" + question + "///" + String(globalID));
            client!.send(string: message)
        } catch {}
    }
    
    public func sendDisconnectionSignal() {
        print("student is leaving the task")
        do {
            let message = try "DISC///" + UIDevice.current.identifierForVendor!.uuidString + "///" + DbTableSettings.retrieveName() + "///"
            client!.send(string: message)
        } catch let error {
            print(error)
        }
    }
    
    public func receivedQuestion(questionID: String) {
        do {
            let message = "GOTIT///" + questionID + "///"
            client!.send(string: message)
        } catch let error {
            print(error)
        }
    }
    
    fileprivate func readAndStoreQuestion(prefix: String, typeOfQuest: String) {
        if prefix.components(separatedBy: ":").count > 1 {
            let imageSize:Int? = Int(prefix.components(separatedBy: ":")[1])
            var textSizeString = prefix.components(separatedBy: ":")[2]
            textSizeString = String(textSizeString.filter { "01234567890.".contains($0) })
            let textSize:Int? = Int(textSizeString)
            
            var dataText = [UInt8]()
            while dataText.count < textSize ?? 0 {
                dataText += self.client!.read(textSize!) ?? [UInt8]()
            }
            print(imageSize!)

                var dataImage = [UInt8]()
            while dataImage.count < imageSize ?? 0 {
                dataImage += self.client!.read(imageSize!) ?? [UInt8]()
            }
            let dataTextString = String(bytes: dataText, encoding: .utf8) ?? "oops, problem in readAndStoreQuestion: dataText to string yields nil"
            if dataTextString.contains("oops") {
                DbTableLogs.insertLog(log: dataTextString)
            }
            print(dataTextString)
            var questionID = -1
            do {
                if typeOfQuest.range(of: "MULTQ") != nil {
                    let questionMult = DataConverstion.bytesToMultq(textData: dataText, imageData: dataImage)
                    questionID = questionMult.ID
                    try DbTableQuestionMultipleChoice.insertQuestionMultipleChoice(Question: questionMult)
                } else if typeOfQuest.range(of: "SHRTA") != nil {
                    let questionShrt = DataConverstion.bytesToShrtaq(textData: dataText, imageData: dataImage)
                    questionID = questionShrt.ID
                    try DbTableQuestionShortAnswer.insertQuestionShortAnswer(Question: questionShrt)
                }
            } catch let error {
                print(error)
            }
            receivedQuestion(questionID: String(questionID))
        } else {
            DbTableLogs.insertLog(log: "error reading questions: prefix not in correct format or buffer truncated")
            print("error reading questions: prefix not in correct format or buffer truncated")
        }
    }
}
