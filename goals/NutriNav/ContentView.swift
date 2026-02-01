//
//  ContentView.swift
//  NutriNav
//
//  Root view that handles navigation between auth, onboarding and main app
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        Group {
            if !appState.isAuthenticated {
                NavigationStack {
                    SignInView()
                }
            } else if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                NavigationStack {
                    OnboardingWelcomeView()
                }
            }
        }
    }
}

