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
import CocoaAsyncSocket

class WifiCommunication: NSObject, GCDAsyncUdpSocketDelegate {
    let PORT_NUMBER = 9090
    var host = "xxx.xxx.x.xxx"
    var client: TCPClient?
    var classroomActivityViewController: ClassroomActivityViewController?
    var pendingAnswer = "none"
    var peeridUidDictionary = [String:MCPeerID]()
    var socket:GCDAsyncUdpSocket!
    
    init(classroomActivityViewControllerArg: ClassroomActivityViewController) {
        classroomActivityViewController = classroomActivityViewControllerArg
    }
    
    public func connectToServer() {
        //change the thread priority if we come back from lock to be sure to send disconnection before user quits app if ever
        var threadProperty = DispatchQoS.QoSClass.utility
        if AppDelegate.locked {
            threadProperty = DispatchQoS.QoSClass.userInteractive
        }
        DispatchQueue.global(qos: threadProperty).async {
            //reinitialize ip address to check if we get it from automatic connection
            self.host = "xxx.xxx.x.xxx"
            
            //first check if we are connected to a wifi network
            if self.currentSSIDs().count == 0 {
                self.displayInstructions(instructionIndex: 0)
            } else {
                //try to connect automatically
                var automaticConnection = 1
                var automaticConnectionSuccess = true
                do {
                    automaticConnection = try DbTableSettings.retrieveAutomaticConnection()
                } catch let error {
                    print(error)
                }
                
                if automaticConnection == 1 && !AppDelegate.locked {
                    self.listenForIPThroughUDP()
                    for _ in 0..<10 {
                        Thread.sleep(forTimeInterval: 0.5)
                        if self.host != "xxx.xxx.x.xxx" {
                            break
                        }
                    }
                    if self.host == "xxx.xxx.x.xxx" {
                        do { try self.host = DbTableSettings.retrieveMaster() } catch {}
                        self.displayInstructions(instructionIndex: 3)
                        automaticConnectionSuccess = false
                        self.socket.close()
                    }
                } else {
                    do { try self.host = DbTableSettings.retrieveMaster() } catch {}
                }
                AppDelegate.locked = false
                
                self.client = TCPClient(address: self.host, port: Int32(self.PORT_NUMBER))
                let dataConverter = DataConversion()
                
                //app crashes after around 250 connections in a row
                switch self.client!.connect(timeout: 4) {
                case .success:
                    if AppDelegate.disconnectionSignalWithoutConnectionYet.optionalArgument1 != "" {
                        self.client!.send(data: AppDelegate.disconnectionSignalWithoutConnectionYet.getTransferableData())
                    }
                    switch self.client!.send(data: dataConverter.connection()) {
                    case .success:
                        self.sendResourceIdsOnDevice()
                        if automaticConnectionSuccess {
                            self.displayInstructions(instructionIndex: 1)
                        }
                        DispatchQueue.global(qos: .utility).async {
                            self.listenToServer()
                        }
                    case .failure(let error):
                        if automaticConnectionSuccess {
                            self.displayInstructions(instructionIndex: 2)
                        }
                        print(error)
                    }
                case .failure(let error):
                    if automaticConnectionSuccess {
                        self.displayInstructions(instructionIndex: 2)
                    }
                    if error.localizedDescription.contains("3") {
                        DbTableLogs.insertLog(log: error.localizedDescription + "(could connect to ip but server not running?)")
                        print(error.localizedDescription + "(could connect to ip but server not running?)")
                    } else {
                        DbTableLogs.insertLog(log: error.localizedDescription + "(ip not valid?)")
                        print(error.localizedDescription + "(ip not valid?)")
                    }
                    print(error)
                }
            }
        }
    }

    private func sendResourceIdsOnDevice() {
        do {
            var idsString = try DbTableQuestionMultipleChoice.getAllQuestionsMultipleChoiceIDsAndHash()
            idsString += try DbTableQuestionShortAnswer.getAllQuestionsShortAnswersIDsandHash()

            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                for var url in fileURLs {
                    idsString.append(url.lastPathComponent)
                }
            } catch {
                print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
            }

            let jsonEncoder = JSONEncoder()
            let encodedArray = try jsonEncoder.encode(idsString)
            
            let transferable = ClientToServerTransferable(prefix: ClientToServerTransferable.resourceIdsPrefix, optionalArgument: UIDevice.current.identifierForVendor!.uuidString)
            transferable.fileBytes = Array(encodedArray)
            let transferableBytes = transferable.getTransferableBytes()
            self.client!.send(data: transferableBytes)
        } catch let error {
            print(error)
        }
    }
    
    public func listenToServer() {
        var prefix = "not initialized"
        var ableToRead = true
        
        while (self.client != nil && self.client?.fd != nil && ableToRead) {
            var timeout = 40000
            if AppDelegate.testConnection != 0 {
                timeout = 1
            }
            let data = readDataIntoArray(expectedSize: 80, timeout: timeout)
            if data != nil {
                prefix = String(bytes: data, encoding: .utf8) ?? "oops, problem in listenToServer(): prefix is nil"
                if prefix.contains("oops, problem in listenToServer(): prefix is nil") {
                    DbTableLogs.insertLog(log: prefix)
                    print(prefix)
                    sendDisconnectionSignal(additionalInformation: "close-connection")
                    DispatchQueue.main.async {
                        AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.stopConnectionAlerting()
                    }
                    break
                }
                print(prefix)

                let objectName = TransferPrefix.getObjectName(prefix: prefix)
                let dataSize = TransferPrefix.getSize(prefix: prefix)

                if TransferPrefix.isResource(prefix: prefix) {
                    let resourceData = self.readDataIntoArray(expectedSize: dataSize)
                    ReceptionProtocol.receivedResource(objectName: objectName, resourceData: resourceData)
                } else if TransferPrefix.isStateUpdate(prefix: prefix) {
                    let resourceData = self.readDataIntoArray(expectedSize: dataSize)
                    ReceptionProtocol.receivedStateUpdate(dataSize: dataSize, objectName: objectName, resourceData: resourceData)
                } else if TransferPrefix.isFile(prefix: prefix) {
                    let resourceData = self.readDataIntoArray(expectedSize: dataSize)
                    let wholeObjectName = TransferPrefix.getWholeObjectName(prefix: prefix)
                    ReceptionProtocol.receivedFile(fileSize: dataSize, objectName: wholeObjectName, resourceData: resourceData)
                } else if TransferPrefix.isOther(prefix: prefix) {
                    let resourceData = self.readDataIntoArray(expectedSize: dataSize)
                    print("Received 'Other' Type of Data but it's not yet supported")
                } else {
                    print("message received but prefix not supported")
                    stopConnection()
                }
            } else {
                ableToRead = false
            }
        }
    }
    
    public func sendAnswerToServer(answers: [String], answer: String, globalID: Int64, questionType: String, timeSpent: Double) {
        pendingAnswer = answer
        var message = ""
        do {
            var question = ""
            if questionType == "ANSW0" {
                let questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: globalID)
                question = questionMultipleChoice.question
            } else if questionType == "ANSW1" {
                let questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: globalID)
                question = questionShortAnswer.question
            }
            let name = try DbTableSettings.retrieveName()
            var answerObject = Answer(studenDeviceId: UIDevice.current.identifierForVendor!.uuidString,
                    studentName: name, questionType: questionType, questionId: String(globalID), question: question,
                    timeSpent: timeSpent, answers: answers)
            var encoder = JSONEncoder()
            var encodedData = try encoder.encode(answerObject)
            var transferable = ClientToServerTransferable(prefix: ClientToServerTransferable.answerPrefix)
            transferable.fileBytes = Array(encodedData)
            sendData(data: transferable.getTransferableData())
        } catch let error {
            print(error)
        }
    }
    
    public func sendData(data: Data) {
        if client != nil {
            client!.send(data: data)
        } else {
            print("client is nil when trying to send Data")
        }
    }
    
    public func sendDisconnectionSignal(additionalInformation: String = "") {
        print("student is leaving the task")
        do {
            var transferable = ClientToServerTransferable(prefix: ClientToServerTransferable.disconnectionPrefix)
            transferable.optionalArgument1 = UIDevice.current.identifierForVendor!.uuidString
            transferable.optionalArgument2 = additionalInformation
            transferable.fileBytes = Array(try DbTableSettings.retrieveName().data(using: .utf8) ?? Data())
            AppDelegate.disconnectionSignalWithoutConnectionYet = transferable
            if client != nil {
                sendData(data: transferable.getTransferableData())
                Thread.sleep(forTimeInterval: 0.7)
                AppDelegate.disconnectionSignalWithoutConnectionYet = ClientToServerTransferable(prefix: ClientToServerTransferable.disconnectionPrefix)
            }
        } catch let error {
            print(error)
        }
    }
    
    func stopConnection() {
        if self.client != nil {
            sendDisconnectionSignal(additionalInformation: "close-connection")
            self.client!.close()            //sets the file descriptor to nil
            displayInstructions(instructionIndex: 4)
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
                self.classroomActivityViewController?.setButtonToStart()
            case 1:
                self.classroomActivityViewController?.InstructionsLabel.text = NSLocalizedString("AND WAIT FOR NEXT QUESTION", comment: "instruction after the KEEP CALM")
            case 2:
                self.classroomActivityViewController?.InstructionsLabel.text = NSLocalizedString("AND RESTART THE CLASSROOM ACTIVITY (but before, check that you have the right IP address in settings)", comment: "instruction after the KEEP CALM if connection failed")
                self.classroomActivityViewController?.setButtonToStart()
            case 3:
                self.classroomActivityViewController?.InstructionsLabel.text = NSLocalizedString("Automatic Connection Failed", comment: "instruction after the KEEP CALM if automatic connection failed")
                self.classroomActivityViewController?.setButtonToStart()
            case 4:
                self.classroomActivityViewController?.InstructionsLabel.text = NSLocalizedString("We are not connected :-(", comment: "message appearing when we are not connected")
                self.classroomActivityViewController?.setButtonToStart()
            default:
                print("Display instruction not recognized")
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

    public func readDataIntoArray(expectedSize: Int, timeout: Int = 300) -> [UInt8] {
        //read data
        var arrayToFill = [UInt8]()
        var ableToRead = true
        while self.client != nil && self.client?.fd != nil && ableToRead && arrayToFill.count < expectedSize {
            let data = self.client!.read(expectedSize - arrayToFill.count, timeout: timeout)
            if data != nil {
                arrayToFill += data ?? [UInt8]()
            } else {
                ableToRead = false
            }
            if ableToRead == false && arrayToFill.count < expectedSize {
                var errorMessage = ""
                if data == nil {
                    errorMessage = "Reading data, data is nil"
                } else {
                    errorMessage = "We are reading data, we had a problem but data is not nil! WTF!!!"
                }
                errorMessage += "\n self.client: " + String(describing: self.client)
                errorMessage += "\n self.client?.fd:" + String(describing: self.client?.fd)
                print(errorMessage)
            }
        }
        return arrayToFill
    }
    
    //START UDP COMMUNICATION STUFFS
    fileprivate func listenForIPThroughUDP() {
        do {
            if socket == nil {
                socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
            }
            try socket.enableBroadcast(true)
            try socket.bind(toPort: 9346)
            try socket.beginReceiving()
            
        } catch let error {
            print(error)
        }
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        let receivedMessage = String(data: data, encoding: .utf8) ?? "couldn't read message"
        print(receivedMessage)
        
        if receivedMessage.components(separatedBy: "///")[0] == "IPADDRESS" {
            self.host = receivedMessage.components(separatedBy: "///")[1]
            DbTableSettings.setMaster(master: receivedMessage.components(separatedBy: "///")[1])
        }
        socket.close()
    }
    //END UDP COMMUNICATION STUFFS
}
