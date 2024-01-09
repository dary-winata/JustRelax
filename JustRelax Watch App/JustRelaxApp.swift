//
//  JustRelaxApp.swift
//  JustRelax Watch App
//
//  Created by dary winata nugraha djati on 04/05/23.
//

import SwiftUI

@main
struct JustRelax_Watch_AppApp: App {
//    @StateObject var appState = 
    @StateObject var scheduleManager = ScheduleManager()
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                HomeView()
            }.environmentObject(scheduleManager)
        }
    }
}
