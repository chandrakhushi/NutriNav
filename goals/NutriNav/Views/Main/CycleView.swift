//
//  CycleView.swift
//  NutriNav
//
//  Cycle-aware nutrition screen with automatic HealthKit integration
//  and manual fallback
//

import SwiftUI

struct CycleView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPeriodLogger = false
    @State private var showCycleSettings = false
    @State private var isLoading = false
    @State private var syncError: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Cycle Status Card
                        if appState.cycleData.lastPeriodStartDate != nil {
                            CycleStatusCard(
                                cycleData: appState.cycleData,
                                onSettingsTap: { showCycleSettings = true }
                            )
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.lg)
                        } else {
                            // No data - show setup card
                            CycleSetupCard(
                                onSyncHealthKit: syncWithHealthKit,
                                onLogManually: { showPeriodLogger = true },
                                isLoading: isLoading
                            )
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.lg)
                        }
                        
                        // Error message if any
                        if let error = syncError {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.calorieColor)
                                Text(error)
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(Spacing.md)
                            .background(Color.calorieColor.opacity(0.1))
                            .cornerRadius(Radius.md)
                            .padding(.horizontal, Spacing.md)
                        }
                        
                        // Nutrition Adjustments (if tracking)
                        if let phase = appState.cycleData.currentPhase {
                            CycleNutritionCard(phase: phase)
                                .padding(.horizontal, Spacing.md)
                        }
                        
                        // Cycle Tips
                        CycleTipsSection(phase: appState.cycleData.currentPhase)
                            .padding(.horizontal, Spacing.md)
                        
                        // Data Source & Actions
                        CycleActionsCard(
                            dataSource: appState.cycleData.dataSource,
                            onLogPeriod: { showPeriodLogger = true },
                            onResync: syncWithHealthKit
                        )
                        .padding(.horizontal, Spacing.md)
                        
                        // Privacy Note
                        PrivacyNote()
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .navigationTitle("Cycle Nutrition")
            .sheet(isPresented: $showPeriodLogger) {
                PeriodLoggerView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showCycleSettings) {
                CycleSettingsView()
                    .environmentObject(appState)
            }
        }
    }
    
    private func syncWithHealthKit() {
        isLoading = true
        syncError = nil
        
        Task {
            await appState.syncCycleData()
            
            await MainActor.run {
                isLoading = false
                if appState.cycleData.dataSource == .none {
                    syncError = "No cycle data found in Apple Health. Try logging manually."
                }
            }
        }
    }
}

// MARK: - Cycle Status Card

struct CycleStatusCard: View {
    let cycleData: CycleData
    let onSettingsTap: () -> Void
    
    private var phaseInfo: (name: String, emoji: String, color: Color) {
        guard let phase = cycleData.currentPhase else {
            return ("Unknown", "❓", .textSecondary)
        }
        switch phase {
        case .menstruation:
            return ("Menstruation", "🌙", Color(hex: "E91E63"))
        case .follicular:
            return ("Follicular", "🌱", Color(hex: "4CAF50"))
        case .ovulation:
            return ("Ovulation", "✨", Color(hex: "FF9800"))
        case .luteal:
            return ("Luteal", "🍫", Color(hex: "9C27B0"))
        }
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Phase Ring Visualization
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.textTertiary.opacity(0.2), lineWidth: 12)
                    .frame(width: 180, height: 180)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: cycleProgress)
                    .stroke(
                        LinearGradient(
                            colors: [phaseInfo.color, phaseInfo.color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                
                // Center content
                VStack(spacing: Spacing.xs) {
                    Text("Day")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    
                    Text("\(cycleData.currentCycleDay ?? 0)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.textPrimary)
                    
                    Text(phaseInfo.name)
                        .font(.input)
                        .foregroundColor(phaseInfo.color)
                }
            }
            .padding(.vertical, Spacing.md)
            
            // Next period prediction
            if let daysUntil = cycleData.daysUntilNextPeriod, daysUntil > 0 {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "calendar")
                        .foregroundColor(.textSecondary)
                    
                    if daysUntil == 1 {
                        Text("Period expected tomorrow")
                            .font(.input)
                            .foregroundColor(.textPrimary)
                    } else {
                        Text("Period expected in \(daysUntil) days")
                            .font(.input)
                            .foregroundColor(.textPrimary)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(Color.inputBackground)
                .cornerRadius(Radius.md)
            }
            
            // Cycle length info - tappable to edit
            Button(action: onSettingsTap) {
                HStack(spacing: Spacing.xl) {
                    VStack(spacing: Spacing.xs) {
                        Text("\(cycleData.averageCycleLength)")
                            .font(.h2)
                            .foregroundColor(.textPrimary)
                        Text("Cycle Length")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    VStack(spacing: Spacing.xs) {
                        Text("\(cycleData.averagePeriodLength)")
                            .font(.h2)
                            .foregroundColor(.textPrimary)
                        Text("Period Days")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.textTertiary)
                }
                .padding(Spacing.md)
                .background(Color.inputBackground)
                .cornerRadius(Radius.md)
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(Radius.lg)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var cycleProgress: Double {
        guard let cycleDay = cycleData.currentCycleDay else { return 0 }
        return min(1.0, Double(cycleDay) / Double(cycleData.averageCycleLength))
    }
}

// MARK: - Cycle Setup Card

struct CycleSetupCard: View {
    let onSyncHealthKit: () -> Void
    let onLogManually: () -> Void
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundColor(.primaryAccent)
            
            Text("Track Your Cycle")
                .font(.h1)
                .foregroundColor(.textPrimary)
            
            Text("Get personalized nutrition recommendations based on your menstrual cycle phase")
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)
            
            VStack(spacing: Spacing.md) {
                // HealthKit Option
                Button(action: onSyncHealthKit) {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.error)
                            .cornerRadius(Radius.md)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync with Apple Health")
                                .font(.h3)
                                .foregroundColor(.textPrimary)
                            Text("Automatic tracking from Health app")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.textTertiary)
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.inputBackground)
                    .cornerRadius(Radius.lg)
                }
                .disabled(isLoading)
                
                // Manual Option
                Button(action: onLogManually) {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.primaryAccent)
                            .cornerRadius(Radius.md)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Log Manually")
                                .font(.h3)
                                .foregroundColor(.textPrimary)
                            Text("Enter your last period date")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.textTertiary)
                    }
                    .padding(Spacing.md)
                    .background(Color.inputBackground)
                    .cornerRadius(Radius.lg)
                }
            }
        }
        .padding(Spacing.xl)
        .background(Color.cardBackground)
        .cornerRadius(Radius.lg)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Cycle Nutrition Card

struct CycleNutritionCard: View {
    let phase: CyclePhase
    
    private var adjustmentInfo: (calories: Int, message: String, tips: [String]) {
        switch phase {
        case .menstruation:
            return (
                -50,
                "Slightly reduced calories during menstruation",
                ["Focus on iron-rich foods", "Stay hydrated", "Gentle exercise is okay"]
            )
        case .follicular:
            return (
                0,
                "Standard nutrition goals",
                ["Great time for intense workouts", "Increase protein intake", "Energy levels rising"]
            )
        case .ovulation:
            return (
                +50,
                "Slight increase for peak energy",
                ["Peak energy phase", "Perfect for challenging workouts", "Stay well hydrated"]
            )
        case .luteal:
            return (
                +150,
                "Increased for higher metabolism",
                ["Cravings may increase", "Focus on complex carbs", "Magnesium-rich foods help"]
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Nutrition Adjustment")
                    .font(.h3)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if adjustmentInfo.calories != 0 {
                    Text(adjustmentInfo.calories > 0 ? "+\(adjustmentInfo.calories)" : "\(adjustmentInfo.calories)")
                        .font(.h3)
                        .foregroundColor(adjustmentInfo.calories > 0 ? .success : .calorieColor)
                    Text("cal")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Text(adjustmentInfo.message)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
            
            // Tips
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(adjustmentInfo.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.primaryAccent)
                        Text(tip)
                            .font(.bodySmall)
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .padding(.top, Spacing.xs)
            
            // Disclaimer
            Text("Estimated — based on cycle phase")
                .font(.caption)
                .foregroundColor(.textTertiary)
                .italic()
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(Radius.lg)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Cycle Tips Section

struct CycleTipsSection: View {
    let phase: CyclePhase?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Cycle Nutrition Tips")
                .font(.h3)
                .foregroundColor(.textPrimary)
            
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
                Text("Start tracking your cycle to get personalized tips")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(Radius.lg)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func tipsForPhase(_ phase: CyclePhase) -> [String] {
        switch phase {
        case .menstruation:
            return [
                "Eat iron-rich foods like spinach, lentils, and lean red meat",
                "Dark chocolate (70%+) can help with cramps",
                "Stay well hydrated - aim for extra water today"
            ]
        case .follicular:
            return [
                "Great time to try new, challenging workouts",
                "Focus on lean proteins for muscle recovery",
                "Fresh vegetables and light meals feel best now"
            ]
        case .ovulation:
            return [
                "Your metabolism is at its peak",
                "Great time for social meals and trying new foods",
                "Fiber-rich foods support hormonal balance"
            ]
        case .luteal:
            return [
                "Complex carbs help stabilize mood and energy",
                "Magnesium-rich foods (nuts, seeds) ease PMS",
                "It's okay to eat slightly more - your body needs it"
            ]
        }
    }
}

// MARK: - Cycle Actions Card

struct CycleActionsCard: View {
    let dataSource: CycleDataSource
    let onLogPeriod: () -> Void
    let onResync: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Data source indicator
            HStack(spacing: Spacing.sm) {
                Image(systemName: dataSource == .healthKit ? "heart.fill" : "hand.raised.fill")
                    .foregroundColor(dataSource == .healthKit ? .error : .primaryAccent)
                Text("Data Source: \(dataSource.rawValue)")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            
            Divider()
            
            // Actions
            Button(action: onLogPeriod) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(Color(hex: "E91E63"))
                    Text("Log Period")
                        .font(.input)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.textTertiary)
                }
            }
            
            if dataSource == .healthKit {
                Button(action: onResync) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.primaryAccent)
                        Text("Refresh from Apple Health")
                            .font(.input)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.textTertiary)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(Radius.lg)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Privacy Note

struct PrivacyNote: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "lock.shield.fill")
                .foregroundColor(.primaryAccent)
            
            Text("Your cycle data is stored only on this device and never shared with anyone.")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .padding(Spacing.md)
        .background(Color.primaryAccent.opacity(0.05))
        .cornerRadius(Radius.md)
    }
}

// MARK: - Period Logger View

struct PeriodLoggerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                VStack(spacing: Spacing.lg) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "E91E63").opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "drop.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color(hex: "E91E63"))
                        }
                        
                        Text("Log Period")
                            .font(.h1)
                            .foregroundColor(.textPrimary)
                        
                        Text("Select the first day of your period")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, Spacing.lg)
                    
                    // Custom Calendar Card
                    VStack(spacing: Spacing.md) {
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(Color(hex: "E91E63"))
                        .padding(Spacing.sm)
                    }
                    .background(Color.cardBackground)
                    .cornerRadius(Radius.lg)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, Spacing.md)
                    
                    // Selected Date Display
                    HStack {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "E91E63"))
                        
                        Text("Selected: \(selectedDate, style: .date)")
                            .font(.input)
                            .foregroundColor(.textPrimary)
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "E91E63").opacity(0.1))
                    .cornerRadius(Radius.md)
                    .padding(.horizontal, Spacing.md)
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: savePeriodStart) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Period")
                        }
                        .font(.h3)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color(hex: "E91E63"))
                        .cornerRadius(Radius.md)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.lg)
                }
            }
            .navigationTitle("Log Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    private func savePeriodStart() {
        appState.logPeriodStart(date: selectedDate)
        dismiss()
    }
}

// MARK: - Cycle Settings View

struct CycleSettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var cycleLength: Int = 28
    @State private var periodLength: Int = 5
    @State private var lastPeriodDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.primaryAccent)
                            
                            Text("Cycle Settings")
                                .font(.h1)
                                .foregroundColor(.textPrimary)
                            
                            Text("Customize your cycle to improve predictions")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, Spacing.lg)
                        
                        // Cycle Length Picker
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Average Cycle Length")
                                .font(.h3)
                                .foregroundColor(.textPrimary)
                            
                            Text("Typical range: 21-35 days")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                            
                            HStack {
                                Button(action: {
                                    if cycleLength > 21 {
                                        cycleLength -= 1
                                        HapticFeedback.selection()
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(cycleLength > 21 ? .primaryAccent : .textTertiary)
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Text("\(cycleLength)")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.textPrimary)
                                    Text("days")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    if cycleLength < 45 {
                                        cycleLength += 1
                                        HapticFeedback.selection()
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(cycleLength < 45 ? .primaryAccent : .textTertiary)
                                }
                            }
                            .padding(Spacing.lg)
                            .background(Color.inputBackground)
                            .cornerRadius(Radius.lg)
                        }
                        .padding(.horizontal, Spacing.md)
                        
                        // Period Length Picker
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Average Period Length")
                                .font(.h3)
                                .foregroundColor(.textPrimary)
                            
                            Text("Typical range: 3-7 days")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                            
                            HStack {
                                Button(action: {
                                    if periodLength > 2 {
                                        periodLength -= 1
                                        HapticFeedback.selection()
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(periodLength > 2 ? Color(hex: "E91E63") : .textTertiary)
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Text("\(periodLength)")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.textPrimary)
                                    Text("days")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    if periodLength < 10 {
                                        periodLength += 1
                                        HapticFeedback.selection()
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(periodLength < 10 ? Color(hex: "E91E63") : .textTertiary)
                                }
                            }
                            .padding(Spacing.lg)
                            .background(Color(hex: "E91E63").opacity(0.1))
                            .cornerRadius(Radius.lg)
                        }
                        .padding(.horizontal, Spacing.md)
                        
                        // Last Period Date
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Last Period Start Date")
                                .font(.h3)
                                .foregroundColor(.textPrimary)
                            
                            DatePicker(
                                "",
                                selection: $lastPeriodDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .tint(Color(hex: "E91E63"))
                            .padding(Spacing.md)
                            .background(Color.inputBackground)
                            .cornerRadius(Radius.lg)
                        }
                        .padding(.horizontal, Spacing.md)
                        
                        Spacer(minLength: Spacing.xl)
                    }
                }
                
                // Save Button at bottom
                VStack {
                    Spacer()
                    
                    Button(action: saveSettings) {
                        Text("Save Changes")
                            .font(.h3)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.primaryAccent)
                            .cornerRadius(Radius.md)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.lg)
                    .background(
                        LinearGradient(
                            colors: [Color.background.opacity(0), Color.background],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        .allowsHitTesting(false)
                    )
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
            .onAppear {
                cycleLength = appState.cycleData.averageCycleLength
                periodLength = appState.cycleData.averagePeriodLength
                lastPeriodDate = appState.cycleData.lastPeriodStartDate ?? Date()
            }
        }
    }
    
    private func saveSettings() {
        appState.cycleData.averageCycleLength = cycleLength
        appState.cycleData.averagePeriodLength = periodLength
        appState.cycleData.lastPeriodStartDate = lastPeriodDate
        appState.cycleData.dataSource = .manual
        appState.cycleData.lastUpdated = Date()
        HapticFeedback.success()
        dismiss()
    }
}
