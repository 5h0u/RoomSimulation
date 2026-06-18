//
//  RoomSimulationApp.swift
//  RoomSimulation
//
//  Created by yamasaki.shotaro on 2026/06/16.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

extension Notification.Name {
    static let usdzSaved = Notification.Name("usdzSaved")
}

@main
struct RoomSimulationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = USDZStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
