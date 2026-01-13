//
//  HealthKitComponents.swift
//  NutriNav
//
//  HealthKit UI components - using DesignSystem
//

import SwiftUI

struct ActivitySummaryCard: View {
    let steps: Double
    let activeCalories: Double
    let workouts: [Activity]
    
    var body: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Today's Activity")
                
                HStack(spacing: Spacing.lg) {
                    // Steps
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "figure.walk")
                                .foregroundColor(.primaryAccent)
                            Text("Steps")
                                .font(.label)
                                .foregroundColor(.textSecondary)
                        }
                        Text("\(Int(steps))")
                            .font(.h2) // 20pt, medium
                            .foregroundColor(.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 40)
                    
                    // Active Calories
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.calorieColor)
                            Text("Burned")
                                .font(.label)
                                .foregroundColor(.textSecondary)
                        }
                        Text("\(Int(activeCalories))")
                            .font(.h2) // 20pt, medium
                            .foregroundColor(.textPrimary)
                        Text("kcal")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 40)
                    
                    // Workouts
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .foregroundColor(.proteinColor)
                            Text("Workouts")
                                .font(.label)
                                .foregroundColor(.textSecondary)
                        }
                        Text("\(workouts.count)")
                            .font(.h2) // 20pt, medium
                            .foregroundColor(.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Recent workouts list
                if !workouts.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Recent Workouts")
                            .font(.h3) // 18pt, medium
                            .foregroundColor(.textPrimary)
                            .padding(.top, Spacing.sm)
                        
                        ForEach(workouts.prefix(3)) { workout in
                            HStack {
                                Text(workout.type.emoji)
                                    .font(.system(size: 20))
                                Text(workout.name)
                                    .font(.input) // 16pt, regular
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Text("\(Int(workout.duration / 60))m")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                                Text("\(Int(workout.caloriesBurned)) kcal")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                    }
                }
            }
        }
    }
}

struct HealthKitPermissionCard: View {
    let action: () -> Void
    
    var body: some View {
        InteractiveCard(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.error)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Connect Apple Health")
                        .font(.h3) // 18pt, medium
                        .foregroundColor(.textPrimary)
                    
                    Text("Sync steps, workouts & calories automatically")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
        }
    }
}

struct HealthKitPermissionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var isRequesting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea() // Design System: background = #ffffff
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.error.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.error)
                        }
                        .padding(.top, Spacing.xl)
                        
                        // Title
                        VStack(spacing: Spacing.md) {
                            Text("Connect Apple Health")
                                .font(.h1) // 24pt, medium
                                .foregroundColor(.textPrimary)
                            
                            Text("Sync your activity data to get personalized nutrition recommendations")
                                .font(.input) // 16pt, regular
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.xl)
                        }
                        
                        // Benefits
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            BenefitRow(icon: "figure.walk", text: "Track steps automatically")
                            BenefitRow(icon: "flame.fill", text: "Monitor calories burned")
                            BenefitRow(icon: "figure.strengthtraining.traditional", text: "Sync workouts from Apple Watch")
                            if appState.user.gender == .female {
                                BenefitRow(icon: "calendar", text: "Track menstrual cycle")
                            }
                        }
                        .padding(.horizontal, Spacing.xl)
                        
                        Spacer()
                        
                        // Buttons
                        VStack(spacing: Spacing.md) {
                            PrimaryButton(
                                title: isRequesting ? "Connecting..." : "Connect Health",
                                action: {
                                    HapticFeedback.impact()
                                    isRequesting = true
                                    Task {
                                        await appState.requestHealthKitAuthorization()
                                        await appState.syncHealthKitData()
                                        isRequesting = false
                                        if appState.healthKitService.isAuthorized {
                                            HapticFeedback.success()
                                            dismiss()
                                        } else {
                                            HapticFeedback.error()
                                        }
                                    }
                                },
                                icon: "heart.fill",
                                isEnabled: !isRequesting
                            )
                            
                            TextButton(
                                title: "Maybe Later",
                                action: {
                                    HapticFeedback.selection()
                                    dismiss()
                                }
                            )
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xl)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.bodySmall)
                                .foregroundColor(.error)
                                .padding(.horizontal, Spacing.md)
                        }
                    }
                }
            }
            .navigationTitle("Health Integration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        HapticFeedback.selection()
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.primaryAccent)
                .frame(width: 30)
            
            Text(text)
                .font(.input) // 16pt, regular
                .foregroundColor(.textPrimary)
        }
    }
}
