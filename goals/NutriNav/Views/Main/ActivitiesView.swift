//
//  ActivitiesView.swift
//  NutriNav
//
//  Activity & Hobbies selection and tracking screen
//

import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var appState: AppState
    @State private var hobbies: [Hobby] = MockDataService.shared.getHobbies()
    @State private var showHealthKitPermission = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Activities")
                            .font(.system(size: 32, weight: .bold))
                        
                        Text("Select your hobbies and sports to personalize your nutrition plan")
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // HealthKit Status
                    if !appState.healthKitService.isAuthorized {
                        HealthKitPermissionCard {
                            showHealthKitPermission = true
                        }
                        .padding(.horizontal, 20)
                    } else {
                        ActivitySummaryCard(
                            steps: appState.todaySteps,
                            activeCalories: appState.todayActiveCalories,
                            workouts: appState.todayWorkouts
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Selected Hobbies
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Your Hobbies")
                                .font(.system(size: 24, weight: .bold))
                            
                            Spacer()
                            
                            Text("\(hobbies.filter { $0.isSelected }.count) selected")
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach($hobbies) { $hobby in
                                HobbyCard(hobby: $hobby)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)
                    
                    // Badges Section
                    if !unlockedBadges.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 8) {
                                Text("🏆")
                                    .font(.system(size: 24))
                                Text("Your Badges")
                                    .font(.system(size: 24, weight: .bold))
                            }
                            .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(unlockedBadges) { badge in
                                        BadgeCard(badge: badge)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 10)
                    }
                    
                    // Activity Impact on Nutrition
                    if !appState.todayWorkouts.isEmpty {
                        ActivityNutritionImpactCard(workouts: appState.todayWorkouts)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Activities")
            .sheet(isPresented: $showHealthKitPermission) {
                HealthKitPermissionView()
                    .environmentObject(appState)
            }
        }
    }
    
    private var unlockedBadges: [HobbyBadge] {
        hobbies.flatMap { $0.badges.filter { $0.isUnlocked } }
    }
}

struct HobbyCard: View {
    @Binding var hobby: Hobby
    
    var body: some View {
        Button(action: {
            hobby.isSelected.toggle()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(hobby.isSelected ? Color.appPurple.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Text(hobby.type.emoji)
                        .font(.system(size: 32))
                }
                
                Text(hobby.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                if hobby.isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        Text("Selected")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(hobby.isSelected ? Color.appPurple.opacity(0.1) : Color.cardBackground)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(hobby.isSelected ? Color.appPurple : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct BadgeCard: View {
    let badge: HobbyBadge
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.appOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Text(badge.icon)
                    .font(.system(size: 35))
            }
            
            Text(badge.name)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.center)
            
            Text(badge.description)
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 120)
        .padding(15)
        .background(Color.cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ActivityNutritionImpactCard: View {
    let workouts: [Activity]
    
    var totalCaloriesBurned: Double {
        workouts.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("⚡")
                    .font(.system(size: 24))
                Text("Activity Impact")
                    .font(.system(size: 20, weight: .bold))
            }
            
            Text("You've burned \(Int(totalCaloriesBurned)) calories today! Your nutrition goals have been adjusted.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 20) {
                StatItem(icon: "flame.fill", value: "\(Int(totalCaloriesBurned))", label: "Calories", color: .orange)
                StatItem(icon: "figure.strengthtraining.traditional", value: "\(workouts.count)", label: "Workouts", color: .purple)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.appPurple.opacity(0.1), Color.appPink.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

