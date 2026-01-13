//
//  OnboardingActivityView.swift
//  NutriNav
//
//  Step 3: Activity level selection
//

import SwiftUI

struct OnboardingActivityView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedActivity: ActivityLevel?
    @State private var navigateToNext = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appOrange, Color.appPink],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Progress indicator
                VStack(spacing: 10) {
                    HStack {
                        Text("Step 3 of 4")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("✨")
                                .font(.system(size: 12))
                            Text("75% there!")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 20)
                    
                    ProgressView(value: 0.75)
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
                        Text("How Active Are You?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("💪")
                            .font(.system(size: 24))
                    }
                    
                    Text("Be honest - this helps us nail your calorie needs!")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Activity options
                VStack(spacing: 12) {
                    ForEach(ActivityLevel.allCases, id: \.self) { activity in
                        ActivityButton(
                            activity: activity,
                            isSelected: selectedActivity == activity
                        ) {
                            selectedActivity = activity
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
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        appState.user.activityLevel = selectedActivity
                        navigateToNext = true
                    }) {
                        HStack {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))
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
                .disabled(selectedActivity == nil)
                .opacity(selectedActivity == nil ? 0.6 : 1.0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToNext) {
            OnboardingGoalView()
        }
    }
}

struct ActivityButton: View {
    let activity: ActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Text(activity.emoji)
                    .font(.system(size: 28))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.rawValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isSelected ? .appPurple : .white)
                    
                    Text(activity.description)
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? .appPurple.opacity(0.8) : .white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.white : Color.white.opacity(0.2))
            .cornerRadius(15)
        }
    }
}

