//
//  OnboardingHealthKitView.swift
//  NutriNav
//
//  Step 4: Requesting HealthKit Setup
//

import SwiftUI

struct OnboardingHealthKitView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToNext = false
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.primaryBackground.ignoresSafeArea()
            
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Icon Header
                ZStack {
                    Circle()
                        .fill(Color.primaryAccent.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "heart.square.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "FF2D55")) // Apple Health pink color
                }
                
                // Text Description
                VStack(spacing: Spacing.md) {
                    Text("Sync Apple Health")
                        .font(.heading1)
                        .foregroundColor(.textPrimary)
                    
                    Text("Allow NutriNav to read your steps, workouts, and active calories. This keeps your goals strictly tailored to your activity.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: Spacing.md) {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        PrimaryButton(
                            title: "Allow Access",
                            action: {
                                HapticFeedback.success()
                                requestHealthKitPermissions()
                            },
                            icon: "heart.text.square.fill"
                        )
                        
                        Button(action: {
                            HapticFeedback.selection()
                            navigateToNext = true
                        }) {
                            Text("Not Now")
                                .font(.button)
                                .foregroundColor(.textSecondary)
                                .padding(.vertical, Spacing.sm)
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToNext) {
            OnboardingNotificationsView()
        }
    }
    
    private func requestHealthKitPermissions() {
        isLoading = true
        Task {
            do {
                try await appState.healthKitService.requestAuthorization()
                await MainActor.run {
                    appState.healthKitService.startObserving()
                    isLoading = false
                    navigateToNext = true
                }
            } catch {
                await MainActor.run {
                    print("HealthKit setup failed: \(error)")
                    isLoading = false
                    navigateToNext = true
                }
            }
        }
    }
}
