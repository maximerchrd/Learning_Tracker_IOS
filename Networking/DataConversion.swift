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
        try input = "CONN" + "///"
            + UIDevice.current.identifierForVendor!.uuidString + "///"
            + DbTableSettings.retrieveName()
        } catch {}
        let dataUTF8 = input.data(using: .utf8)!
        return dataUTF8
    }
    
    static public func bytesToMultq(textData: Data, imageData: Data) -> QuestionMultipleChoice {
        var questionMultipleChoice = QuestionMultipleChoice()
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
        questionMultipleChoice.ID = Int(wholeText.components(separatedBy: "///")[11])
        questionMultipleChoice.NbCorrectAnswers = Int(wholeText.components(separatedBy: "///")[12])
        questionMultipleChoice.Image = wholeText.components(separatedBy: "///")[15]
        
        //deal with subjects
        var subjectsArray = wholeText.components(separatedBy: "///")[13].components(separatedBy: "|||")
        for subject in subjectsArray {
            questionMultipleChoice.Subjects.append(subject)
        }
        //deal with objectives
        var objectivesArray = wholeText.components(separatedBy: "///")[14].components(separatedBy: "|||")
        for objective in objectivesArray {
            questionMultipleChoice.Objectives.append(objective)
        }
        return questionMultipleChoice
    }
}
