//
//  OnboardingNotificationsView.swift
//  NutriNav
//
//  Step 4: Requesting Push Notifications Setup
//

import SwiftUI
import UserNotifications

struct OnboardingNotificationsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
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
                    
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.primaryAccent)
                        .symbolRenderingMode(.multicolor)
                }
                
                // Text Description
                VStack(spacing: Spacing.md) {
                    Text("Stay on Track")
                        .font(.heading1)
                        .foregroundColor(.textPrimary)
                    
                    Text("Enable notifications so we can remind you to log your food and reach your daily water goals. Consistency is key!")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: Spacing.md) {
                    PrimaryButton(
                        title: "Enable Notifications",
                        action: {
                            HapticFeedback.success()
                            requestNotificationPermissions()
                        },
                        icon: "bell.fill"
                    )
                    
                    Button(action: {
                        HapticFeedback.selection()
                        completeOnboarding()
                    }) {
                        Text("Not Now")
                            .font(.button)
                            .foregroundColor(.textSecondary)
                            .padding(.vertical, Spacing.sm)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            DispatchQueue.main.async {
                completeOnboarding()
            }
        }
    }
    
    private func completeOnboarding() {
        appState.hasCompletedOnboarding = true
    }
}
