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
    var classroomActivityViewController: ClassroomActivityViewController
    
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
            while (self.client != nil) {
                let data = self.client!.read(40, timeout: 5400)
                if data != nil {
                    prefix = String(bytes: data!, encoding: .utf8) ?? "oops, problem"
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
                                        self.classroomActivityViewController.showMultipleChoiceQuestion(question:  questionMultipleChoice)
                                    } else {
                                        questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: id_global!)
                                        self.classroomActivityViewController.showShortAnswerQuestion(question: questionShortAnswer)
                                    }
                                } catch {}
                            }
                        }
                    } else if typeID.range(of:"EVAL") != nil {
                        
                    } else if typeID.range(of:"UPDEV") != nil {
                        
                    }
                }
            }
        }
    }
    
    fileprivate func readAndStoreQuestion(prefix: String, typeOfQuest: String) {
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
        print(String(bytes: dataText, encoding: .utf8) ?? "oops, problem")
        do {
            if typeOfQuest.range(of: "MULTQ") != nil {
                try DbTableQuestionMultipleChoice.insertQuestionMultipleChoice(Question: DataConverstion.bytesToMultq(textData: dataText, imageData: dataImage))
            } else if typeOfQuest.range(of: "SHRTA") != nil {
                try DbTableQuestionShortAnswer.insertQuestionShortAnswer(Question: DataConverstion.bytesToShrtaq(textData: dataText, imageData: dataImage))
            }
        } catch {}
    }
}
