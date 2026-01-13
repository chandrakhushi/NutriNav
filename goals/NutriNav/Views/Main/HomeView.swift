//
//  HomeView.swift
//  NutriNav
//
//  Main dashboard/home screen
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var recipes = MockDataService.shared.getRecipes()
    @State private var showHealthKitPermission = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header section with gradient
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back! 👋")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                HStack(spacing: 8) {
                                    Text("You're Crushing It!")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    ZStack {
                                        Circle()
                                            .fill(Color.yellow)
                                            .frame(width: 30, height: 30)
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.appPurple)
                                    }
                                }
                                
                                Text("Thursday, January 9 • Keep up the momentum! 🔥")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.appPurple, Color.appPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    // Content section
                    VStack(spacing: 20) {
                        // Streak card
                        StreakCard(streak: appState.currentStreak)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        // HealthKit Activity section
                        if appState.healthKitService.isAuthorized {
                            ActivitySummaryCard(
                                steps: appState.todaySteps,
                                activeCalories: appState.todayActiveCalories,
                                workouts: appState.todayWorkouts
                            )
                            .padding(.horizontal, 20)
                        } else {
                            // HealthKit permission prompt
                            HealthKitPermissionCard {
                                showHealthKitPermission = true
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Today's Fuel section
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                HStack(spacing: 8) {
                                    Text("Today's Fuel")
                                        .font(.system(size: 24, weight: .bold))
                                    Text("⚡")
                                        .font(.system(size: 20))
                                }
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Text("\(Int(appState.dailyNutrition.totalCompletion))% Complete")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.appPurple)
                                        .cornerRadius(20)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Nutrition cards
                            NutritionCard(
                                title: "Calories",
                                icon: "flame.fill",
                                current: appState.dailyNutrition.calories.current,
                                target: appState.dailyNutrition.calories.target,
                                color: .calorieColor
                            )
                            
                            NutritionCard(
                                title: "Protein",
                                icon: "figure.strengthtraining.traditional",
                                current: appState.dailyNutrition.protein.current,
                                target: appState.dailyNutrition.protein.target,
                                color: .proteinColor
                            )
                            
                            // Carbs and Fats side by side
                            HStack(spacing: 15) {
                                SmallNutritionCard(
                                    title: "Carbs",
                                    icon: "apple.fill",
                                    value: appState.dailyNutrition.carbs.current,
                                    color: .carbColor
                                )
                                
                                SmallNutritionCard(
                                    title: "Fats",
                                    icon: "leaf.fill",
                                    value: appState.dailyNutrition.fats.current,
                                    color: .fatColor
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 10)
                        
                        // What's Next section
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 8) {
                                Text("What's Next?")
                                    .font(.system(size: 24, weight: .bold))
                                Text("🚀")
                                    .font(.system(size: 20))
                            }
                            .padding(.horizontal, 20)
                            
                            ActionCard(
                                title: "Find a Recipe",
                                subtitle: "Cook something delicious 🍳",
                                icon: "fork.knife",
                                gradient: LinearGradient(
                                    colors: [Color.appPink, Color(red: 0.9, green: 0.2, blue: 0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            
                            ActionCard(
                                title: "Explore Nearby",
                                subtitle: "Healthy spots near you 📍",
                                icon: "mappin.circle.fill",
                                gradient: LinearGradient(
                                    colors: [Color.appPurple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            
                            NavigationLink(destination: BudgetView().environmentObject(appState)) {
                                ActionCard(
                                    title: "Budget Tracker",
                                    subtitle: "Smart spending habits 💰",
                                    icon: "wallet.pass.fill",
                                    gradient: LinearGradient(
                                        colors: [Color.appOrange, Color.yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Motivation card
                            MotivationCard(
                                remainingCalories: appState.dailyNutrition.calories.remaining
                            )
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                    .background(Color.white)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .sheet(isPresented: $showHealthKitPermission) {
            HealthKitPermissionView()
                .environmentObject(appState)
        }
        .onAppear {
            // Request HealthKit data if authorized
            if appState.healthKitService.isAuthorized {
                Task {
                    await appState.healthKitService.loadTodayData()
                }
            }
        }
    }
}

struct StreakCard: View {
    let streak: Streak
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Streak")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                HStack(spacing: 8) {
                    Text("\(streak.currentDays) Days")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("🔥")
                        .font(.system(size: 24))
                }
                
                Text("You're on fire! Keep it going")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Text("🎯")
                .font(.system(size: 40))
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.appOrange, Color.appPink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
}

struct NutritionCard: View {
    let title: String
    let icon: String
    let current: Double
    let target: Double
    let color: Color
    
    var percentage: Double {
        guard target > 0 else { return 0 }
        return min((current / target) * 100, 100)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    HStack(spacing: 4) {
                        Text("\(Int(current))")
                            .font(.system(size: 20, weight: .bold))
                        Text("/ \(Int(target))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                Text("\(Int(percentage))%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (percentage / 100), height: 8)
                }

            }
            .frame(height: 8)
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(15)
        .padding(.horizontal, 20)
    }
}

struct SmallNutritionCard: View {
    let title: String
    let icon: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textSecondary)
            
            Text("\(Int(value))g")
                .font(.system(size: 20, weight: .bold))
            
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geometry.size.width * 0.7, height: 4)
            }
            .frame(height: 4)
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(15)
    }
}

struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(gradient)
            .cornerRadius(15)
        }
        .padding(.horizontal, 20)
    }
}

struct MotivationCard: View {
    let remainingCalories: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Text("Daily Motivation ✨")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Amazing! You're \(Int(remainingCalories)) cals from your goal. Your future self will thank you! 💪")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.appPurple, Color.appPink],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(15)
        .padding(.horizontal, 20)
    }
}

