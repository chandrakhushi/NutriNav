//
//  HomeView.swift
//  NutriNav
//
//  Main dashboard/home screen - using DesignSystem
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showNutritionDetails = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea() // Design System: background = #ffffff
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header Section
                        headerSection
                            .padding(.top, Spacing.xxl)
                        
                        // Nutrition Section
                        nutritionSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Quick Actions
                        quickActionsSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Daily Tip
                        dailyTipCard
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .sheet(isPresented: $showNutritionDetails) {
                NutritionDetailsView()
                    .environmentObject(appState)
            }
        }
    }
    
    // MARK: - Header Section
    
    // MARK: - Header Section (Design System: h1=24pt medium)
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Today")
                        .font(.h1) // 24pt, medium
                        .foregroundColor(.textPrimary)
                    
                    Text(Date().formatted(date: .complete, time: .omitted))
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Crown icon button (premium feature)
                Button(action: {
                    HapticFeedback.selection()
                    // TODO: Navigate to premium screen
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.md) // Button cornerRadius = 8
                            .fill(LinearGradient(
                                colors: [Color(hex: "FF9800"), Color(hex: "FFC107")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.lg)
    }
    
    // MARK: - Nutrition Section
    
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Nutrition Progress")
            
            PrimaryCard {
                VStack(spacing: Spacing.lg) {
                    // Calories
                    nutritionProgressRow(
                        title: "Calories",
                        icon: "flame.fill",
                        current: appState.dailyNutrition.calories.current,
                        target: appState.dailyNutrition.calories.target,
                        color: .calorieColor
                    )
                    
                    Divider()
                        .background(Color.textTertiary.opacity(0.2))
                    
                    // Protein
                    nutritionProgressRow(
                        title: "Protein",
                        icon: "figure.strengthtraining.traditional",
                        current: appState.dailyNutrition.protein.current,
                        target: appState.dailyNutrition.protein.target,
                        color: .proteinColor
                    )
                }
            }
        }
    }
    
    // MARK: - Nutrition Progress Row (Design System: input=16pt regular)
    private func nutritionProgressRow(
        title: String,
        icon: String,
        current: Double,
        target: Double,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.input) // 16pt, regular
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if target > 0 {
                    Text("\(Int((current / target) * 100))%")
                        .font(.input) // 16pt, regular
                        .foregroundColor(.textSecondary)
                }
            }
            
            if target > 0 {
                HStack {
                    Text("\(Int(current)) / \(Int(target))")
                        .font(.input) // 16pt, regular
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                }
                
                ProgressBar(
                    value: current,
                    maxValue: target,
                    color: color,
                    height: 8
                )
            }
        }
    }
    
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Quick Actions")
            
            // Recipe Suggestions - Navigate to Recipes tab
            InteractiveCard(action: {
                appState.selectedTab = .recipes
            }) {
                quickActionContent(
                    title: "Recipe Suggestions",
                    subtitle: "Based on your ingredients",
                    icon: "fork.knife",
                    iconColor: Color(hex: "4CAF50")
                )
            }
            
            // Nearby Food Options - Navigate to Nearby tab
            InteractiveCard(action: {
                appState.selectedTab = .nearby
            }) {
                quickActionContent(
                    title: "Nearby Food Options",
                    subtitle: "Find restaurants near you",
                    icon: "mappin.circle.fill",
                    iconColor: Color(hex: "9C27B0")
                )
            }
            
            // Budget Planner - Navigate to Budget view
            NavigationLink(destination: BudgetView().environmentObject(appState)) {
                InteractiveCard(action: nil) {
                    quickActionContent(
                        title: "Budget Planner",
                        subtitle: "Track your meal spending",
                        icon: "wallet.pass.fill",
                        iconColor: Color(hex: "FFC107")
                    )
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Quick Action Content (Design System: h3=18pt medium)
    private func quickActionContent(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color
    ) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.md) // Button cornerRadius = 8
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.h3) // 18pt, medium
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textTertiary)
        }
    }
    
    // MARK: - Daily Tip (Design System: h3=18pt medium, card padding=16, cornerRadius=lg=10)
    private var dailyTipCard: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "target")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Daily Tip")
                    .font(.h3) // 18pt, medium
                    .foregroundColor(.white)
                
                let remaining = Int(appState.dailyNutrition.calories.target - appState.dailyNutrition.calories.current)
                Text("You're \(remaining) calories away from your goal! Try adding a protein-rich snack this afternoon.")
                    .font(.bodySmall)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .padding(16) // Card.padding = 16
        .background(Color.primaryAccent)
        .cornerRadius(Radius.lg) // Card.cornerRadius = Radius.lg (10)
    }
}

// MARK: - Nutrition Details View (Placeholder)

// MARK: - Nutrition Details View (Design System: h1=24pt medium)
struct NutritionDetailsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        Text("Nutrition Details")
                            .font(.h1) // 24pt, medium
                            .foregroundColor(.textPrimary)
                        
                        Text("Detailed breakdown coming soon")
                            .font(.input) // 16pt, regular
                            .foregroundColor(.textSecondary)
                    }
                    .padding(Spacing.xl)
                }
            }
            .navigationTitle("Nutrition Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticFeedback.selection()
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
}
