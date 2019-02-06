import Foundation
import MultipeerConnectivity
import UIKit

class ReceptionProtocol {
    static func receivedResource(objectName: String, resourceData: [UInt8]) {
        switch objectName {
        case "QuestionView":
            storeQuestion(resourceData: resourceData)
            break
        default:
            print("Received Resource Type is Unknown")
        }
    }

    static func storeQuestion(resourceData: [UInt8]) {
        var questionID:Int64 = -1
        let decoder = JSONDecoder()
        do {
            var question = try decoder.decode(QuestionView.self, from: Data(bytes: resourceData))
            print(question)

            if question.type == QuestionView.multipleChoice {
                var questionMultChoice = QuestionMultipleChoice()
                questionMultChoice.initFromQuestionView(questionView: question)
                questionID = questionMultChoice.id
                if questionMultChoice.question != "error" {
                    try DbTableQuestionMultipleChoice.insertQuestionMultipleChoice(Question: questionMultChoice)
                }
                //code for functional testing
                if questionMultChoice.question.contains("7492qJfzdDSB") {
                    AppDelegate.wifiCommunicationSingleton!.client?.send(data: "ACCUSERECEPTION///".data(using: .utf8)!)
                }
            } else if question.type == QuestionView.shortAnswer {
                var questionShortAnswer = QuestionShortAnswer()
                questionShortAnswer.initFromQuestionView(questionView: question)
                questionID = questionShortAnswer.id
                if questionShortAnswer.question != "error" {
                    try DbTableQuestionShortAnswer.insertQuestionShortAnswer(Question: questionShortAnswer)
                }
            }

            //send back a signal that we got the question
            let accuseReception = "OK:" + UIDevice.current.identifierForVendor!.uuidString + "///" + String(questionID) + "///"
            AppDelegate.wifiCommunicationSingleton!.client?.send(data: accuseReception.data(using: .utf8)!)
        } catch let error {
            print(error)
        }
    }

    static func receivedStateUpdate(dataSize: Int, objectName: String, resourceData: [UInt8]) {
        switch objectName {
        case "ShortCommand":
            receivedShortCommand(resourceData: resourceData)
            break
        case "QuestionIdentifier":
            receivedQuestionIdentifier(resourceData: resourceData)
            break
        case "SyncedIds":
            //TODO: prevent server to send SYNCIDS to IOS devices (only for nearby connections)
            AppDelegate.wifiCommunicationSingleton!.readDataIntoArray(expectedSize: dataSize)
            break
        case "Evaluation":
            receivedEvaluation(resourceData: resourceData)
            break
        default:
            print("Received StateUpdate Type is Unknown")
        }
    }

    static func receivedShortCommand(resourceData: [UInt8]) {
        let decoder = JSONDecoder()
        do {
            var shortCommand = try decoder.decode(ShortCommand.self, from: Data(bytes: resourceData))
            switch shortCommand.command {
            case ShortCommand.connected:
                print("Received Connected")
                break
            case ShortCommand.correction:
                receivedCorrection(resourceData: resourceData)
                break
            default:
                print("Received Command is Unknown")
            }
        } catch let error {
            print(error)
        }
    }
    
    static func receivedCorrection(resourceData: [UInt8]) {
        
        DispatchQueue.main.async {
            var questionMultipleChoice = QuestionMultipleChoice()
            var questionShortAnswer = QuestionShortAnswer()
            do {
                let decoder = JSONDecoder()
                var shortCommand = try decoder.decode(ShortCommand.self, from: Data(bytes: resourceData))
                let id_global = Int64(shortCommand.optionalArgument1) ?? 0
                questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: id_global)
                if questionMultipleChoice.question.count > 0 && questionMultipleChoice.question != "none" {
                    AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showMultipleChoiceQuestion(question:  questionMultipleChoice, isCorr: true)
                } else {
                    questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: id_global)
                    AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showShortAnswerQuestion(question: questionShortAnswer, isCorr: true)
                }
            } catch let error {
                print(error)
            }
        }
    }

    static func receivedQuestionIdentifier(resourceData: [UInt8]) {
        let decoder = JSONDecoder()
        do {
            var questionIdentifier = try decoder.decode(QuestionIdentifier.self, from: Data(bytes: resourceData))

            DispatchQueue.main.async {
                var questionMultipleChoice = QuestionMultipleChoice()
                var questionShortAnswer = QuestionShortAnswer()
                let idGlobal = Int64(questionIdentifier.identifier) ?? 0
                if idGlobal < 0 {
                    let test = Test()
                    test.testID = String(-idGlobal)
                    test.testName = DbTableTests.getNameFromTestID(testID: -idGlobal)
                    test.questionIDs = DbTableTests.getQuestionIds(testName: test.testName)
                    test.testMap = DbTableRelationQuestionQuestion.getTestMapForTest(test: test.testName)
                    test.parseMedalsInstructions(instructions: DbTableTests.getMedalsInstructionsFromTestID(testID: -idGlobal))
                    test.mediaFileName = DbTableTests.getMediaFileNameFromTestID(testID: -idGlobal)

                    DispatchQueue.main.async {
                        AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showTest(test: test, directCorrection: questionIdentifier.correctionMode, testMode: 0)
                    }
                } else {
                    let id_global = Int64(questionIdentifier.identifier) ?? 0
                    do {
                        questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: id_global)

                        if questionMultipleChoice.question.count > 0 && questionMultipleChoice.question != "none" {
                            AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?
                                    .showMultipleChoiceQuestion(question:  questionMultipleChoice, isCorr: false, directCorrection: questionIdentifier.correctionMode)
                        } else {
                            questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: id_global)
                            AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?
                                    .showShortAnswerQuestion(question: questionShortAnswer, isCorr: false, directCorrection: questionIdentifier.correctionMode)
                        }
                    } catch let error {
                        print(error)
                    }
                }
            }
        } catch let jsonError {
            print(jsonError)
        }
    }

    static func receivedEvaluation(resourceData: [UInt8]) {
        let decoder = JSONDecoder()
        do {
            let evaluationObject = try decoder.decode(Evaluation.self, from: Data(bytes: resourceData))
            if evaluationObject.evaluationType == Evaluation.questionEvaluation {
                if evaluationObject.evalUpdate {
                    do {
                        try DbTableIndividualQuestionForResult.setEvalForQuestionAndStudentIDs(eval: String(evaluationObject.evaluation), idQuestion: evaluationObject.identifier)
                    } catch let error {
                        print(error)
                    }
                } else {
                    try DbTableIndividualQuestionForResult.insertIndividualQuestionForResult(questionID: Int64(evaluationObject.identifier) ?? 0,
                            answer: (AppDelegate.wifiCommunicationSingleton?.pendingAnswer)!, quantitativeEval: String(evaluationObject.evaluation))
                    if ClassroomActivityViewController.navTestTableViewController != nil {
                        AppDelegate.activeTest.IDresults[evaluationObject.identifier] = Float32(evaluationObject.evaluation)
                        DispatchQueue.main.async {
                            ClassroomActivityViewController.navTestTableViewController?.reloadTable()
                        }
                    }
                }
            } else if evaluationObject.evaluationType == Evaluation.objectiveEvaluation {
                do {
                    let testID = Int64(evaluationObject.testIdentifier) ?? 0
                    let testName = evaluationObject.testName
                    let objectiveID = Int64(evaluationObject.identifier) ?? 0
                    let objective = evaluationObject.name
                    let evaluation = String(evaluationObject.evaluation)
                    
                    //insert test in db after parsing questions
                    try DbTableLearningObjective.insertLearningObjective(objectiveID: objectiveID, objective: objective, levelCognitiveAbility: 0)
                    try DbTableRelationTestObjective.insertRelationTestObjective(idTest: testID, idObjective: objectiveID)
                    try DbTableTests.insertTest(testID: testID, test: testName, testType: "CERTIF")
                    try DbTableIndividualQuestionForResult.insertIndividualQuestionForResult(questionID: objectiveID, quantitativeEval: evaluation, testBelonging: testName, type: 2)
                } catch let error {
                    print(error)
                }
            } else {
                print("Unknown Evaluation Type Received")
            }
        } catch let jsonError {
            print(jsonError)
        }
    }
    
    static func receivedEVAL(prefix: String) {
        do {
            try DbTableIndividualQuestionForResult.insertIndividualQuestionForResult(questionID: Int64(prefix.components(separatedBy: "///")[2]) ?? 0, answer: (AppDelegate.wifiCommunicationSingleton?.pendingAnswer)!, quantitativeEval: prefix.components(separatedBy: "///")[1])
            if ClassroomActivityViewController.navTestTableViewController != nil {
                AppDelegate.activeTest.IDresults[prefix.components(separatedBy: "///")[2]] = Float32(prefix.components(separatedBy: "///")[1]) ?? -1.0
                DispatchQueue.main.async {
                    ClassroomActivityViewController.navTestTableViewController?.reloadTable()
                }
            }
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
            let id_global = Int64(prefix.components(separatedBy: "///")[1])
            do {
                questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: id_global!)
                
                if questionMultipleChoice.question.count > 0 && questionMultipleChoice.question != "none" {
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
    
    static func receivedTESTFromServer(prefix: DataPrefix) {
        let textSize = prefix.dataLength
        var dataText = AppDelegate.wifiCommunicationSingleton?.readDataIntoArray(expectedSize: textSize) ?? [UInt8]()
        let decoder = JSONDecoder()

        do {
            var testView = try decoder.decode(TestView.self, from: Data(bytes: dataText))

            //extract objectives for certificative test
            var objectivesArray = testView.objectives.components(separatedBy: "|||")
            var objectiveIDS = [Int64]()
            var objectives = [String]()
            for objectiveANDid in objectivesArray {
                if objectiveANDid.count > 0 {
                    objectiveIDS.append(Int64(objectiveANDid.components(separatedBy: "/|/")[0]) ?? 0)
                    if objectiveANDid.components(separatedBy: "/|/").count > 1 {
                        objectives.append(objectiveANDid.components(separatedBy: "/|/")[1])
                    } else {
                        let error = "problem reading objectives for test: objective - ID pair not complete"
                        print(error)
                        DbTableLogs.insertLog(log: error)
                    }
                }
            }

            //parse the test map and insert the corresponding question-question relations inside the database
            let testMapArray = testView.testMap.components(separatedBy: "|||")
            var questionIdsForTest = ""
            for question in testMapArray {
                let relations = question.components(separatedBy: ";;;")
                let questionID = relations[0]
                questionIdsForTest += questionID + "///"
                for i in 1..<relations.count {
                    DbTableRelationQuestionQuestion.insertRelationQuestionQuestion(idGlobal1: questionID, idGlobal2:
                    relations[i].components(separatedBy: ":::")[0], test: testView.testName,
                            condition: relations[i].components(separatedBy: ":::")[1])

                }
            }


            //insert test in db after parsing questions
            try DbTableTests.insertTest(testID: Int64(testView.idTest) ?? 0, test: testView.testName, questionIDs: questionIdsForTest,
                    objectiveIDs: objectiveIDS, objectives: objectives, medalsInstructions: testView.medalInstructions,
                    mediaFileName: testView.mediaFileName ?? "")
        } catch let error {
            print(error)
        }
    }

    class func receivedSUBOBJ(prefix: DataPrefix, wifiCommunication: WifiCommunication) {
        let subObjData = wifiCommunication.readDataIntoArray(expectedSize: prefix.dataLength)
        let decoder = JSONDecoder()
        do {
            var subObj = try decoder.decode(SubjectsAndObjectivesForQuestion.self, from: Data(bytes: subObjData))
            var questionId = Int64(subObj.questionId) ?? 0

            for subject in subObj.subjects {
                try DbTableSubject.insertSubject(questionID: questionId, subject: subject)
            }

            for objective in subObj.objectives {
                try DbTableLearningObjective.insertLearningObjective(questionID: questionId, objective: objective, levelCognitiveAbility: -1)
            }
        } catch let error {
            print(error)
        }
    }

    static func receivedOEVALFromServer(prefix: String) {
        if prefix.components(separatedBy: ":").count > 1 {
            let textSize = Int(prefix.components(separatedBy: ":")[1].trimmingCharacters(in: CharacterSet(charactersIn: "01234567890.").inverted)) ?? 0
            var dataText = AppDelegate.wifiCommunicationSingleton?.readDataIntoArray(expectedSize: textSize) ?? [UInt8]()
            let dataTextString = String(bytes: dataText, encoding: .utf8) ?? "oops, problem reading objectives evaluation: dataText to string yields nil"
            if dataTextString.contains("oops") {
                DbTableLogs.insertLog(log: dataTextString)
            }
            do {
                if dataTextString.components(separatedBy: "///").count >= 5 {
                    let testID = Int64(dataTextString.components(separatedBy: "///")[0]) ?? 0
                    let testName = dataTextString.components(separatedBy: "///")[1]
                    let objectiveID = Int64(dataTextString.components(separatedBy: "///")[2]) ?? 0
                    let objective = dataTextString.components(separatedBy: "///")[3]
                    let evaluation = dataTextString.components(separatedBy: "///")[4]
                    
                    //insert test in db after parsing questions
                    try DbTableLearningObjective.insertLearningObjective(objectiveID: objectiveID, objective: objective, levelCognitiveAbility: 0)
                    try DbTableRelationTestObjective.insertRelationTestObjective(idTest: testID, idObjective: objectiveID)
                    try DbTableTests.insertTest(testID: testID, test: testName, testType: "CERTIF")
                    try DbTableIndividualQuestionForResult.insertIndividualQuestionForResult(questionID: objectiveID, quantitativeEval: evaluation, testBelonging: testName, type: 2)
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
    
    static func receivedFILEFromServer(prefix: String) {
        if prefix.components(separatedBy: "///").count != 3 {
            let fileName = prefix.components(separatedBy: "///")[1]
            let fileSize = Int(prefix.components(separatedBy: "///")[2]) ?? 0
            
            let fileData = AppDelegate.wifiCommunicationSingleton!.readDataIntoArray(expectedSize: fileSize)
            print("expected fileSize: " + String(fileSize) + " actual textSize read: " + String(fileData.count))
            
            //insert file only if we received all the data
            if fileSize == fileData.count {
                let mediaData = Data(bytes: fileData);
                guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                        appropriateFor: nil, create: false) as NSURL else {
                    print("ERROR: unable to open directory when saving file")
                    return
                }
                do {
                    try mediaData.write(to: directory.appendingPathComponent(fileName)!)
                } catch let error {
                    print(error.localizedDescription)
                }

                //send back a signal that we got the question
                let accuseReception = "OK:" + UIDevice.current.identifierForVendor!.uuidString + "///" + fileName + "///"
                AppDelegate.wifiCommunicationSingleton!.client?.send(data: accuseReception.data(using: .utf8)!)
            } else {
                var errorMessage = "\n expected fileSize: " + String(fileSize) + "; actual fileSize: " + String(fileData.count)
                print(errorMessage)
            }
        } else {
            let errorMessage = "error reading questions: prefix not in correct format or buffer truncated"
            print(errorMessage)
        }
    }
}
