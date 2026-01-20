//
//  HomeView.swift
//  NutriNav
//
//  Main dashboard/home screen - using DesignSystem
//

import SwiftUI

// MARK: - Navigation Route Enum
enum HomeRoute: Hashable {
    case log(mealType: MealType?)
    case checkin
    case bodySignals
    case mealDetails(mealType: MealType)
    case logRecipe(mealType: MealType)
}

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showNutritionDetails = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.background.ignoresSafeArea() // Design System: background = #ffffff
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header Section
                        headerSection
                            .padding(.top, Spacing.xxl)
                        
                        // Daily Summary Cards (Streak, Water, Steps)
                        dailySummaryCards
                            .padding(.horizontal, Spacing.md)
                        
                        // Calories & Macros Section
                        caloriesAndMacrosSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Today's Meals Section
                        todaysMealsSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Log Food or Workout Button
                        logFoodButton
                            .padding(.horizontal, Spacing.md)
                        
                        // Weekly Progress Section
                        weeklyProgressSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Today's Insight
                        todaysInsightCard
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .navigationDestination(for: HomeRoute.self) { destination in
                switch destination {
                case .log(let mealType):
                    LogFoodView(initialMealType: mealType)
                        .environmentObject(appState)
                case .checkin:
                    DailyCheckInView()
                        .environmentObject(appState)
                case .bodySignals:
                    BodySignalsView()
                        .environmentObject(appState)
                case .mealDetails(let mealType):
                    MealDetailsView(mealType: mealType)
                        .environmentObject(appState)
                case .logRecipe(let mealType):
                    LogRecipeFromMealView(initialMealType: mealType)
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showNutritionDetails) {
                NutritionDetailsView()
                    .environmentObject(appState)
            }
        }
    }
    
    // MARK: - Header Section (Design System: h1=24pt medium)
    private var headerSection: some View {
                VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(timeBasedGreeting)
                .font(.h1) // 24pt, medium
                        .foregroundColor(.textPrimary)
                    
            Text("Here's your day at a glance")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }
    
    // MARK: - Time-Based Greeting
    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Good night"
        }
    }
    
    // MARK: - Protein Insight Text
    private var proteinInsightText: String {
        let remainingProtein = max(0, appState.dailyNutrition.protein.target - appState.dailyNutrition.protein.current)
        if remainingProtein == 0 {
            return "You've hit your protein goal! Great job! 🎉"
        } else {
            return "You're \(Int(remainingProtein))g protein away from your goal. Keep it up!"
        }
    }
    
    // MARK: - Daily Summary Cards (Streak, Water, Steps)
    private var dailySummaryCards: some View {
        HStack(spacing: Spacing.md) {
            // Streak Card (Orange)
            summaryCard(
                icon: "flame.fill",
                title: "Streak",
                value: "\(appState.currentStreak.currentDays)",
                subtitle: "days",
                color: Color(hex: "FF9800"),
                backgroundColor: Color(hex: "FFF3E0")
            )
            
            // Water Card (Blue)
            summaryCard(
                icon: "drop.fill",
                title: "Water",
                value: "6/8",
                subtitle: "glasses",
                color: Color(hex: "2196F3"),
                backgroundColor: Color(hex: "E3F2FD")
            )
            
            // Steps Card (Green)
            summaryCard(
                icon: "figure.walk",
                title: "Steps",
                value: formatSteps(appState.todaySteps),
                subtitle: "\(Int((appState.todaySteps / 10000) * 100))% goal",
                color: Color(hex: "4CAF50"),
                backgroundColor: Color(hex: "E8F5E9")
            )
        }
    }
    
    private func summaryCard(icon: String, title: String, value: String, subtitle: String, color: Color, backgroundColor: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(title)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(backgroundColor)
        .cornerRadius(Radius.lg)
    }
    
    private func formatSteps(_ steps: Double) -> String {
        if steps >= 1000 {
            let kValue = steps / 1000
            // Format to show one decimal place, but remove trailing zero
            if kValue.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(kValue))k"
            } else {
                return String(format: "%.1fk", kValue)
            }
        }
        return "\(Int(steps))"
    }
    
    // MARK: - Calories & Macros Section
    private var caloriesAndMacrosSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Calories & Macros")
                    .font(.h2) // 20pt, medium
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                let remaining = max(0, appState.dailyNutrition.calories.target - appState.dailyNutrition.calories.current)
                Text("\(Int(remaining)) cal left")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            
            PrimaryCard {
                VStack(spacing: Spacing.lg) {
                    // Large Calorie Progress Ring
                    calorieProgressRing
                    
                    // Three Macro Rings (Protein, Carbs, Fat)
                    macroRingsRow
                }
            }
        }
    }
    
    private var calorieProgressRing: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.textTertiary.opacity(0.2), lineWidth: 16)
                .frame(width: 160, height: 160)
            
            // Progress ring
            let percentage = appState.dailyNutrition.calories.target > 0 ? min(appState.dailyNutrition.calories.current / appState.dailyNutrition.calories.target, 1.0) : 0
            Circle()
                .trim(from: 0, to: percentage)
                .stroke(
                    Color.calorieColor,
                    style: StrokeStyle(
                        lineWidth: 16,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 160, height: 160)
            
            // Center text
            VStack(spacing: 2) {
                Text("\(Int(appState.dailyNutrition.calories.current))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text("of \(Int(appState.dailyNutrition.calories.target)) cal")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
    }
    
    private var macroRingsRow: some View {
        HStack(spacing: Spacing.lg) {
            macroRing(
                value: appState.dailyNutrition.protein.current,
                target: appState.dailyNutrition.protein.target,
                label: "Protein",
                color: .proteinColor
            )
            
            macroRing(
                value: appState.dailyNutrition.carbs.current,
                target: appState.dailyNutrition.carbs.target,
                label: "Carbs",
                color: .carbColor
            )
            
            macroRing(
                value: appState.dailyNutrition.fats.current,
                target: appState.dailyNutrition.fats.target,
                label: "Fat",
                color: .fatColor
            )
        }
    }
    
    private func macroRing(value: Double, target: Double, label: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.textTertiary.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                // Progress ring
                let percentage = target > 0 ? min(value / target, 1.0) : 0
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: 8,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 80, height: 80)
            }
            
            Text("\(Int(value))g")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.textPrimary)
            
            Text(label)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Today's Meals Section
    private var todaysMealsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Today's Meals")
                .font(.h2) // 20pt, medium
                .foregroundColor(.textPrimary)
            
            PrimaryCard {
                VStack(spacing: 0) {
                    mealRow(mealType: .breakfast)
                    Divider().background(Color.textTertiary.opacity(0.2))
                    mealRow(mealType: .lunch)
                    Divider().background(Color.textTertiary.opacity(0.2))
                    mealRow(mealType: .dinner)
                    Divider().background(Color.textTertiary.opacity(0.2))
                    mealRow(mealType: .snacks)
                }
            }
        }
    }
    
    private func mealRow(mealType: MealType) -> some View {
        let mealData = getMealData(mealType: mealType)
        let isLogged = mealData.calories != nil
        
        return Button(action: {
            HapticFeedback.selection()
            if isLogged {
                // Show meal details
                navigationPath.append(HomeRoute.mealDetails(mealType: mealType))
            } else {
                // Navigate to log food with meal type pre-selected
                navigationPath.append(HomeRoute.log(mealType: mealType))
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(mealType.rawValue)
                        .font(.input)
                        .foregroundColor(.textPrimary)
                    
                    if let time = mealData.time {
                        Text(time)
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    } else {
                        Text("Not logged")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                if let calories = mealData.calories {
                    HStack(spacing: Spacing.xs) {
                        Text("\(Int(calories)) cal")
                            .font(.input)
                            .foregroundColor(.textPrimary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 16))
                        .foregroundColor(.primaryAccent)
                }
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getMealData(mealType: MealType) -> (calories: Double?, time: String?) {
        let today = Calendar.current.startOfDay(for: Date())
        let todayLog = appState.foodLogs.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        
        // Filter entries by meal type
        let mealEntries = todayLog?.entries.filter { $0.mealType == mealType } ?? []
        
        guard !mealEntries.isEmpty else {
            return (nil, nil)
        }
        
        // Calculate total calories
        let totalCalories = mealEntries.reduce(0) { $0 + $1.calories }
        
        // Get the most recent entry time
        let mostRecentEntry = mealEntries.max(by: { $0.timestamp < $1.timestamp })
        let timeString = mostRecentEntry.map { formatTime($0.timestamp) }
        
        return (totalCalories, timeString)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Log Food Button
    private var logFoodButton: some View {
        Button(action: {
            HapticFeedback.impact()
            navigationPath.append(HomeRoute.log(mealType: nil))
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Log Food or Workout")
                        .font(.h3) // 18pt, medium
                        .foregroundColor(.white)
                    
                    Text("Track what you ate or how you moved")
                        .font(.bodySmall)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
            }
            .padding(Spacing.md)
            .background(
                LinearGradient(
                    colors: [Color(hex: "22C55E"), Color(hex: "16A34A")], // green-500 to green-600
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(Radius.lg)
            .shadow(
                color: Shadow.button.color,
                radius: Shadow.button.radius,
                x: Shadow.button.x,
                y: Shadow.button.y
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Weekly Progress Section
    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "9C27B0"))
                
                Text("Weekly Progress")
                    .font(.h3) // 18pt, medium
                    .foregroundColor(Color(hex: "9C27B0"))
            }
            
            Text("You're on track with your goals")
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
            
            // Days of week
            HStack(spacing: Spacing.sm) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.bodySmall)
                        .foregroundColor(Color(hex: "9C27B0"))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.md)
        .background(Color(hex: "F3E5F5"))
        .cornerRadius(Radius.lg)
    }
    
    // MARK: - Calories Burned Row (separate stat, not affecting target)
    private var caloriesBurnedRow: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.calorieColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.calorieColor)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Calories Burned")
                    .font(.input) // 16pt, regular
                    .foregroundColor(.textPrimary)
                
                Text("\(Int(appState.todayActiveCalories)) cal")
                    .font(.input) // 16pt, regular
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
            
            // Optional: Show net calories as secondary insight
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text("Net")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                
                let netCalories = appState.netCalories
                Text("\(Int(netCalories))")
                    .font(.input) // 16pt, regular
                    .foregroundColor(netCalories >= 0 ? .calorieColor : .textSecondary)
            }
        }
    }
    
    // MARK: - Nutrition Progress Row with Circular Ring (Design System: input=16pt regular)
    private func nutritionProgressRow(
        title: String,
        current: Double,
        target: Double,
        color: Color
    ) -> some View {
        HStack(spacing: Spacing.md) {
            // Circular progress ring with percentage
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.textTertiary.opacity(0.2), lineWidth: 10)
                
                // Progress ring - shows color based on progress
                let percentage = target > 0 ? min(current / target, 1.0) : 0
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: 10,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                
                // Percentage in center
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
            .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.input) // 16pt, regular
                    .foregroundColor(.textPrimary)
                
                // Show units for protein: "65g / 120g" instead of "65 / 120"
                if title == "Protein" {
                    Text("\(Int(current))g / \(Int(target))g")
                        .font(.input) // 16pt, regular
                        .foregroundColor(.textPrimary)
                } else {
                    Text("\(Int(current)) / \(Int(target))")
                        .font(.input) // 16pt, regular
                        .foregroundColor(.textPrimary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text("Remaining")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                
                // Clamp remaining values so they never go negative
                let remaining = max(0, target - current)
                Text(title == "Calories" ? "\(Int(remaining))" : "\(Int(remaining))g")
                    .font(.input) // 16pt, regular
                    .foregroundColor(color)
            }
        }
    }
    
    // MARK: - Primary Actions Section
    private var primaryActionsSection: some View {
        VStack(spacing: Spacing.md) {
            // Log Food or Workout - Primary action with green gradient
            Button(action: {
                HapticFeedback.impact()
                navigationPath.append(HomeRoute.log(mealType: nil))
            }) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Log Food or Workout")
                            .font(.h3) // 18pt, medium
                            .foregroundColor(.white)
                        
                        Text("Track what you ate or how you moved")
                            .font(.bodySmall)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                }
                .padding(16) // Card.padding = 16
                .background(
                    LinearGradient(
                        colors: [Color(hex: "22C55E"), Color(hex: "16A34A")], // green-500 to green-600
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(Radius.lg) // Card.cornerRadius = Radius.lg (10)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Daily Check-In card
            Button(action: {
                HapticFeedback.selection()
                navigationPath.append(HomeRoute.checkin)
            }) {
                PrimaryCard {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "9C27B0")) // Purple
                            .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Daily Check-In")
                                .font(.h3) // 18pt, medium
                                .foregroundColor(.textPrimary)
                            
                            Text("Log a moment from today")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Body Signals card
            Button(action: {
                HapticFeedback.selection()
                navigationPath.append(HomeRoute.bodySignals)
            }) {
                PrimaryCard {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "waveform.path")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "4CAF50")) // Light green
                            .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Body Signals")
                                .font(.h3) // 18pt, medium
                                .foregroundColor(.textPrimary)
                            
                            Text("Recovery phase · Energy may vary")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Today's Insight (Design System: h3=18pt medium, card padding=16, cornerRadius=lg=10)
    private var todaysInsightCard: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24))
                .foregroundColor(Color(hex: "FF9800")) // Orange
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Today's Insight")
                    .font(.h3) // 18pt, medium
                    .foregroundColor(.textPrimary)
                
                // Clamp remainingProtein to 0 minimum, show positive reinforcement if goal is hit
                Text(proteinInsightText)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(16) // Card.padding = 16
        .background(Color(hex: "FFF3E0")) // Light orange/beige background
        .cornerRadius(Radius.lg) // Card.cornerRadius = Radius.lg (10)
    }
}

// MARK: - Navigation Destination Views

// MARK: - Log Food or Workout View (Design System: h1=24pt medium)
struct LogFoodWorkoutView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        Text("Log Food or Workout")
                            .font(.h1) // 24pt, medium
                            .foregroundColor(.textPrimary)
                        
                        Text("Track your meals and activities")
                            .font(.input) // 16pt, regular
                            .foregroundColor(.textSecondary)
                    }
                    .padding(Spacing.xl)
                }
            }
            .navigationTitle("Log Food or Workout")
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

// MARK: - Daily Check-In View (Design System: h1=24pt medium)
struct DailyCheckInView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        Text("Daily Check-In")
                            .font(.h1) // 24pt, medium
                            .foregroundColor(.textPrimary)
                        
                        Text("Log a moment from today")
                            .font(.input) // 16pt, regular
                            .foregroundColor(.textSecondary)
                    }
                    .padding(Spacing.xl)
                }
            }
            .navigationTitle("Daily Check-In")
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

// MARK: - Body Signals View (Design System: h1=24pt medium)
struct BodySignalsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        Text("Body Signals")
                            .font(.h1) // 24pt, medium
                            .foregroundColor(.textPrimary)
                        
                        Text("Track your body's signals and recovery")
                            .font(.input) // 16pt, regular
                            .foregroundColor(.textSecondary)
                    }
                    .padding(Spacing.xl)
                }
            }
            .navigationTitle("Body Signals")
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

// MARK: - Log Recipe From Meal View
struct LogRecipeFromMealView: View {
    @EnvironmentObject var appState: AppState
    let initialMealType: MealType
    
    var body: some View {
        RecipesView(initialMealType: initialMealType)
            .environmentObject(appState)
            .navigationTitle("Find Recipe")
    }
}

// MARK: - Meal Details View
struct MealDetailsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let mealType: MealType
    
    private var mealEntries: [FoodEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        let todayLog = appState.foodLogs.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        return (todayLog?.entries.filter { $0.mealType == mealType } ?? []).sorted { $0.timestamp > $1.timestamp }
    }
    
    private var totalCalories: Double {
        mealEntries.reduce(0) { $0 + $1.calories }
    }
    
    private var totalProtein: Double {
        mealEntries.reduce(0) { $0 + $1.protein }
    }
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header with totals
                    VStack(spacing: Spacing.md) {
                        Text(mealType.rawValue)
                            .font(.h1)
                            .foregroundColor(.textPrimary)
                        
                        if !mealEntries.isEmpty {
                            HStack(spacing: Spacing.lg) {
                                VStack(spacing: Spacing.xs) {
                                    Text("\(Int(totalCalories))")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.calorieColor)
                                    Text("Calories")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                VStack(spacing: Spacing.xs) {
                                    Text("\(Int(totalProtein))g")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.proteinColor)
                                    Text("Protein")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            .padding(.top, Spacing.sm)
                        }
                    }
                    .padding(.top, Spacing.md)
                    .padding(.horizontal, Spacing.md)
                    
                    // Food entries list
                    if mealEntries.isEmpty {
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 48))
                                .foregroundColor(.textTertiary)
                            Text("No items logged for \(mealType.rawValue)")
                                .font(.input)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, Spacing.xxl)
                    } else {
                        VStack(spacing: Spacing.sm) {
                            ForEach(mealEntries) { entry in
                                foodEntryRow(entry: entry)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }
                .padding(.bottom, Spacing.xl)
            }
        }
        .navigationTitle(mealType.rawValue)
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
    
    private func foodEntryRow(entry: FoodEntry) -> some View {
        PrimaryCard {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(entry.name)
                        .font(.input)
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: Spacing.sm) {
                        Text("\(Int(entry.calories)) cal")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                        
                        if entry.protein > 0 {
                            Text("• \(Int(entry.protein))g protein")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                        
                        if let servingSize = entry.servingSize {
                            Text("• \(servingSize)")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Text(formatTime(entry.timestamp))
                        .font(.bodySmall)
                        .foregroundColor(.textTertiary)
                }
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.selection()
                    appState.removeFoodEntry(entry)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.destructive)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
