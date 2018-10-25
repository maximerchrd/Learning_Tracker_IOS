//
//  AppDelegate.swift
//  Learning_Tracker_IOS
//
//  Created by Maxime Richard on 22.02.18.
//  Copyright © 2018 Maxime Richard. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    static var wifiCommunicationSingleton: WifiCommunication?
    var disconnectionDetection = 0
    static var questionsOnDevices = [String:[String]]()
    static var activeTest = Test()
    static var testMode = ""//testReconnection"
    var orientationLock = UIInterfaceOrientationMask.all
    static var disconnectionSignalWithoutConnectionYet = ""
    static var locked = false
    static var testConnection = 0
    static var QRCode = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        GlobalDBManager.createTables()
        application.isIdleTimerDisabled = true
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        if AppDelegate.wifiCommunicationSingleton != nil {
            AppDelegate.wifiCommunicationSingleton?.sendDisconnectionSignal()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        if (DidUserPressLockButton()) {
            print("User pressed lock button")
            if AppDelegate.wifiCommunicationSingleton != nil {
                AppDelegate.wifiCommunicationSingleton?.sendDisconnectionSignal(additionalInformation: "locked")
                AppDelegate.locked = true
                AppDelegate.wifiCommunicationSingleton?.client?.close()
            }
        } else {
            print("user pressed home button")
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if AppDelegate.wifiCommunicationSingleton != nil {
            AppDelegate.wifiCommunicationSingleton?.connectToServer() //we need it because we lose the connection when locking the device. Once this problem solved, we can probably get rid of it
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //START code used to force screen orientation
    struct AppUtility {
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = orientation
            }
        }
        
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation: UIInterfaceOrientation) {
            self.lockOrientation(orientation)
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        }
    }
    //END code used to force screen orientation

    //Code to know when sending disconnection signal
    private func DidUserPressLockButton() -> Bool {
        let oldBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = oldBrightness + (oldBrightness <= 0.01 ? (0.01) : (-0.01))
        return oldBrightness != UIScreen.main.brightness
    }
}

