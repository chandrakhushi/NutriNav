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
                        
                        // Calories Section
                        caloriesSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Macros Breakdown Section
                        macrosBreakdownSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Steps and Water Section
                        stepsAndWaterSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Today's Meals Section
                        todaysMealsSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Log Food Button
                        logFoodButton
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
    
    // MARK: - Header Section (matching React design)
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Top row with date and actions
            HStack {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                    Text(formattedDateShort)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Streak and plus button
                HStack(spacing: Spacing.md) {
                    // Streak display (red background matching React)
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                        Text("\(appState.currentStreak.currentDays)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 6)
                    .background(Color(hex: "FEF2F2")) // red-50
                    .cornerRadius(20)
                    
                    Button(action: {
                        HapticFeedback.impact()
                        navigationPath.append(HomeRoute.log(mealType: nil))
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black)
                            .clipShape(Circle())
                    }
                }
            }
            
            // Log count
            Text("\(todayLogCount) LOGS TODAY")
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }
    
    // MARK: - Formatted Date Short (matching React)
    private var formattedDateShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "'Today,' d MMMM"
        return formatter.string(from: Date())
    }
    
    
    // MARK: - Today Log Count
    private var todayLogCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let todayLog = appState.foodLogs.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        return todayLog?.entries.count ?? 0
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
    
    // MARK: - Calories Section (matching React design)
    private var caloriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Calories KCAL")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "D1D5DB")) // gray-300
            }
            
            PrimaryCard {
                VStack(spacing: Spacing.xl) {
                    // Semi-circular gauge
                    calorieGauge
                    
                    // Legend (matching React - horizontal layout)
                    HStack(spacing: Spacing.lg) {
                        HStack(spacing: Spacing.xs) {
                            Circle()
                                .fill(Color(hex: "14B8A6")) // teal-500
                                .frame(width: 8, height: 8)
                            Text("Consumed \(Int(appState.dailyNutrition.calories.current))kcal")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                        
                        HStack(spacing: Spacing.xs) {
                            Circle()
                                .fill(Color(hex: "D1D5DB")) // gray-300
                                .frame(width: 8, height: 8)
                            Text("Base \(Int(appState.dailyNutrition.calories.target))kcal")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
            .cornerRadius(24) // rounded-3xl matching React
        }
    }
    
    // MARK: - Calorie Gauge (Speed dial style - matching React design)
    private var calorieGauge: some View {
        let remaining = max(0, appState.dailyNutrition.calories.target - appState.dailyNutrition.calories.current)
        let consumed = appState.dailyNutrition.calories.current
        let base = appState.dailyNutrition.calories.target
        let gaugePercentage = base > 0 ? (consumed / base) * 100 : 0
        let gaugeAngle = min((gaugePercentage / 100) * 180, 180)
        
        return GeometryReader { geometry in
            ZStack {
                // SVG-style gauge with lines from -180 to 0 degrees
                GaugeView(
                    gaugeAngle: gaugeAngle,
                    filledColor: Color(hex: "14B8A6"), // Teal
                    emptyColor: Color(hex: "E5E7EB") // Light gray
                )
                .frame(height: 160)
                
                // Center text (positioned in the lower part of semi-circle)
                VStack(spacing: 4) {
                    Text("\(Int(remaining))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text("calories remaining")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.75) // 75% down from top
            }
        }
        .frame(height: 160)
        .padding(.vertical, Spacing.md)
    }
    
    // MARK: - Macros Breakdown Section
    private var macrosBreakdownSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(Color(hex: "14B8A6"))
                        .frame(width: 8, height: 8)
                    Text("Macros Breakdown")
                        .font(.h2) // 20pt, medium
                        .foregroundColor(.textPrimary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            
            PrimaryCard {
                HStack(spacing: Spacing.md) {
                    // Macros vertical layout (compressed spacing)
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        macroRowVertical(
                            name: "Carbs",
                            value: appState.dailyNutrition.carbs.current,
                            target: appState.dailyNutrition.carbs.target,
                            color: Color(hex: "10B981") // Green
                        )
                        
                        macroRowVertical(
                            name: "Protein",
                            value: appState.dailyNutrition.protein.current,
                            target: appState.dailyNutrition.protein.target,
                            color: Color(hex: "F97316") // Orange
                        )
                        
                        macroRowVertical(
                            name: "Fat",
                            value: appState.dailyNutrition.fats.current,
                            target: appState.dailyNutrition.fats.target,
                            color: Color(hex: "3B82F6") // Blue
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Three concentric rings (outer, middle, inner)
                    concentricMacroRings
                        .frame(width: 128, height: 128)
                }
            }
            .cornerRadius(24) // rounded-3xl matching React
        }
    }
    
    private func macroRowVertical(name: String, value: Double, target: Double, color: Color) -> some View {
        let percentage = target > 0 ? Int((value / target) * 100) : 0
        
        return VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
            Text("\(Int(value))g")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            Text("\(percentage)%")
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
        }
    }
    
    private var concentricMacroRings: some View {
        let carbs = appState.dailyNutrition.carbs.current
        let protein = appState.dailyNutrition.protein.current
        let fat = appState.dailyNutrition.fats.current
        
        let carbsTarget = appState.dailyNutrition.carbs.target
        let proteinTarget = appState.dailyNutrition.protein.target
        let fatTarget = appState.dailyNutrition.fats.target
        
        let carbsPercentage = carbsTarget > 0 ? min(carbs / carbsTarget, 1.0) : 0
        let proteinPercentage = proteinTarget > 0 ? min(protein / proteinTarget, 1.0) : 0
        let fatPercentage = fatTarget > 0 ? min(fat / fatTarget, 1.0) : 0
        
        return ZStack {
            // Carbs ring (outer) - radius 58
            Circle()
                .stroke(Color(hex: "E5E7EB"), lineWidth: 8)
                .frame(width: 116, height: 116)
            Circle()
                .trim(from: 0, to: carbsPercentage)
                .stroke(
                    Color(hex: "10B981"),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 116, height: 116)
            
            // Protein ring (middle) - radius 46
            Circle()
                .stroke(Color(hex: "E5E7EB"), lineWidth: 8)
                .frame(width: 92, height: 92)
            Circle()
                .trim(from: 0, to: proteinPercentage)
                .stroke(
                    Color(hex: "F97316"),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 92, height: 92)
            
            // Fat ring (inner) - radius 34
            Circle()
                .stroke(Color(hex: "E5E7EB"), lineWidth: 8)
                .frame(width: 68, height: 68)
            Circle()
                .trim(from: 0, to: fatPercentage)
                .stroke(
                    Color(hex: "3B82F6"),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 68, height: 68)
        }
    }
    
    // MARK: - Steps and Water Section
    private var stepsAndWaterSection: some View {
        PrimaryCard {
            HStack(spacing: Spacing.md) {
                // Steps Card
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "4CAF50"))
                        Text("Steps")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Text(formatSteps(appState.todaySteps))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.textPrimary)
                    
                    Text("\(Int((appState.todaySteps / 10000) * 100))% goal")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .background(Color(hex: "E8F5E9"))
                .cornerRadius(Radius.lg)
                
                // Water Card
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "2196F3"))
                        Text("Water")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Text("6/8")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.textPrimary)
                    
                    Text("glasses")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .background(Color(hex: "E3F2FD"))
                .cornerRadius(Radius.lg)
            }
        }
        .cornerRadius(24) // rounded-3xl matching React
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

// MARK: - Gauge View Component (matching React SVG design)
struct GaugeView: View {
    let gaugeAngle: Double // Angle from -180 to 0 degrees
    let filledColor: Color
    let emptyColor: Color
    
    private let lineCount = 40 // Number of lines (matching React)
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerX = width / 2
            let centerY = height // Bottom center
            let innerRadius: CGFloat = width * 0.39 // ~110 for 280 width
            let outerRadius: CGFloat = width * 0.43 // ~120 for 280 width
            
            ZStack {
                // Draw lines from -180 to 0 degrees (matching React)
                ForEach(0..<lineCount, id: \.self) { index in
                    let angle = -180.0 + (Double(index) * 4.5) // 4.5 degrees per line
                    let isActive = angle <= (gaugeAngle - 180.0)
                    let radians = angle * .pi / 180.0
                    
                    // Calculate line endpoints
                    let x1 = centerX + innerRadius * cos(radians)
                    let y1 = centerY + innerRadius * sin(radians)
                    let x2 = centerX + outerRadius * cos(radians)
                    let y2 = centerY + outerRadius * sin(radians)
                    
                    Path { path in
                        path.move(to: CGPoint(x: x1, y: y1))
                        path.addLine(to: CGPoint(x: x2, y: y2))
                    }
                    .stroke(
                        isActive ? filledColor : emptyColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                }
            }
        }
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
