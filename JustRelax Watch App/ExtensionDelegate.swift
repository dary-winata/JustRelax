//
//  ExtensionDelegate.swift
//  JustRelax Watch App
//
//  Created by dary winata nugraha djati on 12/05/23.
//

import WatchKit

class ExatensionDelegate : NSObject, WKExtensionDelegate {
//    func applicationDidEnterBackground() {
//        UserDefaults.standard.set(1, forKey: "lastViewIndex")
//    }
    func applicationDidBecomeActive() {
        if let lastAppUrl = UserDefaults.standard.url(forKey: "lastApp") {
            WKExtension.shared().openSystemURL(lastAppUrl)
        }
    }
    
    func handle(_ userActivity: NSUserActivity) {
        print("yang bener")
        if userActivity.activityType == "lastStateView" {
            print("test")
            UserDefaults.standard.set(userActivity.userInfo?["appUrl"], forKey: "lastApp")
        }
    }
}
