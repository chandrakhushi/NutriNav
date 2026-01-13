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
            LinearGradient(
                colors: [Color.appPurple, Color.appPink],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Progress indicator
                VStack(spacing: 10) {
                    HStack {
                        Text("Step 4 of 4")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12))
                            Text("100% there!")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 20)
                    
                    ProgressView(value: 1.0)
                        .tint(.yellow)
                        .background(Color.white.opacity(0.3))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Title
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text("What's Your Goal?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("🎯")
                            .font(.system(size: 24))
                    }
                    
                    Text("Choose your path to greatness!")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Goal options
                VStack(spacing: 15) {
                    ForEach(FitnessGoal.allCases, id: \.self) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: selectedGoal == goal
                        ) {
                            selectedGoal = goal
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 15) {
                    Button(action: {
                        // Go back
                    }) {
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
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
                    }) {
                        HStack {
                            Text("Let's Go!")
                                .font(.system(size: 18, weight: .bold))
                            Text("🚀")
                                .font(.system(size: 16))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.appPurple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .disabled(selectedGoal == nil)
                .opacity(selectedGoal == nil ? 0.6 : 1.0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            navigateToMain = false
        }
    }
}

struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void
    
    var gradient: LinearGradient {
        switch goal {
        case .glowUp:
            return LinearGradient(
                colors: [Color.appPink, Color(red: 0.9, green: 0.2, blue: 0.2)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .loseWeight:
            return LinearGradient(
                colors: [Color.appPink, Color.appOrange],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .maintainWeight:
            return LinearGradient(
                colors: [Color.appPurple, Color.appPink],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .buildMuscle:
            return LinearGradient(
                colors: [Color.appOrange, Color.appPink],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Text(goal.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.rawValue)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(goal.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
            }
            .padding()
            .background(gradient)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
            )
        }
    }
}

