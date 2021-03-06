//
//  ClassroomActivityViewController.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 24.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import Foundation
import UIKit

class ClassroomActivityViewController: UIViewController {
    static var navQuestionMultipleChoiceViewController: QuestionMultipleChoiceViewController?
    static var navQuestionShortAnswerViewController: QuestionShortAnswerViewController?
    static var navTestTableViewController: TestTableViewController?
    static var navGameViewController: GameViewController?
    
    static var classroomActivityIsVisible = false

    @IBOutlet weak var InstructionsLabel: UILabel!
    @IBOutlet weak var RestartConnectionButton: UIButton!
    @IBOutlet weak var CrownImageView: UIImageView!
    var stopConnectionButton = true
    var QRCode: String = ""

    @IBAction func scanQRCode(_ sender: Any) {
        if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScanQRCodeViewController") as? ScanQRCodeViewController {
            if let navigator = self.navigationController {
                navigator.pushViewController(newViewController, animated: true)
            } else {
                NSLog("%@", "Error trying to show Scan QR code: the view controller wasn't pushed on a navigation controller")
            }
        }
    }

    public func showMultipleChoiceQuestion(question: QuestionMultipleChoice, isCorr: Bool, directCorrection: Int = 0) {
        if ClassroomActivityViewController.classroomActivityIsVisible {
            ClassroomActivityViewController.navGameViewController = nil
        }
        if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QuestionMultipleChoiceViewController") as? QuestionMultipleChoiceViewController {
            if let navigator = self.navigationController {
                newViewController.questionMultipleChoice = question
                newViewController.isCorrection = isCorr
                newViewController.directCorrection = directCorrection
                navigator.pushViewController(newViewController, animated: true)
            } else {
                NSLog("%@", "Error trying to show Multiple choice question: the view controller wasn't pushed on a navigation controller")
            }
        }
    }

    public func showShortAnswerQuestion(question: QuestionShortAnswer, isCorr: Bool, directCorrection: Int = 0) {
        if ClassroomActivityViewController.classroomActivityIsVisible {
            ClassroomActivityViewController.navGameViewController = nil
        }
        if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QuestionShortAnswerViewController") as? QuestionShortAnswerViewController {
            if let navigator = navigationController {
                newViewController.questionShortAnswer = question
                newViewController.isCorrection = isCorr
                newViewController.directCorrection = directCorrection
                navigator.pushViewController(newViewController, animated: true)
            } else {
                NSLog("%@", "Error trying to show Short answer question: the view controller wasn't pushed on a navigation controller")
            }
        }
    }

    public func showTest(test: Test, directCorrection: Int = 0, testMode: Int = 0) {
        if ClassroomActivityViewController.classroomActivityIsVisible {
            ClassroomActivityViewController.navGameViewController = nil
        }
        if test.testMap.count > 0 {
            if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "testTable") as? TestTableViewController {
                AppDelegate.activeTest = test
                newViewController.directCorrection = directCorrection
                if let navigator = navigationController {
                    navigator.pushViewController(newViewController, animated: true)
                }
            }
        } else {
            let error = "Problem trying to display test: no question ID received"
            print(error)
            DbTableLogs.insertLog(log: error)
        }
    }

    public func showHTML(url: URL) {
        if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "displayWebContent") as? DisplayWebContentController {
            if let navigator = navigationController {
                newViewController.url = url
                navigator.pushViewController(newViewController, animated: true)
            }
        }
    }
    
    public func showGame(gameView: GameView) {
        if let newViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "gameViewStoryboard") as? GameViewController {
            if let navigator = navigationController {
                newViewController.gameView = gameView
                navigator.pushViewController(newViewController, animated: true)
            }
        }
    }
    
    @objc func goBackToGame() {
        if let navigator = navigationController {
            if ClassroomActivityViewController.navGameViewController != nil {
                navigator.pushViewController(ClassroomActivityViewController.navGameViewController!, animated: true)
            } else {
                let error = "Problem going back to question MC: View Controller is unexpectedly nil"
                print(error)
                DbTableLogs.insertLog(log: error)
            }
        }
    }

    @objc func goBackToQuestionMultChoice() {
        if let navigator = navigationController {
            if ClassroomActivityViewController.navQuestionMultipleChoiceViewController != nil {
                navigator.pushViewController(ClassroomActivityViewController.navQuestionMultipleChoiceViewController!, animated: true)
            } else {
                let error = "Problem going back to question MC: View Controller is unexpectedly nil"
                print(error)
                DbTableLogs.insertLog(log: error)
            }
        }
    }

    @objc func goBackToQuestionShortAnswer() {
        if let navigator = navigationController {
            if ClassroomActivityViewController.navQuestionShortAnswerViewController != nil {
                navigator.pushViewController(ClassroomActivityViewController.navQuestionShortAnswerViewController!, animated: true)
            } else {
                let error = "Problem going back to SHRTAQ: View Controller is unexpectedly nil"
                print(error)
                DbTableLogs.insertLog(log: error)
            }
        }
    }

    @objc func goBackToTest() {
        if let navigator = navigationController {
            if ClassroomActivityViewController.navTestTableViewController != nil {
                navigator.pushViewController(ClassroomActivityViewController.navTestTableViewController!, animated: true)
            } else {
                let error = "Problem going back to TEST: View Controller is unexpectedly nil"
                print(error)
                DbTableLogs.insertLog(log: error)
            }
        }
    }

    @IBAction func restartConnection(_ sender: Any) {
        if (AppDelegate.testMode.contains("testReconnection")) {
            var i = 0
            while (i < 3) {
                i = i + 1
                AppDelegate.wifiCommunicationSingleton!.stopConnection()
                Thread.sleep(forTimeInterval: 3)
                AppDelegate.wifiCommunicationSingleton!.startConnection()
            }
        } else {
            if stopConnectionButton {
                AppDelegate.wifiCommunicationSingleton!.stopConnection()
                stopConnectionButton = false
                RestartConnectionButton.setTitle(NSLocalizedString("Start Connection", comment: "Button in Class activity"), for: .normal)
            } else {
                AppDelegate.wifiCommunicationSingleton!.startConnection()
                stopConnectionButton = true
                RestartConnectionButton.setTitle(NSLocalizedString("Stop Connection", comment: "Button in Class activity"), for: .normal)
            }
        }
    }
    
    public func setButtonToStart() {
        if stopConnectionButton {
            stopConnectionButton = false
            RestartConnectionButton.setTitle(NSLocalizedString("Start Connection", comment: "Button in Class activity"), for: .normal)
        }
    }

    public func stopConnectionAlerting() {
        AppDelegate.wifiCommunicationSingleton!.stopConnection()
        stopConnectionButton = false
        RestartConnectionButton.setTitle(NSLocalizedString("Start Connection", comment: "Button in Class activity"), for: .normal)
        let alert = UIAlertController(title: NSLocalizedString("Oops!", comment: "pop up if receiving problem"), message: NSLocalizedString("We had a problem receiving some data. Try to reconnect.", comment: "error with data transfer"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if AppDelegate.wifiCommunicationSingleton == nil {
            AppDelegate.wifiCommunicationSingleton = WifiCommunication(classroomActivityViewControllerArg: self)
        } else {
            AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController = self
        }
        AppDelegate.wifiCommunicationSingleton!.connectToServer()

        //CrownImageView.animationImages = [#imageLiteral(resourceName: "crown_1"), #imageLiteral(resourceName: "crown_2"), #imageLiteral(resourceName: "crown_3"), #imageLiteral(resourceName: "crown_4"), #imageLiteral(resourceName: "crown_5"), #imageLiteral(resourceName: "crown_6"), #imageLiteral(resourceName: "crown_7")]
        //CrownImageView.animationDuration = 1
    }

    override func viewDidAppear(_ animated: Bool) {
        if ClassroomActivityViewController.navGameViewController != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Back to game", comment: "Back to game button") + " >", style: .plain, target: self, action: #selector(goBackToGame))
        } else if ClassroomActivityViewController.navQuestionMultipleChoiceViewController != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Back to question", comment: "Back to question button") + " >", style: .plain, target: self, action: #selector(goBackToQuestionMultChoice))
        } else if ClassroomActivityViewController.navQuestionShortAnswerViewController != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Back to question", comment: "Back to question button") + " >", style: .plain, target: self, action: #selector(goBackToQuestionShortAnswer))
        } else if ClassroomActivityViewController.navTestTableViewController != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Back to test", comment: "Back to test button") + " >", style: .plain, target: self, action: #selector(goBackToTest))
        } else {
            navigationItem.rightBarButtonItem = nil
        }

        if AppDelegate.testConnection != 0 {
            DispatchQueue.global(qos: .utility).async {
                Thread.sleep(forTimeInterval: 1.8)
                if let navigator = self.navigationController {
                    DispatchQueue.main.async {
                        navigator.popViewController(animated: false)
                    }
                }
            }
        }

        ClassroomActivityViewController.launchFromQrCode(viewController: self)
        
        ClassroomActivityViewController.classroomActivityIsVisible = true
    }
    
    static func launchFromQrCode(viewController: UIViewController) {
        if AppDelegate.QRCode != "" {
            if AppDelegate.QRCode.components(separatedBy: ":").count == 4 {
                //launch question or test read by QR Code scanner
                var questionMultipleChoice = QuestionMultipleChoice()
                var questionShortAnswer = QuestionShortAnswer()
                let idGlobal = Int64(AppDelegate.QRCode.components(separatedBy: ":")[0]) ?? 0
                let directCorrection = Int(AppDelegate.QRCode.components(separatedBy: ":")[2]) ?? 0
                if checkIfResourceAvailable(resourceId: idGlobal) {
                    if idGlobal < 0 {
                        let test = Test()
                        test.testID = String(-idGlobal)
                        test.testName = DbTableTests.getNameFromTestID(testID: -idGlobal)
                        test.questionIDs = DbTableTests.getQuestionIds(testName: test.testName)
                        test.testMap = DbTableRelationQuestionQuestion.getTestMapForTest(test: test.testName)
                        test.parseMedalsInstructions(instructions: DbTableTests.getMedalsInstructionsFromTestID(testID: -idGlobal))
                        
                        DispatchQueue.main.async {
                            AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showTest(test: test, directCorrection: directCorrection, testMode: 0)
                        }
                    } else {
                        do {
                            questionMultipleChoice = try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: idGlobal)
                            
                            if questionMultipleChoice.question.count > 0 && questionMultipleChoice.question != "none" {
                                AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showMultipleChoiceQuestion(question: questionMultipleChoice, isCorr: false, directCorrection: directCorrection)
                            } else {
                                questionShortAnswer = try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: idGlobal)
                                AppDelegate.wifiCommunicationSingleton?.classroomActivityViewController?.showShortAnswerQuestion(question: questionShortAnswer, isCorr: false, directCorrection: directCorrection)
                            }
                        } catch let error {
                            print(error)
                        }
                    }
                } else {
                    var transferable = ClientToServerTransferable(prefix: ClientToServerTransferable.requestPrefix)
                    transferable.optionalArgument1 = UIDevice.current.identifierForVendor!.uuidString
                    transferable.optionalArgument2 = AppDelegate.QRCode.components(separatedBy: ":")[0]
                    AppDelegate.wifiCommunicationSingleton?.sendData(data: transferable.getTransferableData())
                }
            } else {
                let ac = UIAlertController(title: NSLocalizedString("Error Reading QR Code", comment: "Error prompted when Reading QR Code"), message: NSLocalizedString("The scanned QR Code is not recognized by Koeko.", comment: "The scanned QR Code is not recognized by Koeko."), preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                viewController.present(ac, animated: true)
            }
            AppDelegate.QRCode = ""
        }
    }

    fileprivate static func checkIfResourceAvailable(resourceId: Int64) -> Bool {
        do {
            if resourceId < 0 {
                if DbTableTests.getNameFromTestID(testID: resourceId) == "" {
                    return false
                } else {
                    return true
                }
            } else {
                if try DbTableQuestionMultipleChoice.retrieveQuestionMultipleChoiceWithID(globalID: resourceId).question == "none" {
                    if try DbTableQuestionShortAnswer.retrieveQuestionShortAnswerWithID(globalID: resourceId).question == "none" {
                        return false
                    } else {
                        return true
                    }
                } else {
                    return true
                }
            }
        } catch let error {
            print(error)
            return false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.isMovingFromParentViewController {
            AppDelegate.wifiCommunicationSingleton!.stopConnection()
            
            if ClassroomActivityViewController.navTestTableViewController != nil {
                timer.invalidate()
                timerLabel.text = ""
            }
        }
        
        ClassroomActivityViewController.classroomActivityIsVisible = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension UIImageView {
    func setImageColor(color: UIColor) {
        let templateImage = self.image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
    }
}

extension UIImage {
    func maskWithColor(color: UIColor) -> UIImage? {
        let maskImage = cgImage!

        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!

        context.clip(to: bounds, mask: maskImage)
        context.setFillColor(color.cgColor)
        context.fill(bounds)

        if let cgImage = context.makeImage() {
            let coloredImage = UIImage(cgImage: cgImage)
            return coloredImage
        } else {
            return nil
        }
    }
}
