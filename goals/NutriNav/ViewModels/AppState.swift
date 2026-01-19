//
//  AppState.swift
//  NutriNav
//
//  Global app state management
//

import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var user: User
    @Published var dailyNutrition: DailyNutrition
    @Published var currentStreak: Streak
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedTab: TabItem = .home
    
    // HealthKit integration
    let healthKitService = HealthKitService.shared
    @Published var todaySteps: Double = 0
    @Published var todayActiveCalories: Double = 0
    @Published var todayWorkouts: [Activity] = []
    
    // Budget tracking
    @Published var budget = Budget(weeklyBudget: 100.0, currentWeekSpending: 45.50)
    @Published var expenses: [MealExpense] = []
    
    // Hobbies and activities
    @Published var hobbies: [Hobby] = []
    
    // Food logging
    @Published var foodLogs: [FoodLog] = []
    @Published var weeklyFoodLog: FoodLog?
    
    // Body metrics (calculated)
    @Published var bodyMetrics: BodyMetrics?
    
    // Services
    let bodyMetricsService = BodyMetricsService.shared
    let nutritionLogicService = NutritionLogicService.shared
    let lazyDayService = LazyDayService.shared
    let workoutRecommendationService = WorkoutRecommendationService.shared
    
    // Analytics
    let analyticsService = AnalyticsService.shared
    let subscriptionService = SubscriptionService.shared
    
    init() {
        // Initialize with default/mock data
        var defaultUser = User()
        defaultUser.name = "Sarah Johnson"
        defaultUser.email = "sarah.j@email.com"
        defaultUser.age = 23
        defaultUser.gender = .female
        defaultUser.height = 164
        defaultUser.weight = 65
        defaultUser.activityLevel = .moderatelyActive
        defaultUser.goal = .glowUp
        
        self.user = defaultUser
        
        // Initialize currentStreak first
        self.currentStreak = Streak(currentDays: 7, lastDate: Date())
        
        // Calculate body metrics
        if let age = defaultUser.age,
           let gender = defaultUser.gender,
           let height = defaultUser.height,
           let weight = defaultUser.weight,
           let activityLevel = defaultUser.activityLevel,
           let goal = defaultUser.goal {
            
            // Calculate body metrics
            self.bodyMetrics = bodyMetricsService.calculateAllMetrics(
                weight: weight,
                height: height,
                age: age,
                gender: gender,
                activityLevel: activityLevel,
                activeCalories: 0 // Will update when HealthKit data loads
            )
            
            // Calculate nutrition goals using real formulas
            var calculatedNutrition = NutritionStats.calculateGoals(
                age: age,
                gender: gender,
                height: height,
                weight: weight,
                activityLevel: activityLevel,
                goal: goal,
                cyclePhase: defaultUser.cyclePhase,
                activeCalories: 0
            )
            
            // Set weekly budget
            calculatedNutrition.weeklyBudget = nutritionLogicService.calculateWeeklyBudget(
                dailyTarget: calculatedNutrition.calories.target
            )
            
            self.dailyNutrition = calculatedNutrition
        } else {
            // Fallback to old calculation if data missing
            var fallbackNutrition = NutritionStats.calculateGoals(
                age: 23,
                gender: .female,
                height: 164,
                weight: 65,
                activityLevel: .moderatelyActive,
                goal: .glowUp
            )
            
            fallbackNutrition.weeklyBudget = nutritionLogicService.calculateWeeklyBudget(
                dailyTarget: fallbackNutrition.calories.target
            )
            
            self.dailyNutrition = fallbackNutrition
        }
        self.hasCompletedOnboarding = false // Set to true to skip onboarding for testing
        self.hobbies = MockDataService.shared.getHobbies()
        self.expenses = MockDataService.shared.getExpenses()
        
        // Set up HealthKit observers
        setupHealthKit()
        
        // Track onboarding completion
        analyticsService.trackOnboardingCompleted(
            age: defaultUser.age ?? 23,
            gender: defaultUser.gender?.rawValue ?? "Unknown",
            goal: defaultUser.goal?.rawValue ?? "Unknown"
        )
    }
    
    private func setupHealthKit() {
        // Observe HealthKit service updates
        healthKitService.$todaySteps
            .assign(to: &$todaySteps)
        
        healthKitService.$todayActiveCalories
            .assign(to: &$todayActiveCalories)
        
        healthKitService.$todayWorkouts
            .assign(to: &$todayWorkouts)
        
        // Load initial data if authorized
        if healthKitService.isAuthorized {
            Task {
                await healthKitService.loadTodayData()
            }
        }
    }
    
    /// Request HealthKit authorization and load data
    func requestHealthKitAuthorization() async {
        do {
            try await healthKitService.requestAuthorization()
            await healthKitService.loadTodayData()
            healthKitService.startObserving()
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }
    
    /// Sync user data from HealthKit (height, weight)
    func syncHealthKitData() async {
        guard healthKitService.isAuthorized else { return }
        
        do {
            if let height = try await healthKitService.getLatestHeight() {
                await MainActor.run {
                    self.user.height = height
                }
            }
            
            if let weight = try await healthKitService.getLatestWeight() {
                await MainActor.run {
                    self.user.weight = weight
                    // Recalculate nutrition goals with new weight
                    if let age = self.user.age,
                       let gender = self.user.gender,
                       let height = self.user.height,
                       let activityLevel = self.user.activityLevel,
                       let goal = self.user.goal {
                        self.dailyNutrition = NutritionStats.calculateGoals(
                            age: age,
                            gender: gender,
                            height: height,
                            weight: weight,
                            activityLevel: activityLevel,
                            goal: goal
                        )
                    }
                }
            }
            
            // Sync cycle data for females
            if user.gender == .female {
                if #available(iOS 9.0, *) {
                    if let cyclePhase = try await healthKitService.getCyclePhase() {
                        await MainActor.run {
                            self.user.cyclePhase = cyclePhase
                        }
                    }
                }
            }
        } catch {
            print("Error syncing HealthKit data: \(error)")
        }
    }
    
    /// Recalculate nutrition goals based on updated user data or activity
    func recalculateNutritionGoals() {
        guard let age = user.age,
             let gender = user.gender,
             let height = user.height,
             let weight = user.weight,
             let activityLevel = user.activityLevel,
             let goal = user.goal else { return }
        
        // Recalculate body metrics with current HealthKit data
        bodyMetrics = bodyMetricsService.calculateAllMetrics(
            weight: weight,
            height: height,
            age: age,
            gender: gender,
            activityLevel: activityLevel,
            activeCalories: todayActiveCalories
        )
        
        // Recalculate nutrition goals
        dailyNutrition = NutritionStats.calculateGoals(
            age: age,
            gender: gender,
            height: height,
            weight: weight,
            activityLevel: activityLevel,
            goal: goal,
            cyclePhase: user.cyclePhase,
            activeCalories: todayActiveCalories
        )
        
        // Update weekly budget
        dailyNutrition.weeklyBudget = nutritionLogicService.calculateWeeklyBudget(
            dailyTarget: dailyNutrition.calories.target
        )
    }
    
    /// Add food entry to log
    func addFoodEntry(_ entry: FoodEntry) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Find or create today's log
        if let index = foodLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            foodLogs[index].entries.append(entry)
        } else {
            let newLog = FoodLog(date: today, entries: [entry])
            foodLogs.append(newLog)
        }
        
        // Update nutrition totals
        updateNutritionFromFoodLogs()
    }
    
    /// Remove food entry from log
    func removeFoodEntry(_ entry: FoodEntry) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Find today's log
        if let logIndex = foodLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            // Remove the entry
            foodLogs[logIndex].entries.removeAll { $0.id == entry.id }
            
            // If no entries left, remove the log
            if foodLogs[logIndex].entries.isEmpty {
                foodLogs.remove(at: logIndex)
            }
            
            // Update nutrition totals
            updateNutritionFromFoodLogs()
        }
    }
    
    /// Update nutrition values from food logs
    /// Note: Calories consumed come from food logs only
    /// Active calories from workouts (HealthKit) are tracked separately in todayActiveCalories
    /// The base calorie target remains FIXED and does not change based on workouts
    func updateNutritionFromFoodLogs() {
        let today = Calendar.current.startOfDay(for: Date())
        let todayLog = foodLogs.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        
        // Calories consumed from food logging only
        dailyNutrition.calories.current = todayLog?.totalCalories ?? 0
        
        // Macros come from food logging only (not from workouts)
        dailyNutrition.protein.current = todayLog?.totalProtein ?? 0
        dailyNutrition.carbs.current = todayLog?.totalCarbs ?? 0
        dailyNutrition.fats.current = todayLog?.totalFats ?? 0
        
        // Update weekly consumption
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weekLogs = foodLogs.filter { $0.date >= weekStart }
        dailyNutrition.consumedThisWeek = weekLogs.reduce(0) { $0 + $1.totalCalories }
    }
    
    /// Calculate net calories (consumed - burned)
    /// Used for insights only, does not affect the base calorie target
    var netCalories: Double {
        return dailyNutrition.calories.current - todayActiveCalories
    }
}

enum TabItem: String, CaseIterable {
    case home = "Home"
    case recipes = "Recipes"
    case nearby = "Nearby"
    case activities = "Activities"
    case profile = "Profile"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .recipes: return "book.fill"
        case .nearby: return "mappin.circle.fill"
        case .activities: return "figure.run"
        case .profile: return "person.fill"
        }
    }
}

