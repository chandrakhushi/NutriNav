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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

