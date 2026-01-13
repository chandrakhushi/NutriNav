//
//  ContentView.swift
//  NutriNav
//
//  Root view that handles navigation between auth, onboarding and main app
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var isAuthenticated = false // TODO: Check actual auth status
    
    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else if isAuthenticated {
                NavigationStack {
                    OnboardingWelcomeView()
                }
            } else {
                NavigationStack {
                    LoginView()
                }
            }
        }
    }
}

