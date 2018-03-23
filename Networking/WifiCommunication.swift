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
    
    init(classroomActivityViewControllerArg: ClassroomActivityViewController) {
        classroomActivityViewController = classroomActivityViewControllerArg
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
                print(error)
                return false
            }
        case .failure(let error):
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
                            try DbTableIndividualQuestionForResult.insertIndividualQuestionForResult(questionID: Int(prefix.components(separatedBy: "///")[2])!, quantitativeEval: prefix.components(separatedBy: "///")[1])
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
                    }
                } else {
                    ableToRead = false
                }
            }
        }
    }
    
    public func sendAnswerToServer(answer: String, globalID: Int, questionType: String) {
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
            print(String(bytes: dataText, encoding: .utf8) ?? "oops, problem in readAndStoreQuestion: dataText to string yields nil")
            do {
                if typeOfQuest.range(of: "MULTQ") != nil {
                    try DbTableQuestionMultipleChoice.insertQuestionMultipleChoice(Question: DataConverstion.bytesToMultq(textData: dataText, imageData: dataImage))
                } else if typeOfQuest.range(of: "SHRTA") != nil {
                    try DbTableQuestionShortAnswer.insertQuestionShortAnswer(Question: DataConverstion.bytesToShrtaq(textData: dataText, imageData: dataImage))
                }
            } catch let error {
                print(error)
            }
        } else {
            print("error reading questions: prefix not in correct format or buffer truncated")
        }
    }
}
