//
//  ProfileView.swift
//  NutriNav
//
//  Profile screen with user info, progress, and goals
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with gradient
                        VStack(spacing: 20) {
                            // Profile info
                            HStack(spacing: 15) {
                                ZStack {
                                    Circle()
                                        .fill(Color.appOrange)
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(appState.user.name)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(appState.user.email)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    HStack(spacing: 8) {
                                        if let age = appState.user.age {
                                            Badge(text: "\(age) yrs")
                                        }
                                        if let height = appState.user.height {
                                            Badge(text: "\(Int(height))cm")
                                        }
                                        if let weight = appState.user.weight {
                                            Badge(text: "\(Int(weight))kg")
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // Premium upgrade banner
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 4) {
                                            Text("Upgrade to Premium")
                                                .font(.system(size: 20, weight: .bold))
                                            Text("✨")
                                                .font(.system(size: 16))
                                        }
                                        
                                        Text("Unlock all the magic")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(20)
                                .background(
                                    LinearGradient(
                                        colors: [Color.yellow, Color.appOrange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(15)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 30)
                        .background(
                            LinearGradient(
                                colors: [Color.appPurple, Color.appPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        
                        // Content section
                        VStack(spacing: 25) {
                            // Your Progress section
                            VStack(alignment: .leading, spacing: 15) {
                                HStack(spacing: 8) {
                                    Text("Your Progress")
                                        .font(.system(size: 24, weight: .bold))
                                    Text("🎯")
                                        .font(.system(size: 20))
                                }
                                .padding(.horizontal, 20)
                                
                                HStack(spacing: 15) {
                                    ProgressStatCard(
                                        title: "Streak",
                                        value: "\(appState.currentStreak.currentDays) days",
                                        icon: "chart.line.uptrend.xyaxis",
                                        color: .appPurple
                                    )
                                    
                                    ProgressStatCard(
                                        title: "Recipes",
                                        value: "24",
                                        icon: "book.fill",
                                        color: .appOrange
                                    )
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 20)
                            
                            // Your Goals section
                            VStack(alignment: .leading, spacing: 15) {
                                HStack(spacing: 8) {
                                    Text("Your Goals")
                                        .font(.system(size: 24, weight: .bold))
                                    Text("💪")
                                        .font(.system(size: 20))
                                }
                                .padding(.horizontal, 20)
                                
                                VStack(spacing: 12) {
                                    GoalRow(
                                        title: "Nutrition Goals",
                                        subtitle: "\(Int(appState.dailyNutrition.calories.target)) cal • \(Int(appState.dailyNutrition.protein.target))g protein",
                                        icon: "heart.text.square.fill",
                                        color: .appOrange
                                    )
                                    
                                    GoalRow(
                                        title: "Dietary Preferences",
                                        subtitle: "Customize your meals",
                                        icon: "leaf.fill",
                                        color: .green
                                    )
                                    
                                    NavigationLink(destination: CycleView().environmentObject(appState)) {
                                        GoalRow(
                                            title: "Cycle & Workout Sync",
                                            subtitle: appState.user.cyclePhase?.rawValue ?? "Not tracked",
                                            icon: "calendar.badge.clock",
                                            color: .appPink
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 10)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
        }
    }
}

struct Badge: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.appPurple.opacity(0.3))
            .cornerRadius(12)
    }
}

struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textSecondary)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(color.opacity(0.1))
        .cornerRadius(15)
    }
}

struct GoalRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 15) {
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
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
            .padding(15)
            .background(Color.cardBackground)
            .cornerRadius(15)
        }
    }
}

