import Foundation
import MultipeerConnectivity
import UIKit

class ReceptionProtocol {
    static func receivedResource(objectName: String, resourceData: [UInt8]) {
        switch objectName {
        case "QuestionView":
            storeQuestion(resourceData: resourceData)
            break
        case "ObjectiveTransferable":
            receivedObjective(resourceData: resourceData)
            break
        case "SubjectTransferable":
            receivedSubject(resourceData: resourceData)
            break
        case "TestView":
            receivedTestView(resourceData: resourceData)
            break
        case "GameView":
            receivedGameView(resourceData: resourceData)
            break
        default:
            print("Received Resource Type is Unknown")
        }
    }
    
    static func receivedGameView(resourceData: [UInt8]) {
        let decoder = JSONDecoder()
        do {
            let gameView = try decoder.decode(GameView.self, from: Data(bytes: resourceData))
            DispatchQueue.main.async {
                AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showGame(gameView: gameView)
            }
            
        } catch let error {
            print(error)
        }
    }
    
    static func receivedTestView(resourceData: [UInt8]) {
        let decoder = JSONDecoder()
        do {
            let testView = try decoder.decode(TestView.self, from: Data(bytes: resourceData))
            
            //extract objectives for certificative test
            let objectivesArray = testView.objectives.components(separatedBy: "|||")
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
    
    static func receivedObjective(resourceData: [UInt8]) {
        let decoder = JSONDecoder()
        do {
            let objective = try decoder.decode(ObjectiveTransferable.self, from: Data(bytes: resourceData))
            try DbTableLearningObjective.insertLearningObjective(questionID: Int64(objective.questionId) ?? 0, objective: objective._objectiveName, levelCognitiveAbility: objective._objectiveLevel)
        } catch let jsonError {
            print(jsonError)
        }
    }
    
    static func receivedSubject(resourceData: [UInt8]) {
        let decoder = JSONDecoder()
        do {
            let subject = try decoder.decode(SubjectTransferable.self, from: Data(bytes: resourceData))
            try DbTableSubject.insertSubject(questionID: Int64(subject.questionId) ?? 0, subject: subject._subjectName)
        } catch let jsonError {
            print(jsonError)
        }
    }

    static func storeQuestion(resourceData: [UInt8]) {
        var questionID:Int64 = -1
        let decoder = JSONDecoder()
        do {
            let question = try decoder.decode(QuestionView.self, from: Data(bytes: resourceData))
            print(question)

            if question.type == QuestionView.multipleChoice {
                let questionMultChoice = QuestionMultipleChoice()
                questionMultChoice.initFromQuestionView(questionView: question)
                questionID = questionMultChoice.id
                if questionMultChoice.question != "error" {
                    try DbTableQuestionMultipleChoice.insertQuestionMultipleChoice(Question: questionMultChoice)
                }
                //code for functional testing
                if questionMultChoice.question.contains("7492qJfzdDSB") {
                    let transferable = ClientToServerTransferable(prefix: ClientToServerTransferable.accuserReceptionPrefix)
                    AppDelegate.wifiCommunicationSingleton!.client?.send(data: transferable.getTransferableBytes())
                }
            } else if question.type == QuestionView.shortAnswer {
                let questionShortAnswer = QuestionShortAnswer()
                questionShortAnswer.initFromQuestionView(questionView: question)
                questionID = questionShortAnswer.id
                if questionShortAnswer.question != "error" {
                    try DbTableQuestionShortAnswer.insertQuestionShortAnswer(Question: questionShortAnswer)
                }
            }

            //send back a signal that we got the question
            let transferable = ClientToServerTransferable(prefix: ClientToServerTransferable.okPrefix)
            transferable.optionalArgument1 = UIDevice.current.identifierForVendor!.uuidString
            transferable.optionalArgument2 = String(questionID)
            AppDelegate.wifiCommunicationSingleton!.client?.send(data: transferable.getTransferableBytes())
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
            case ShortCommand.gameScore:
                let scoreTeamOne = Double(shortCommand.optionalArgument1) ?? 0
                let scoreTeamTwo = Double(shortCommand.optionalArgument2) ?? 0
                if ClassroomActivityViewController.navGameViewController != nil {
                    ClassroomActivityViewController.navGameViewController?.changeScore(teamOneScore: scoreTeamOne, teamTwoScore: scoreTeamTwo)
                }
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
    
    static func receivedFile(fileSize: Int, objectName: String, resourceData: [UInt8]) {
        //insert file only if we received all the data
        if fileSize == resourceData.count {
            let mediaData = Data(bytes: resourceData);
            guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                               appropriateFor: nil, create: false) as NSURL else {
                                                                print("ERROR: unable to open directory when saving file")
                                                                return
            }
            do {
                try mediaData.write(to: directory.appendingPathComponent(objectName)!)
            } catch let error {
                print(error.localizedDescription)
            }
            
            //send back a signal that we got the question
            let transferable = ClientToServerTransferable(prefix: ClientToServerTransferable.okPrefix)
            transferable.optionalArgument1 = UIDevice.current.identifierForVendor!.uuidString
            transferable.optionalArgument2 = objectName
            AppDelegate.wifiCommunicationSingleton!.client?.send(data: transferable.getTransferableBytes())
        } else {
            let errorMessage = "\n expected fileSize: " + String(fileSize) + "; actual fileSize: " + String(resourceData.count)
            print(errorMessage)
        }
    }
}
