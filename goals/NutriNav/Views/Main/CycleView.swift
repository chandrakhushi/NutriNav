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
            ScrollView {
                VStack(spacing: 20) {
                    // Cycle Phase Card
                    if let cyclePhase = appState.user.cyclePhase {
                        CyclePhaseCard(phase: cyclePhase)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    } else {
                        NoCycleDataCard {
                            showCycleEditor = true
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // Nutrition Adjustments
                    if let cyclePhase = appState.user.cyclePhase {
                        CycleNutritionAdjustments(phase: cyclePhase, nutrition: appState.dailyNutrition)
                            .padding(.horizontal, 20)
                    }
                    
                    // Cycle Tips
                    CycleTipsCard(phase: appState.user.cyclePhase)
                        .padding(.horizontal, 20)
                    
                    // Sync with HealthKit
                    if appState.user.gender == .female {
                        HealthKitCycleSyncCard {
                            Task {
                                await appState.syncHealthKitData()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Cycle Nutrition")
            .sheet(isPresented: $showCycleEditor) {
                CycleEditorView()
                    .environmentObject(appState)
            }
        }
    }
}

struct CyclePhaseCard: View {
    let phase: CyclePhase
    
    var phaseInfo: (name: String, emoji: String, color: Color, description: String) {
        switch phase {
        case .menstruation:
            return ("Menstruation", "🌙", Color.red, "Days 1-5: Focus on iron-rich foods and rest")
        case .follicular:
            return ("Follicular Phase", "🌱", Color.green, "Days 6-13: Energy is rising, great for workouts")
        case .ovulation:
            return ("Ovulation", "✨", Color.yellow, "Days 14-16: Peak energy, maximize nutrition")
        case .luteal:
            return ("Luteal Phase", "🍫", Color.orange, "Days 17+: Cravings may increase, focus on balance")
        }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(phaseInfo.emoji)
                            .font(.system(size: 32))
                        Text(phaseInfo.name)
                            .font(.system(size: 24, weight: .bold))
                    }
                    
                    Text(phaseInfo.description)
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            
            // Cycle progress indicator
            CycleProgressIndicator(phase: phase)
        }
        .padding(20)
        .background(phaseInfo.color.opacity(0.1))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(phaseInfo.color.opacity(0.3), lineWidth: 2)
        )
    }
}

struct CycleProgressIndicator: View {
    let phase: CyclePhase
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach([CyclePhase.menstruation, .follicular, .ovulation, .luteal], id: \.self) { p in
                Circle()
                    .fill(p == phase ? Color.appPurple : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NoCycleDataCard: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(.appPink)
            
            Text("Track Your Cycle")
                .font(.system(size: 24, weight: .bold))
            
            Text("Sync with HealthKit or enter manually to get personalized nutrition recommendations")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: action) {
                Text("Get Started")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.appPink)
                    .cornerRadius(15)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(Color.appPink.opacity(0.1))
        .cornerRadius(15)
    }
}

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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 8) {
                Text("📊")
                    .font(.system(size: 24))
                Text("Adjusted Nutrition Goals")
                    .font(.system(size: 20, weight: .bold))
            }
            
            if adjustments.calories > 0 || adjustments.protein > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    if adjustments.calories > 0 {
                        AdjustmentRow(
                            icon: "flame.fill",
                            label: "Calories",
                            adjustment: "+\(Int(adjustments.calories))",
                            color: .orange
                        )
                    }
                    
                    if adjustments.protein > 0 {
                        AdjustmentRow(
                            icon: "figure.strengthtraining.traditional",
                            label: "Protein",
                            adjustment: "+\(Int(adjustments.protein))g",
                            color: .blue
                        )
                    }
                }
                
                Text(adjustments.message)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .padding(.top, 5)
            } else {
                Text("Your nutrition goals are optimized for this phase")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(15)
    }
}

struct AdjustmentRow: View {
    let icon: String
    let label: String
    let adjustment: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 16))
            
            Spacer()
            
            Text(adjustment)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
    }
}

struct CycleTipsCard: View {
    let phase: CyclePhase?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 8) {
                Text("💡")
                    .font(.system(size: 24))
                Text("Cycle Nutrition Tips")
                    .font(.system(size: 20, weight: .bold))
            }
            
            if let phase = phase {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(tipsForPhase(phase), id: \.self) { tip in
                        HStack(alignment: .top, spacing: 10) {
                            Text("•")
                                .foregroundColor(.appPink)
                            Text(tip)
                                .font(.system(size: 14))
                        }
                    }
                }
            } else {
                Text("Track your cycle to get personalized nutrition tips")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.appPink.opacity(0.1), Color.appPurple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
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

struct HealthKitCycleSyncCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 24))
                    .foregroundColor(.appPink)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync with HealthKit")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Automatically track your cycle from Apple Health")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
            .padding(15)
            .background(Color.cardBackground)
            .cornerRadius(15)
        }
    }
}

struct CycleEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedPhase: CyclePhase?
    @State private var lastPeriodDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Text("Track Your Cycle")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Help us personalize your nutrition recommendations")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                
                // Last period date
                VStack(alignment: .leading, spacing: 10) {
                    Text("Last Period Start Date")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal, 20)
                    
                    DatePicker("", selection: $lastPeriodDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal, 20)
                }
                
                // Phase selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current Phase")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        ForEach([CyclePhase.menstruation, .follicular, .ovulation, .luteal], id: \.self) { phase in
                            CyclePhaseButton(phase: phase, isSelected: selectedPhase == phase) {
                                selectedPhase = phase
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                Button(action: {
                    if let phase = selectedPhase {
                        appState.user.cyclePhase = phase
                    }
                    dismiss()
                }) {
                    Text("Save")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appPink)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .disabled(selectedPhase == nil)
                .opacity(selectedPhase == nil ? 0.6 : 1.0)
            }
            .navigationTitle("Cycle Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CyclePhaseButton: View {
    let phase: CyclePhase
    let isSelected: Bool
    let action: () -> Void
    
    var phaseInfo: (name: String, emoji: String, color: Color) {
        switch phase {
        case .menstruation: return ("Menstruation", "🌙", Color.red)
        case .follicular: return ("Follicular Phase", "🌱", Color.green)
        case .ovulation: return ("Ovulation", "✨", Color.yellow)
        case .luteal: return ("Luteal Phase", "🍫", Color.orange)
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Text(phaseInfo.emoji)
                    .font(.system(size: 32))
                
                Text(phaseInfo.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(15)
            .background(isSelected ? phaseInfo.color.opacity(0.1) : Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? phaseInfo.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

