//
//  DateMateApp.swift
//  DateMate
//
//  Created by ajay Yadav on 10/11/24.
//

import SwiftUI
import FirebaseCore

@main
struct DateMateApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            OnBoardingView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("Firebase Configured!")
        return true
    }
}
