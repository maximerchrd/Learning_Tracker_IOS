//
//  DataConversion.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 24.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class DataConversion {
    
    public func connection() -> Data {
        var input = "problem retrieving name from DB"
        do {
            let MCQIDsList = try DbTableQuestionMultipleChoice.getAllQuestionsMultipleChoiceIDs()
            let SHRTAQIDsList = try DbTableQuestionShortAnswer.getAllQuestionsShortAnswersIDs()
            try input = "CONN" + "///"
                + UIDevice.current.identifierForVendor!.uuidString + "///"
                + DbTableSettings.retrieveName() + "///"
                + MCQIDsList + "|" + SHRTAQIDsList
        } catch let error {
            print(error)
            DbTableLogs.insertLog(log: error.localizedDescription)
        }
        let dataUTF8 = input.data(using: .utf8)!
        return dataUTF8
    }
    
    static public func bytesToMultq(textData: [UInt8]?, imageData: [UInt8]?) -> QuestionMultipleChoice {
        let questionMultipleChoice = QuestionMultipleChoice()
        let wholeText = String(bytes: textData!, encoding: .utf8) ?? "oops, problem converting the question text"
        if wholeText.contains("oops") {
            print(wholeText)
            DbTableLogs.insertLog(log: wholeText)
        }
        
        //prepares the question
        if wholeText.components(separatedBy: "///").count > 15 {
            questionMultipleChoice.Question = wholeText.components(separatedBy: "///")[0]
            questionMultipleChoice.Options.append(wholeText.components(separatedBy: "///")[1])
            questionMultipleChoice.Options.append(wholeText.components(separatedBy: "///")[2])
            questionMultipleChoice.Options.append(wholeText.components(separatedBy: "///")[3])
            questionMultipleChoice.Options.append(wholeText.components(separatedBy: "///")[4])
            questionMultipleChoice.Options.append(wholeText.components(separatedBy: "///")[5])
            questionMultipleChoice.Options.append(wholeText.components(separatedBy: "///")[6])
            questionMultipleChoice.Options.append(wholeText.components(separatedBy: "///")[7])
            questionMultipleChoice.Options.append(wholeText.components(separatedBy: "///")[8])
            questionMultipleChoice.Options.append(wholeText.components(separatedBy: "///")[9])
            questionMultipleChoice.Options.append(wholeText.components(separatedBy: "///")[10])
            questionMultipleChoice.ID = Int(wholeText.components(separatedBy: "///")[11])!
            questionMultipleChoice.NbCorrectAnswers = Int(wholeText.components(separatedBy: "///")[12])!
            questionMultipleChoice.Image = wholeText.components(separatedBy: "///")[15]
            
            //save the picture
            let imageNSData: NSData = NSData(bytes: imageData, length: imageData!.count)
            let uiImage: UIImage = UIImage(data: imageNSData as Data) ?? UIImage()
            saveImage(image: uiImage, fileName: questionMultipleChoice.Image)
            
            do {
                //deal with subjects
                let subjectsArray = wholeText.components(separatedBy: "///")[13].components(separatedBy: "|||")
                for subject in subjectsArray {
                    questionMultipleChoice.Subjects.append(subject)
                    try DbTableSubject.insertSubject(questionID: questionMultipleChoice.ID, subject: subject)
                }
                //deal with objectives
                let objectivesArray = wholeText.components(separatedBy: "///")[14].components(separatedBy: "|||")
                for objective in objectivesArray {
                    questionMultipleChoice.Objectives.append(objective)
                    try DbTableLearningObjective.insertLearningObjective(questionID: questionMultipleChoice.ID, objective: objective, levelCognitiveAbility: 0)
                }
            } catch let error {
                print(error)
            }
        } else {
            NSLog("%@", "Problem converting bytes to question multiple choice: parsed array too short")
            questionMultipleChoice.Question = "error"
        }
        return questionMultipleChoice
    }
    
    static public func bytesToShrtaq(textData: [UInt8]?, imageData: [UInt8]?) -> QuestionShortAnswer {
        let questionShortAnswer = QuestionShortAnswer()
        let wholeText = String(bytes: textData!, encoding: .utf8) ?? "oops, problem converting the question text"
        if wholeText.contains("oops") {
            print(wholeText)
            DbTableLogs.insertLog(log: wholeText)
        }
        
        //prepares the question
        if wholeText.components(separatedBy: "///").count > 5 {
            questionShortAnswer.Question = wholeText.components(separatedBy: "///")[0]
            questionShortAnswer.ID = Int(wholeText.components(separatedBy: "///")[1])!
            questionShortAnswer.Options = wholeText.components(separatedBy: "///")[2].components(separatedBy: "|||")
            let indexOfEmptyOption = questionShortAnswer.Options.index(of: "")
            if indexOfEmptyOption != nil {
                questionShortAnswer.Options.remove(at: indexOfEmptyOption!)
            }
            questionShortAnswer.Image = wholeText.components(separatedBy: "///")[5]
        
            //save the picture
            let imageNSData: NSData = NSData(bytes: imageData, length: imageData!.count)
            let uiImage: UIImage = UIImage(data: imageNSData as Data) ?? UIImage()
            saveImage(image: uiImage, fileName: questionShortAnswer.Image)
        
            do {
                //deal with subjects
                var subjectsArray = wholeText.components(separatedBy: "///")[3].components(separatedBy: "|||")
                let indexOfEmptySubject = subjectsArray.index(of: "")
                if indexOfEmptySubject != nil {
                    subjectsArray.remove(at: indexOfEmptySubject!)
                }
                for subject in subjectsArray {
                    questionShortAnswer.Subjects.append(subject)
                    try DbTableSubject.insertSubject(questionID: questionShortAnswer.ID, subject: subject)
                }
                //deal with objectives
                var objectivesArray = wholeText.components(separatedBy: "///")[4].components(separatedBy: "|||")
                let indexOfEmptyObjective = objectivesArray.index(of: "")
                if indexOfEmptyObjective != nil {
                    objectivesArray.remove(at: indexOfEmptyObjective!)
                }
                for objective in objectivesArray {
                    questionShortAnswer.Objectives.append(objective)
                    try DbTableLearningObjective.insertLearningObjective(questionID: questionShortAnswer.ID, objective: objective, levelCognitiveAbility: 0)
                }
            } catch let error {
                print(error)
            }
        } else {
            NSLog("%@", "Problem converting bytes to question multiple choice: parsed array too short")
            questionShortAnswer.Question = "error"
        }
        return questionShortAnswer
    }
    
    static private func saveImage(image: UIImage, fileName: String) -> Bool {
        guard let data = UIImageJPEGRepresentation(image, 1) ?? UIImagePNGRepresentation(image) else {
            return false
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return false
        }
        do {
            try data.write(to: directory.appendingPathComponent(fileName)!)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    static public func storeQuestionFromData(typeOfQuest: String, questionData: Data, prefix: String) {
        if prefix.components(separatedBy: ":").count > 1 {
            let imageSize:Int? = Int(prefix.components(separatedBy: ":")[1]) ?? 0
            let textSize:Int? = Int(prefix.components(separatedBy: ":")[2]) ?? 0
            let dataText = questionData.subdata(in: 80..<(80+textSize!))
            if questionData.count >= 80 + textSize! + imageSize! {
                let dataImage = questionData.subdata(in: (80+textSize!)..<questionData.count)
                do {
                    if typeOfQuest.range(of: "MULTQ") != nil {
                        let questionMult = DataConversion.bytesToMultq(textData: [UInt8](dataText), imageData: [UInt8](dataImage))
                        try DbTableQuestionMultipleChoice.insertQuestionMultipleChoice(Question: questionMult)
                    } else if typeOfQuest.range(of: "SHRTA") != nil {
                        let questionShrt = DataConversion.bytesToShrtaq(textData: [UInt8](dataText), imageData: [UInt8](dataImage))
                        try DbTableQuestionShortAnswer.insertQuestionShortAnswer(Question: questionShrt)
                    }
                } catch let error {
                    print(error)
                }
            } else {
                NSLog("%@", "problem storing question from peer: buffer too short")
            }
        } else {
            NSLog("%@", "problem storing question from peer: prefix not in correct format or buffer truncated")
        }
    }
    static public func dataFromMultipleChoiceQuestionID(questionID: String) -> Data {
        var data = "error transforming multiple choice question to Data".data(using: .utf8)!
        do {
            let multipleChoiceQuestion = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: Int(questionID) ?? 0)
            var textData: Data
            var imageData = Data(bytes: [UInt8]())
            
            //first load the question text
            var questionText = ""
            questionText += multipleChoiceQuestion.Question + "///"
            for option in multipleChoiceQuestion.Options {
                questionText += option + "///"
            }
            questionText += String(multipleChoiceQuestion.ID) + "///"
            questionText += String(multipleChoiceQuestion.NbCorrectAnswers) + "///"
            for subject in multipleChoiceQuestion.Subjects {
                questionText += subject + "///"
            }
            for objective in multipleChoiceQuestion.Objectives {
                questionText += objective + "///"
            }
            questionText += multipleChoiceQuestion.Image + "///"
            textData = questionText.data(using: .utf8)!
            
            // Load picture
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
            let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath          = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(multipleChoiceQuestion.Image)
                imageData = try Data(contentsOf: imageURL)
            }
            
            //build prefix
            var prefix = "MULTQ:"
            prefix += String(textData.count) + ":"
            prefix += String(imageData.count) + "///"
            var prefixData = prefix.data(using: .utf8)!
            var missingBytes = [UInt8]()
            for _ in 0..<(80-(prefixData.count)) {
                missingBytes.append(0)
            }
            prefixData += Data(bytes: missingBytes)
            
            data = prefixData + textData + imageData
            
        } catch let error {
            print(error)
        }
        return data
    }
    static public func dataFromShortAnswerQuestionID(questionID: String) -> Data {
        var data = "error transforming multiple choice question to Data".data(using: .utf8)!
        do {
            let shortAnswerQuestion = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: Int(questionID) ?? 0)
            var textData: Data
            var imageData = Data(bytes: [UInt8]())
            
            //first load the question text
            var questionText = ""
            questionText += shortAnswerQuestion.Question + "///"
            for option in shortAnswerQuestion.Options {
                questionText += option + "///"
            }
            questionText += String(shortAnswerQuestion.ID) + "///"
            for subject in shortAnswerQuestion.Subjects {
                questionText += subject + "///"
            }
            for objective in shortAnswerQuestion.Objectives {
                questionText += objective + "///"
            }
            questionText += shortAnswerQuestion.Image + "///"
            textData = questionText.data(using: .utf8)!
            
            // Load picture
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
            let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath          = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(shortAnswerQuestion.Image)
                imageData = try Data(contentsOf: imageURL)
            }
            
            //build prefix
            var prefix = "SHRTA:"
            prefix += String(textData.count) + ":"
            prefix += String(imageData.count) + "///"
            var prefixData = prefix.data(using: .utf8)!
            var missingBytes = [UInt8]()
            for _ in 0..<(80-(prefixData.count)) {
                missingBytes.append(0)
            }
            prefixData += Data(bytes: missingBytes)
            
            data = prefixData + textData + imageData
            
        } catch let error {
            print(error)
        }
        return data
    }
}
