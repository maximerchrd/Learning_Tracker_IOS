//
//  MultipeerCommunication.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 25.04.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//
/*
 
 protocol used for communication with MultipeerConnectivity:
 
 1. Select the channel on which you want to communicate. This corresponds to the index in the services array.
 2. When device connected to wifi network (master) connects with new peer(slave): send ACCEPTED/// if max number of devices not reached
    or NOTACCEPTED/// if max number reached.
 3. IF master accepted slave: slave sends: connection string (CONN///etcetera) with personal prefix (FORWARD///PERSONALID///CONN///ETC)
        save the slave unique id and corresponding peer id in an array
    ELSE slave tries next service type
 4. RECEIVE from computer: forward to right peers (from unique id matching peer id)
 RECEIVE from peer: forward to computer with personal prefix
 5. Synchronize list of questions present on device with all slaves.
 6. on disconnection from master: search for new master
    on disconnection from server: stop advertising
 
 */
import Foundation
import MultipeerConnectivity

protocol MultipeerCommunicationDelegate {
    
    func connectedDevicesChanged(manager : MultipeerCommunication, connectedDevices: [String])
    func colorChanged(manager : MultipeerCommunication, colorString: String)
    
}


class MultipeerCommunication : NSObject {
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    private let MPComServiceType = ["koeko-app-1","koeko-app-2","koeko-app-3","koeko-app-4","koeko-app-5","koeko-app-6","koeko-app-7","koeko-app-8","koeko-app-9","koeko-app-10"]
    
    private let MPComPeerId = MCPeerID(displayName: UIDevice.current.name)
    private var serviceAdvertiser: MCNearbyServiceAdvertiser
    private var serviceBrowser: MCNearbyServiceBrowser
    
    var delegate : MultipeerCommunicationDelegate?
    
    var peerFound = false
    var serviceNamesArray = [String]()
    var currentServiceIndex = 0
    var numberOfPeers = 0
    let maxPeers = 5
    var masterPeer = MCPeerID(displayName: UIDevice.current.name)
    var pendingAnswer = "none"
    
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
            sendToPeer(data: message.data(using: .utf8)!, peerID: masterPeer)
        } catch let error {
            print(error)
        }
    }
    
    public func sendDisconnectionSignal() {
        print("student is leaving the task")
        do {
            let message = try "DISC///" + UIDevice.current.identifierForVendor!.uuidString + "///" + DbTableSettings.retrieveName() + "///"
            sendToPeer(data: message.data(using: .utf8)!, peerID: masterPeer)
        } catch let error {
            print(error)
        }
    }
    
    func sendToAll(data : Data) {
        NSLog("%@", "send message to \(session.connectedPeers.count) peers")
        
        if session.connectedPeers.count > 0 {
            do {
                try self.session.send(data, toPeers: session.connectedPeers, with: .reliable)
            }
            catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
    }
    
    func sendToPeer(data : Data, peerID: MCPeerID) {
        NSLog("%@", "send message to peer")
        let peerListOfSingleId = [peerID]
        if session.connectedPeers.count > 0 {
            do {
                try self.session.send(data, toPeers: peerListOfSingleId, with: .reliable)
            }
            catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
    }
    
    func sendQuestionsToPeer(uuid: String) {
        NSLog("%@", "send message to \(session.connectedPeers.count) peers")
        do {
            //get the peerID from the uuid
            let peerID = AppDelegate.wifiCommunicationSingleton?.peeridUidDictionary[uuid] ?? MCPeerID(displayName: UIDevice.current.name)
            let peerListOfSingleId = [peerID]
            
            //build the list of questions to send
            let MCQs = try DbTableQuestionMultipleChoice.getArrayOfAllQuestionsMultipleChoiceIDs()
            let SHRTAQs = try DbTableQuestionShortAnswer.getArrayOfAllQuestionsShortAnswersIDs()
            let deviceQuestionsIDs = AppDelegate.questionsOnDevices[uuid]
            
            //send the new questions
            for questionID in MCQs {
                if !(deviceQuestionsIDs?.contains(questionID))!{
                    let data = DataConversion.dataFromMultipleChoiceQuestionID(questionID: questionID)
                    try self.session.send(data, toPeers: peerListOfSingleId, with: .reliable)
                }
            }
            
            for questionID in SHRTAQs {
                if !(deviceQuestionsIDs?.contains(questionID))! {
                    let data = DataConversion.dataFromShortAnswerQuestionID(questionID: questionID)
                    try self.session.send(data, toPeers: peerListOfSingleId, with: .reliable)
                }
            }
        } catch let error {
            NSLog("%@", "Error for sending: \(error)")
        }
    }

    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: MPComPeerId, discoveryInfo: nil, serviceType: MPComServiceType[0])
        self.serviceBrowser = MCNearbyServiceBrowser(peer: MPComPeerId, serviceType: MPComServiceType[0])
        
        super.init()
    }
    
    func connectToPeers() {
        let serviceName = self.MPComServiceType[DbTableSettings.retrieveServiceIndex()]

        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: self.MPComPeerId, discoveryInfo: nil, serviceType: serviceName)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: self.MPComPeerId, serviceType: serviceName)
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    func stopAdvertisingAndBrowsing() {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.MPComPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
}

extension MultipeerCommunication : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
        if AppDelegate.isFirstLayer {
            DispatchQueue.global(qos: .utility).async {
                Thread.sleep(forTimeInterval: 1)            //wait for peer to do some stuffs (find a better solution later)
                if self.numberOfPeers <= self.maxPeers {
                    print("sending accepted to peer")
                    self.sendToPeer(data: "ACCEPTED///".data(using: .utf8)!, peerID: peerID)
                } else {
                    self.sendToPeer(data: "NOTACCEPTED///".data(using: .utf8)!, peerID: peerID)
                }
            }
        }
    }
}

extension MultipeerCommunication : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
    
}

extension MultipeerCommunication : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state)")
        //if we are disconnected from master, try to find new master
        if peerID == masterPeer && state == MCSessionState.notConnected {
            currentServiceIndex = 0
            self.connectToPeers()
        }
        
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        var prefix = ""
        if data.count < 80 {
            prefix = String(data: data.subdata(in: 0..<data.count), encoding: .utf8)!
        } else {
            prefix = String(data: data.subdata(in: 0..<80), encoding: .utf8)!
        }
        print(prefix)
        let typeID = prefix.components(separatedBy: ":")[0]
        
        if typeID.range(of:"MULTQ") != nil {
            DataConversion.storeQuestionFromData(typeOfQuest: typeID, questionData: data, prefix: prefix)
        } else if typeID.range(of:"SHRTA") != nil {
            DataConversion.storeQuestionFromData(typeOfQuest: typeID, questionData: data, prefix: prefix)
        } else if typeID.range(of:"QID") != nil {
            ReceptionProtocol.receivedQID(prefix: prefix)
        } else if typeID.range(of:"EVAL") != nil {
            ReceptionProtocol.receivedEVAL(prefix: prefix)
        } else if typeID.range(of:"UPDEV") != nil {
            ReceptionProtocol.receivedUPDEV(prefix: prefix)
        } else if typeID.range(of:"CORR") != nil {
            ReceptionProtocol.receivedCORR(prefix: prefix)
        } else if typeID.range(of:"TEST") != nil {
            ReceptionProtocol.receivedTESTFromPeer(data: data)
        } else if typeID.range(of:"TESYN") != nil {
            ReceptionProtocol.receivedTESYNFromPeer(data: data)
        } else if typeID.range(of:"NOTACCEPTED") != nil {
            self.serviceAdvertiser.stopAdvertisingPeer()
            self.serviceBrowser.stopBrowsingForPeers()
            currentServiceIndex = (currentServiceIndex + 1) % 10
            connectToPeers()
        } else if typeID.range(of:"ACCEPTED") != nil {
            masterPeer = peerID
            var connectionString = "problem retrieving name from DB"
            do {
                let MCQIDsList = try DbTableQuestionMultipleChoice.getAllQuestionsMultipleChoiceIDs()
                let SHRTAQIDsList = try DbTableQuestionShortAnswer.getAllQuestionsShortAnswersIDs()
                try connectionString = "CONN" + "///"
                    + UIDevice.current.identifierForVendor!.uuidString + "///"
                    + DbTableSettings.retrieveName() + "///"
                    + MCQIDsList + "|" + SHRTAQIDsList
            } catch let error {
                print(error)
                DbTableLogs.insertLog(log: error.localizedDescription)
            }
            self.sendToPeer(data: connectionString.data(using: .utf8)!, peerID: masterPeer)
        } else if typeID.range(of:"CONN") != nil {
            ReceptionProtocol.receivedCONNFromPEER(prefix: prefix, data: data, peerID: peerID)
            let forwardPrefix = "FORWARD///" + UIDevice.current.identifierForVendor!.uuidString + "///"
            let dataToForward = forwardPrefix.data(using: .utf8)! + data
            AppDelegate.wifiCommunicationSingleton?.sendData(data: dataToForward)
        } else if prefix.contains("///") {
            let forwardPrefix = "FORWARD///" + UIDevice.current.identifierForVendor!.uuidString + "///"
            let dataToForward = forwardPrefix.data(using: .utf8)! + data
            AppDelegate.wifiCommunicationSingleton?.sendData(data: dataToForward)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
}
