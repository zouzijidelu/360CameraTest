//
//  AppDelegate.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/4.
//

import UIKit
import Flutter
import flutter_boost
import CocoaLumberjack
import Bugly
import FlutterPluginRegistrant
import INSCameraSDK

let flutterTag = 100

@main
class VRAppDelegate: FlutterAppDelegate {
    
    
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        VRLocalCrashUtil.exceptionLogWithData()
        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
        INSCameraManager.shared().setup()
        window = UIWindow(frame: UIScreen.main.bounds)
        let homeVC = VRHomeVC()
        let nav = UINavigationController(rootViewController: homeVC)
        window?.backgroundColor = .white
        window?.rootViewController = nav
        window?.tag = flutterTag
        window?.makeKeyAndVisible()
        
        //创建代理，做初始化操作
        let delegate = VRBoostDelegate()
        delegate.navigationController = nav
        FlutterBoost.instance().setup(application, delegate: delegate, callback: { engine in
            // 这里是FlutterBoost回调方法,另写它处
            //self.pushFlutterHomeNative()
        })

        return super.application(application,didFinishLaunchingWithOptions: launchOptions)
    }
}

