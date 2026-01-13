//
//  ActivitiesView.swift
//  NutriNav
//
//  Activity & Hobbies screen - using DesignSystem
//

import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var appState: AppState
    @State private var hobbies: [Hobby] = MockDataService.shared.getHobbies()
    @State private var showHealthKitPermission = false
    
    var unlockedBadges: [HobbyBadge] {
        hobbies.flatMap { $0.badges.filter { $0.isUnlocked } }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea() // Design System: background = #ffffff
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        headerSection
                            .padding(.top, Spacing.xxl)
                        
                        // HealthKit Status
                        if !appState.healthKitService.isAuthorized {
                            healthKitPermissionCard
                                .padding(.horizontal, Spacing.md)
                        } else {
                            healthKitCard
                                .padding(.horizontal, Spacing.md)
                        }
                        
                        // Hobbies Section
                        hobbiesSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Badges Section
                        if !unlockedBadges.isEmpty {
                            badgesSection
                                .padding(.horizontal, Spacing.md)
                        }
                        
                        // Activity Impact
                        if !appState.todayWorkouts.isEmpty {
                            activityImpactCard
                                .padding(.horizontal, Spacing.md)
                        }
                        
                        Spacer(minLength: Spacing.xl)
                    }
                }
            }
            .sheet(isPresented: $showHealthKitPermission) {
                HealthKitPermissionView()
                    .environmentObject(appState)
            }
        }
    }
    
    // MARK: - Header (Design System: h1=24pt medium, input=16pt regular)
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Your Activities")
                .font(.h1) // 24pt, medium
                .foregroundColor(.textPrimary)
            
            Text("Select your hobbies and sports to personalize your nutrition plan")
                .font(.input) // 16pt, regular
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }
    
    // MARK: - HealthKit
    
    private var healthKitPermissionCard: some View {
        PrimaryCard {
            HealthKitPermissionCard {
                showHealthKitPermission = true
            }
        }
    }
    
    private var healthKitCard: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Activity")
                
                HStack(spacing: Spacing.lg) {
                    StatRing(
                        value: appState.todaySteps,
                        maxValue: 10000,
                        color: .primaryAccent,
                        size: 70
                    )
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("\(Int(appState.todaySteps)) steps")
                            .font(.body)
                            .foregroundColor(.textPrimary)
                        
                        Text("\(Int(appState.todayActiveCalories)) cal burned")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Hobbies
    
    private var hobbiesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                SectionHeader(title: "Your Hobbies")
                
                Spacer()
                
                BadgeView(
                    text: "\(hobbies.filter { $0.isSelected }.count) selected",
                    color: .primaryAccent
                )
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                ForEach($hobbies) { $hobby in
                    hobbyCard(hobby: $hobby)
                }
            }
        }
    }
    
    // MARK: - Hobby Card (Design System: input=16pt regular, card padding=16, cornerRadius=lg=10)
    private func hobbyCard(hobby: Binding<Hobby>) -> some View {
        Button(action: {
            HapticFeedback.selection()
            hobby.wrappedValue.isSelected.toggle()
        }) {
            PrimaryCard { // Card.padding=16, Card.cornerRadius=lg=10
                VStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                hobby.wrappedValue.isSelected
                                    ? Color.primaryAccent.opacity(0.2)
                                    : Color.textTertiary.opacity(0.1)
                            )
                            .frame(width: 60, height: 60)
                        
                        Text(hobby.wrappedValue.type.emoji)
                            .font(.system(size: 32))
                    }
                    
                    Text(hobby.wrappedValue.name)
                        .font(.input) // 16pt, regular
                        .foregroundColor(.textPrimary)
                    
                    if hobby.wrappedValue.isSelected {
                        BadgeView(
                            text: "Selected",
                            color: .success,
                            size: .small
                        )
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg) // Card cornerRadius = 10
                    .stroke(
                        hobby.wrappedValue.isSelected ? Color.primaryAccent : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Badges
    
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Your Badges")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(unlockedBadges) { badge in
                        badgeCard(badge: badge)
                    }
                }
            }
        }
    }
    
    // MARK: - Badge Card (Design System: input=16pt regular, card padding=16, cornerRadius=lg=10)
    private func badgeCard(badge: HobbyBadge) -> some View {
        PrimaryCard { // Card.padding=16, Card.cornerRadius=lg=10
            VStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.primaryAccent.opacity(0.1))
                        .frame(width: 70, height: 70)
                    
                    Text(badge.icon)
                        .font(.system(size: 35))
                }
                
                Text(badge.name)
                    .font(.input) // 16pt, regular
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(badge.description)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 120)
        }
    }
    
    // MARK: - Activity Impact
    
    private var activityImpactCard: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Activity Impact")
                
                Text("You've burned \(Int(totalCaloriesBurned)) calories today! Your nutrition goals have been adjusted.")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                
                HStack(spacing: Spacing.lg) {
                    statItem(
                        icon: "flame.fill",
                        value: "\(Int(totalCaloriesBurned))",
                        label: "Calories",
                        color: .calorieColor
                    )
                    
                    statItem(
                        icon: "figure.strengthtraining.traditional",
                        value: "\(appState.todayWorkouts.count)",
                        label: "Workouts",
                        color: .proteinColor
                    )
                }
            }
        }
    }
    
    private var totalCaloriesBurned: Double {
        appState.todayWorkouts.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    // MARK: - Stat Item (Design System: h3=18pt medium)
    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.h3) // 18pt, medium
                    .foregroundColor(.textPrimary)
                
                Text(label)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}
