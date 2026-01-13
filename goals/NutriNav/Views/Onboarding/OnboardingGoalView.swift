//
//  OnboardingGoalView.swift
//  NutriNav
//
//  Step 4: Goal selection
//

import SwiftUI

struct OnboardingGoalView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedGoal: FitnessGoal?
    @State private var navigateToMain = false
    
    var body: some View {
        ZStack {
            // White background matching Figma design
            Color.primaryBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Progress indicator
                    VStack(spacing: Spacing.sm) {
                        HStack {
                            Text("Step 4 of 4")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                            
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 12))
                                Text("100% there!")
                                    .font(.bodySmall)
                            }
                            .foregroundColor(.warning)
                        }
                        .padding(.horizontal, Spacing.md)
                        
                        ProgressView(value: 1.0)
                            .tint(.primaryAccent)
                            .background(Color.textTertiary.opacity(0.2))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .padding(.horizontal, Spacing.md)
                    }
                    .padding(.top, Spacing.xxl)
                    
                    // Title
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.xs) {
                            Text("What's Your Goal?")
                                .font(.heading1)
                                .foregroundColor(.textPrimary)
                            
                            Text("🎯")
                                .font(.body)
                        }
                        
                        Text("Choose your path to greatness!")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                    .padding(.top, Spacing.xl)
                    
                    // Goal options
                    VStack(spacing: Spacing.md) {
                        ForEach(FitnessGoal.allCases, id: \.self) { goal in
                            GoalCard(
                                goal: goal,
                                isSelected: selectedGoal == goal
                            ) {
                                HapticFeedback.selection()
                                selectedGoal = goal
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
                                // Go back handled by navigation
                            }
                        )
                        
                        PrimaryButton(
                            title: "Let's Go!",
                            action: {
                                appState.user.goal = selectedGoal
                                // Calculate nutrition goals
                                if let age = appState.user.age,
                                   let gender = appState.user.gender,
                                   let height = appState.user.height,
                                   let weight = appState.user.weight,
                                   let activityLevel = appState.user.activityLevel,
                                   let goal = appState.user.goal {
                                    appState.dailyNutrition = NutritionStats.calculateGoals(
                                        age: age,
                                        gender: gender,
                                        height: height,
                                        weight: weight,
                                        activityLevel: activityLevel,
                                        goal: goal
                                    )
                                }
                                appState.hasCompletedOnboarding = true
                                navigateToMain = true
                            },
                            icon: "arrow.right"
                        )
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                    .disabled(selectedGoal == nil)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            navigateToMain = false
        }
    }
}

// MARK: - Goal Card (DesignSystem aligned - using solid colors instead of gradients)
struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void
    
    // Using DesignSystem colors - solid colors matching Figma design
    var goalColor: Color {
        switch goal {
        case .glowUp: return Color(hex: "E91E63") // Pink
        case .loseWeight: return Color(hex: "FF9800") // Orange
        case .maintainWeight: return Color.primaryAccent // Green
        case .buildMuscle: return Color(hex: "2196F3") // Blue
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Text(goal.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(goal.rawValue)
                        .font(.heading3)
                        .foregroundColor(.textPrimary)
                    
                    Text(goal.description)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(goalColor)
                        .font(.system(size: 20))
                }
            }
            .padding(Spacing.md)
            .background(isSelected ? goalColor.opacity(0.1) : Color.white)
            .cornerRadius(CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(isSelected ? goalColor : Color.textTertiary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

