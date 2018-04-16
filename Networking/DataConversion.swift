//
//  DataConversion.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 24.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class DataConverstion {
    
    public func connection() -> Data {
        var input = "problem retrieving name from DB"
        do {
            let MCQIDsList = try DbTableQuestionMultipleChoice.getAllQuestionsMultipleChoiceIDs()
            let SHRTAQIDsList = try DbTableQuestionShortAnswer.getAllQuestionsShortAnswersIDs()
            try input = "CONN" + "///"
                + UIDevice.current.identifierForVendor!.uuidString + "///"
                + DbTableSettings.retrieveName() + "///"
                + MCQIDsList + "|" + SHRTAQIDsList
        } catch {}
        let dataUTF8 = input.data(using: .utf8)!
        return dataUTF8
    }
    
    static public func bytesToMultq(textData: [UInt8]?, imageData: [UInt8]?) -> QuestionMultipleChoice {
        let questionMultipleChoice = QuestionMultipleChoice()
        let wholeText = String(bytes: textData!, encoding: .utf8) ?? "oops, problem converting the question text"
        
        //prepares the question
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
        return questionMultipleChoice
    }
    
    static public func bytesToShrtaq(textData: [UInt8]?, imageData: [UInt8]?) -> QuestionShortAnswer {
        let questionShortAnswer = QuestionShortAnswer()
        let wholeText = String(bytes: textData!, encoding: .utf8) ?? "oops, problem converting the question text"
        
        //prepares the question
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
    
    
}
