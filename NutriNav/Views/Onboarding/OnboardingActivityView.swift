//
//  OnboardingActivityView.swift
//  NutriNav
//
//  Step 3: Activity level selection
//

import SwiftUI

struct OnboardingActivityView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedActivity: ActivityLevel?
    @State private var navigateToNext = false
    
    var body: some View {
        ZStack {
            // White background matching Figma design
            Color.primaryBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Progress indicator
                    VStack(spacing: Spacing.sm) {
                        HStack {
                            Text("Step 2 of 3")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                            
                            HStack(spacing: Spacing.xs) {
                                Text("✨")
                                    .font(.system(size: 12))
                                Text("67% there!")
                                    .font(.bodySmall)
                            }
                            .foregroundColor(.warning)
                        }
                        .padding(.horizontal, Spacing.md)
                        
                        ProgressView(value: 0.67)
                            .tint(.primaryAccent)
                            .background(Color.textTertiary.opacity(0.2))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .padding(.horizontal, Spacing.md)
                    }
                    .padding(.top, Spacing.xxl)
                    
                    // Title
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.xs) {
                            Text("How Active Are You?")
                                .font(.heading1)
                                .foregroundColor(.textPrimary)
                            
                            Text("💪")
                                .font(.body)
                        }
                        
                        Text("Be honest - this helps us nail your calorie needs!")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                    .padding(.top, Spacing.xl)
                    
                    // Activity options
                    VStack(spacing: Spacing.md) {
                        ForEach(ActivityLevel.allCases, id: \.self) { activity in
                            ActivityButton(
                                activity: activity,
                                isSelected: selectedActivity == activity
                            ) {
                                HapticFeedback.selection()
                                selectedActivity = activity
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    
                    Spacer(minLength: Spacing.xl)
                    
                    // Navigation buttons - using DesignSystem
                    HStack(spacing: Spacing.md) {
                        SecondaryButton(
                            title: "Back",
                            action: {
                                HapticFeedback.selection()
                                dismiss()
                            },
                            isEnabled: true
                        )
                        
                        PrimaryButton(
                            title: "Continue",
                            action: {
                                appState.user.activityLevel = selectedActivity
                                navigateToNext = true
                            },
                            icon: "arrow.right",
                            isEnabled: selectedActivity != nil
                        )
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToNext) {
            OnboardingGoalView()
        }
    }
}

// MARK: - Activity Button (DesignSystem aligned)
struct ActivityButton: View {
    let activity: ActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Text(activity.emoji)
                    .font(.system(size: 28))
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(activity.rawValue)
                        .font(.heading3)
                        .foregroundColor(isSelected ? .textPrimary : .textPrimary)
                    
                    Text(activity.description)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.primaryAccent)
                        .font(.system(size: 20))
                }
            }
            .padding(Spacing.md)
            .background(isSelected ? Color.primaryAccent.opacity(0.1) : Color.white)
            .cornerRadius(CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(isSelected ? Color.primaryAccent : Color.textTertiary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

