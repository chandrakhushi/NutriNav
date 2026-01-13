//
//  CycleView.swift
//  NutriNav
//
//  Cycle-aware nutrition screen
//

import SwiftUI

struct CycleView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCycleEditor = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // White background matching Figma design
                Color.primaryBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Cycle Phase Card
                        if let cyclePhase = appState.user.cyclePhase {
                            CyclePhaseCard(phase: cyclePhase)
                                .padding(.horizontal, Spacing.md)
                                .padding(.top, Spacing.xxl)
                        } else {
                            NoCycleDataCard {
                                HapticFeedback.selection()
                                showCycleEditor = true
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.xxl)
                        }
                        
                        // Nutrition Adjustments
                        if let cyclePhase = appState.user.cyclePhase {
                            CycleNutritionAdjustments(phase: cyclePhase, nutrition: appState.dailyNutrition)
                                .padding(.horizontal, Spacing.md)
                        }
                        
                        // Cycle Tips
                        CycleTipsCard(phase: appState.user.cyclePhase)
                            .padding(.horizontal, Spacing.md)
                        
                        // Sync with HealthKit
                        if appState.user.gender == .female {
                            HealthKitCycleSyncCard {
                                Task {
                                    await appState.syncHealthKitData()
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                    }
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationTitle("Cycle Nutrition")
            .sheet(isPresented: $showCycleEditor) {
                CycleEditorView()
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - Cycle Phase Card (DesignSystem aligned)
struct CyclePhaseCard: View {
    let phase: CyclePhase
    
    var phaseInfo: (name: String, emoji: String, color: Color, description: String) {
        switch phase {
        case .menstruation:
            return ("Menstruation", "🌙", Color.error, "Days 1-5: Focus on iron-rich foods and rest")
        case .follicular:
            return ("Follicular Phase", "🌱", Color.success, "Days 6-13: Energy is rising, great for workouts")
        case .ovulation:
            return ("Ovulation", "✨", Color.warning, "Days 14-16: Peak energy, maximize nutrition")
        case .luteal:
            return ("Luteal Phase", "🍫", Color.calorieColor, "Days 17+: Cravings may increase, focus on balance")
        }
    }
    
    // MARK: - Cycle Phase Card (Design System: h2=20pt medium, card padding=16, cornerRadius=lg=10)
    var body: some View {
        PrimaryCard { // Card.padding=16, Card.cornerRadius=lg=10
            VStack(spacing: Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack(spacing: Spacing.sm) {
                            Text(phaseInfo.emoji)
                                .font(.system(size: 32))
                            Text(phaseInfo.name)
                                .font(.h2) // 20pt, medium
                                .foregroundColor(.textPrimary)
                        }
                        
                        Text(phaseInfo.description)
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // Cycle progress indicator
                CycleProgressIndicator(phase: phase)
            }
        }
    }
}

// MARK: - Cycle Progress Indicator (DesignSystem aligned)
struct CycleProgressIndicator: View {
    let phase: CyclePhase
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach([CyclePhase.menstruation, .follicular, .ovulation, .luteal], id: \.self) { p in
                Circle()
                    .fill(p == phase ? Color.primaryAccent : Color.textTertiary.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - No Cycle Data Card (DesignSystem aligned)
struct NoCycleDataCard: View {
    let action: () -> Void
    
    // MARK: - No Cycle Data Card (Design System: h2=20pt medium, card padding=16, cornerRadius=lg=10)
    var body: some View {
        PrimaryCard { // Card.padding=16, Card.cornerRadius=lg=10
            VStack(spacing: Spacing.md) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 50))
                    .foregroundColor(.primaryAccent)
                
                Text("Track Your Cycle")
                    .font(.h2) // 20pt, medium
                    .foregroundColor(.textPrimary)
                
                Text("Sync with HealthKit or enter manually to get personalized nutrition recommendations")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                
                PrimaryButton(
                    title: "Get Started",
                    action: action
                )
            }
            .padding(Spacing.xl)
        }
    }
}

// MARK: - Cycle Nutrition Adjustments (DesignSystem aligned)
struct CycleNutritionAdjustments: View {
    let phase: CyclePhase
    let nutrition: DailyNutrition
    
    var adjustments: (calories: Double, protein: Double, message: String) {
        switch phase {
        case .menstruation:
            return (100, 10, "Added iron-rich foods boost")
        case .follicular:
            return (0, 0, "Standard nutrition goals")
        case .ovulation:
            return (50, 5, "Slight increase for peak energy")
        case .luteal:
            return (150, 0, "Increased calories for cravings")
        }
    }
    
    // MARK: - Cycle Nutrition Adjustments (Design System: input=16pt regular, card padding=16, cornerRadius=lg=10)
    var body: some View {
        PrimaryCard { // Card.padding=16, Card.cornerRadius=lg=10
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Adjusted Nutrition Goals")
                
                if adjustments.calories > 0 || adjustments.protein > 0 {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        if adjustments.calories > 0 {
                            AdjustmentRow(
                                icon: "flame.fill",
                                label: "Calories",
                                adjustment: "+\(Int(adjustments.calories))",
                                color: .calorieColor
                            )
                        }
                        
                        if adjustments.protein > 0 {
                            AdjustmentRow(
                                icon: "figure.strengthtraining.traditional",
                                label: "Protein",
                                adjustment: "+\(Int(adjustments.protein))g",
                                color: .proteinColor
                            )
                        }
                    }
                    
                    Text(adjustments.message)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .padding(.top, Spacing.xs)
                } else {
                    Text("Your nutrition goals are optimized for this phase")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}

// MARK: - Adjustment Row (DesignSystem aligned)
struct AdjustmentRow: View {
    let icon: String
    let label: String
    let adjustment: String
    let color: Color
    
    // MARK: - Adjustment Row (Design System: input=16pt regular, h3=18pt medium)
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(.input) // 16pt, regular
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Text(adjustment)
                .font(.h3) // 18pt, medium
                .foregroundColor(color)
        }
    }
}

// MARK: - Cycle Tips Card (DesignSystem aligned - using solid color background)
struct CycleTipsCard: View {
    let phase: CyclePhase?
    
    var body: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Cycle Nutrition Tips")
                
                if let phase = phase {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(tipsForPhase(phase), id: \.self) { tip in
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                Text("•")
                                    .foregroundColor(.primaryAccent)
                                Text(tip)
                                    .font(.bodySmall)
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                } else {
                    Text("Track your cycle to get personalized nutrition tips")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    private func tipsForPhase(_ phase: CyclePhase) -> [String] {
        switch phase {
        case .menstruation:
            return [
                "Focus on iron-rich foods like spinach and lean meats",
                "Stay hydrated and get plenty of rest",
                "Consider magnesium-rich foods to ease cramps"
            ]
        case .follicular:
            return [
                "Great time for high-intensity workouts",
                "Increase protein intake for muscle building",
                "Energy levels are rising - maximize activity"
            ]
        case .ovulation:
            return [
                "Peak energy phase - perfect for challenging workouts",
                "Maintain balanced nutrition",
                "Stay active and hydrated"
            ]
        case .luteal:
            return [
                "Cravings may increase - focus on healthy alternatives",
                "Increase complex carbs for mood stability",
                "Consider magnesium and B6 for PMS symptoms"
            ]
        }
    }
}

// MARK: - HealthKit Cycle Sync Card (DesignSystem aligned)
struct HealthKitCycleSyncCard: View {
    let action: () -> Void
    
    var body: some View {
        InteractiveCard(action: {
            HapticFeedback.selection()
            action()
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 24))
                    .foregroundColor(.primaryAccent)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Sync with HealthKit")
                        .font(.heading3)
                        .foregroundColor(.textPrimary)
                    
                    Text("Automatically track your cycle from Apple Health")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
        }
    }
}

// MARK: - Cycle Editor View (DesignSystem aligned)
struct CycleEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedPhase: CyclePhase?
    @State private var lastPeriodDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // White background matching Figma design
                Color.background.ignoresSafeArea() // Design System: background = #ffffff
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        VStack(spacing: Spacing.sm) {
                            Text("Track Your Cycle")
                                .font(.h1) // 24pt, medium
                                .foregroundColor(.textPrimary)
                            
                            Text("Help us personalize your nutrition recommendations")
                                .font(.input) // 16pt, regular
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.xl)
                        }
                        .padding(.top, Spacing.xxl)
                        
                        // Last period date
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Last Period Start Date")
                                .font(.h3) // 18pt, medium
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, Spacing.md)
                            
                            DatePicker("", selection: $lastPeriodDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .padding(.horizontal, Spacing.md)
                        }
                        
                        // Phase selection
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Current Phase")
                                .font(.h3) // 18pt, medium
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, Spacing.md)
                            
                            VStack(spacing: Spacing.md) {
                                ForEach([CyclePhase.menstruation, .follicular, .ovulation, .luteal], id: \.self) { phase in
                                    CyclePhaseButton(phase: phase, isSelected: selectedPhase == phase) {
                                        HapticFeedback.selection()
                                        selectedPhase = phase
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                        
                        Spacer(minLength: Spacing.xl)
                        
                        // Save button - using DesignSystem
                        PrimaryButton(
                            title: "Save",
                            action: {
                                if let phase = selectedPhase {
                                    appState.user.cyclePhase = phase
                                }
                                HapticFeedback.success()
                                dismiss()
                            }
                        )
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xl)
                        .disabled(selectedPhase == nil)
                    }
                }
            }
            .navigationTitle("Cycle Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        HapticFeedback.selection()
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
}

// MARK: - Cycle Phase Button (DesignSystem aligned)
struct CyclePhaseButton: View {
    let phase: CyclePhase
    let isSelected: Bool
    let action: () -> Void
    
    var phaseInfo: (name: String, emoji: String, color: Color) {
        switch phase {
        case .menstruation: return ("Menstruation", "🌙", Color.error)
        case .follicular: return ("Follicular Phase", "🌱", Color.success)
        case .ovulation: return ("Ovulation", "✨", Color.warning)
        case .luteal: return ("Luteal Phase", "🍫", Color.calorieColor)
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Text(phaseInfo.emoji)
                    .font(.system(size: 32))
                
                Text(phaseInfo.name)
                    .font(.h3) // 18pt, medium
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                        .font(.system(size: 20))
                }
            }
            .padding(Spacing.md)
            .background(isSelected ? phaseInfo.color.opacity(0.1) : Color.white)
            .cornerRadius(Radius.md) // Button cornerRadius = 8
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md) // Button cornerRadius = 8
                    .stroke(isSelected ? phaseInfo.color : Color.textTertiary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

