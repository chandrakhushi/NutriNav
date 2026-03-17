//
//  NutriNavApp.swift
//  NutriNav
//
//  Created by AI Developer
//

import SwiftUI

@main
struct NutriNavApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("appTheme") private var appTheme: Int = 0 // 0: System, 1: Light, 2: Dark
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appTheme == 1 ? .light : (appTheme == 2 ? .dark : nil))
        }
    }
}

