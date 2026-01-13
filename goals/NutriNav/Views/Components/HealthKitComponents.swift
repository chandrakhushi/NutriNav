//
//  HealthKitComponents.swift
//  NutriNav
//
//  HealthKit UI components
//

import SwiftUI

struct ActivitySummaryCard: View {
    let steps: Double
    let activeCalories: Double
    let workouts: [Activity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 8) {
                Text("Today's Activity")
                    .font(.system(size: 20, weight: .bold))
                Text("🏃")
                    .font(.system(size: 18))
            }
            
            HStack(spacing: 20) {
                // Steps
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.blue)
                        Text("Steps")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    Text("\(Int(steps))")
                        .font(.system(size: 24, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                // Active Calories
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Burned")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    Text("\(Int(activeCalories))")
                        .font(.system(size: 24, weight: .bold))
                    Text("kcal")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                // Workouts
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundColor(.purple)
                        Text("Workouts")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    Text("\(workouts.count)")
                        .font(.system(size: 24, weight: .bold))
                }
                .frame(maxWidth: .infinity)
            }
            
            // Recent workouts list
            if !workouts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Workouts")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.top, 8)
                    
                    ForEach(workouts.prefix(3)) { workout in
                        HStack {
                            Text(workout.type.emoji)
                                .font(.system(size: 20))
                            Text(workout.name)
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Text("\(Int(workout.duration / 60))m")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            Text("\(Int(workout.caloriesBurned)) kcal")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct HealthKitPermissionCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Connect Apple Health")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Sync steps, workouts & calories automatically")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
            .padding(20)
            .background(Color.cardBackground)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.appPurple.opacity(0.3), lineWidth: 2)
            )
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
            VStack(spacing: 30) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                }
                .padding(.top, 40)
                
                // Title
                VStack(spacing: 12) {
                    Text("Connect Apple Health")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Sync your activity data to get personalized nutrition recommendations")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: 15) {
                    BenefitRow(icon: "figure.walk", text: "Track steps automatically")
                    BenefitRow(icon: "flame.fill", text: "Monitor calories burned")
                    BenefitRow(icon: "figure.strengthtraining.traditional", text: "Sync workouts from Apple Watch")
                    if appState.user.gender == .female {
                        BenefitRow(icon: "calendar", text: "Track menstrual cycle")
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        isRequesting = true
                        Task {
                            await appState.requestHealthKitAuthorization()
                            await appState.syncHealthKitData()
                            isRequesting = false
                            if appState.healthKitService.isAuthorized {
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Connect Health")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(15)
                    }
                    .disabled(isRequesting)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Maybe Later")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Health Integration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.appPurple)
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 16))
        }
    }
}

