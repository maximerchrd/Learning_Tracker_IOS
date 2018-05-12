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
import SystemConfiguration.CaptiveNetwork
import MultipeerConnectivity

class WifiCommunication {
    let PORT_NUMBER = 9090
    var host = "xxx.xxx.x.xxx"
    var client: TCPClient?
    var classroomActivityViewController: ClassroomActivityViewController?
    var pendingAnswer = "none"
    var peeridUidDictionary = [String:MCPeerID]()
    
    init(classroomActivityViewControllerArg: ClassroomActivityViewController) {
        classroomActivityViewController = classroomActivityViewControllerArg
    }
    
    public func connectToServer() {
        DispatchQueue.global(qos: .utility).async {
            //first check if we are connected to a wifi network
            if self.currentSSIDs().count == 0 {
                self.displayInstructions(instructionIndex: 0)
            } else {
                do { try self.host = DbTableSettings.retrieveMaster() } catch {}
                self.client = TCPClient(address: self.host, port: Int32(self.PORT_NUMBER))
                let dataConverter = DataConversion()
                
                switch self.client!.connect(timeout: 4) {
                case .success:
                    switch self.client!.send(data: dataConverter.connection()) {
                    case .success:
                        self.displayInstructions(instructionIndex: 1)
                        DispatchQueue.global(qos: .utility).async {
                            self.listenToServer()
                        }
                    case .failure(let error):
                        self.displayInstructions(instructionIndex: 2)
                        DbTableLogs.insertLog(log: error.localizedDescription)
                        print(error)
                    }
                case .failure(let error):
                    self.displayInstructions(instructionIndex: 2)
                    if error.localizedDescription.contains("3") {
                        DbTableLogs.insertLog(log: error.localizedDescription + "(could connect to ip but server not running?)")
                    } else {
                        DbTableLogs.insertLog(log: error.localizedDescription + "(ip not valid?)")
                    }
                    print(error)
                }
            }
        }
    }
    
    public func listenToServer() {
        var prefix = "not initialized"
        var ableToRead = true
        
        while (self.client != nil && ableToRead) {
            let data = self.client!.read(80, timeout: 5400)
            if data != nil {
                prefix = String(bytes: data!, encoding: .utf8) ?? "oops, problem in listenToServer(): prefix is nil"
                if prefix.contains("oops") {
                    DbTableLogs.insertLog(log: prefix)
                    print(prefix)
                    fatalError()
                }
                print(prefix)
                let typeID = prefix.components(separatedBy: "///")[0].components(separatedBy: ":")[0]
                
                if typeID.range(of:"MULTQ") != nil {
                    self.readAndStoreQuestion(prefix: prefix, typeOfQuest: typeID, prefixData: data!)
                } else if typeID.range(of:"SHRTA") != nil {
                    self.readAndStoreQuestion(prefix: prefix, typeOfQuest: typeID, prefixData: data!)
                } else if typeID.range(of:"QID") != nil {
                    ReceptionProtocol.receivedQID(prefix: prefix)
                } else if typeID.range(of:"EVAL") != nil {
                    ReceptionProtocol.receivedEVAL(prefix: prefix)
                } else if typeID.range(of:"UPDEV") != nil {
                    ReceptionProtocol.receivedUPDEV(prefix: prefix)
                } else if typeID.range(of:"CORR") != nil {
                    ReceptionProtocol.receivedCORR(prefix: prefix)
                } else if typeID.range(of:"TEST") != nil {
                    ReceptionProtocol.receivedTESTFromServer(prefix: prefix)
                } else if typeID.range(of:"TESYN") != nil {
                    //ReceptionProtocol.receivedTESYNFromServer(prefix: prefix)
                } else {
                    DbTableLogs.insertLog(log: "message received but prefix not supported: " + prefix)
                    print("message received but prefix not supported")
                }
            } else {
                ableToRead = false
            }
        }
        
    }
    
    public func sendAnswerToServer(answer: String, globalID: Int, questionType: String, timeSpent: String) {
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
            message += (answer + "///" + question + "///" + String(globalID)) + "///" + timeSpent;
            if client != nil {
                client!.send(string: message)
            } else {
                print("client is nil when trying to send the answer")
            }
        } catch let error {
            print(error)
        }
    }
    
    public func sendData(data: Data) {
        if client != nil {
            client!.send(data: data)
        }
    }
    
    public func sendDisconnectionSignal() {
        print("student is leaving the task")
        do {
            let message = try "DISC///" + UIDevice.current.identifierForVendor!.uuidString + "///" + DbTableSettings.retrieveName() + "///"
            if client != nil {
                client!.send(string: message)
            }
        } catch let error {
            print(error)
        }
    }
    
    fileprivate func readAndStoreQuestion(prefix: String, typeOfQuest: String, prefixData: [UInt8]) {
        if prefix.components(separatedBy: ":").count > 1 {
            let imageSize:Int? = Int(prefix.components(separatedBy: ":")[1])
            var textSizeString = prefix.components(separatedBy: ":")[2]
            textSizeString = String(textSizeString.filter { "01234567890.".contains($0) })
            let textSize:Int? = Int(textSizeString)
            
            var dataText = [UInt8]()
            while dataText.count < textSize ?? 0 {
                dataText += self.client!.read(textSize! - dataText.count) ?? [UInt8]()
            }
            print(imageSize!)
            
            var dataImage = [UInt8]()
            while dataImage.count < imageSize ?? 0 {
                dataImage += self.client!.read(imageSize! - dataImage.count) ?? [UInt8]()
            }
            print("Image size actually read:" + String(dataImage.count))
            let dataTextString = String(bytes: dataText, encoding: .utf8) ?? "oops, problem in readAndStoreQuestion: dataText to string yields nil"
            if dataTextString.contains("oops") {
                DbTableLogs.insertLog(log: dataTextString)
            }
            print(dataTextString)
            var questionID = -1
            do {
                if typeOfQuest.range(of: "MULTQ") != nil {
                    let questionMult = DataConversion.bytesToMultq(textData: dataText, imageData: dataImage)
                    questionID = questionMult.ID
                    if questionMult.Question != "error" {
                        try DbTableQuestionMultipleChoice.insertQuestionMultipleChoice(Question: questionMult)
                    }
                } else if typeOfQuest.range(of: "SHRTA") != nil {
                    let questionShrt = DataConversion.bytesToShrtaq(textData: dataText, imageData: dataImage)
                    questionID = questionShrt.ID
                    if questionShrt.Question != "error" {
                        try DbTableQuestionShortAnswer.insertQuestionShortAnswer(Question: questionShrt)
                    }
                }
            } catch let error {
                print(error)
            }
        } else {
            DbTableLogs.insertLog(log: "error reading questions: prefix not in correct format or buffer truncated")
            print("error reading questions: prefix not in correct format or buffer truncated")
        }
    }
    
    func stopConnection() {
        if self.client != nil {
            self.client!.close()
        }
    }
    
    func startConnection() {
        DispatchQueue.global(qos: .utility).async {
            self.connectToServer()
        }
    }
    
    fileprivate func displayInstructions(instructionIndex: Int) {
        DispatchQueue.main.async {
            switch instructionIndex {
            case 0:
                self.classroomActivityViewController?.InstructionsLabel.text = NSLocalizedString("AND CONNECT TO THE RIGHT WIFI NETWORK", comment: "instruction NO NETWORK after the KEEP CALM")
            case 1:
                self.classroomActivityViewController?.InstructionsLabel.text = NSLocalizedString("AND WAIT FOR NEXT QUESTION", comment: "instruction after the KEEP CALM")
            default:
                self.classroomActivityViewController?.InstructionsLabel.text = NSLocalizedString("AND RESTART THE CLASSROOM ACTIVITY (but before, check that you have the right IP address in settings)", comment: "instruction after the KEEP CALM if connection failed")
            }
        }
    }
    
    fileprivate func currentSSIDs() -> [String] {
        guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
            return []
        }
        return interfaceNames.flatMap { name in
            guard let info = CNCopyCurrentNetworkInfo(name as CFString) as? [String:AnyObject] else {
                return nil
            }
            guard let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                return nil
            }
            return ssid
        }
    }
}
