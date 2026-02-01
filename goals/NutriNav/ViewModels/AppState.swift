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
    
    // Auth
    let authService = AppleAuthService()
    @Published var authUser: AuthUser?
    @Published var isAuthenticated: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
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
    
    // Favorite foods (stored by food name for easy lookup)
    @Published var favoriteFoodNames: Set<String> = []
    
    // Favorite recipes (stored by recipe ID)
    @Published var favoriteRecipeIds: Set<Int> = []
    
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
        // Create a date of birth that results in age 23
        let calendar = Calendar.current
        defaultUser.dateOfBirth = calendar.date(byAdding: .year, value: -23, to: Date())
        defaultUser.gender = .female
        defaultUser.height = 164
        defaultUser.weight = 65
        defaultUser.activityLevel = .moderatelyActive
        defaultUser.goal = .maintainWeight
        
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
                goal: .maintainWeight
            )
            
            fallbackNutrition.weeklyBudget = nutritionLogicService.calculateWeeklyBudget(
                dailyTarget: fallbackNutrition.calories.target
            )
            
            self.dailyNutrition = fallbackNutrition
        }
        self.hasCompletedOnboarding = false // Set to true to skip onboarding for testing
        self.hobbies = MockDataService.shared.getHobbies()
        self.expenses = MockDataService.shared.getExpenses()
        
        // Load favorites from UserDefaults
        if let savedFavorites = UserDefaults.standard.array(forKey: "favoriteFoodNames") as? [String] {
            self.favoriteFoodNames = Set(savedFavorites)
        }
        
        // Load favorite recipes from UserDefaults
        if let savedRecipeIds = UserDefaults.standard.array(forKey: "favoriteRecipeIds") as? [Int] {
            self.favoriteRecipeIds = Set(savedRecipeIds)
        }
        
        // Set up HealthKit observers
        setupHealthKit()
        
        // Track onboarding completion
        analyticsService.trackOnboardingCompleted(
            age: defaultUser.age ?? 23,
            gender: defaultUser.gender?.rawValue ?? "Unknown",
            goal: defaultUser.goal?.rawValue ?? "Unknown"
        )
        
        setupAuth()
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
    
    /// Update nutrition targets with custom values
    func updateNutritionTargets(calories: Double, protein: Double, carb: Double, fat: Double) {
        dailyNutrition.calories.target = calories
        dailyNutrition.protein.target = protein
        dailyNutrition.carbs.target = carb
        dailyNutrition.fats.target = fat
        dailyNutrition.isCustom = true
    }
    
    // MARK: - Favorite Foods Management
    
    /// Toggle favorite status for a food
    func toggleFavorite(foodName: String) {
        if favoriteFoodNames.contains(foodName) {
            favoriteFoodNames.remove(foodName)
        } else {
            favoriteFoodNames.insert(foodName)
        }
        saveFavorites()
    }
    
    /// Check if a food is favorited
    func isFavorite(foodName: String) -> Bool {
        return favoriteFoodNames.contains(foodName)
    }
    
    /// Save favorites to UserDefaults
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteFoodNames), forKey: "favoriteFoodNames")
    }
    
    // MARK: - Favorite Recipes Management
    
    /// Toggle favorite status for a recipe
    func toggleFavoriteRecipe(recipeId: Int) {
        if favoriteRecipeIds.contains(recipeId) {
            favoriteRecipeIds.remove(recipeId)
        } else {
            favoriteRecipeIds.insert(recipeId)
        }
        saveFavoriteRecipes()
    }
    
    /// Check if a recipe is favorited
    func isFavoriteRecipe(recipeId: Int) -> Bool {
        return favoriteRecipeIds.contains(recipeId)
    }
    
    /// Save favorite recipes to UserDefaults
    private func saveFavoriteRecipes() {
        UserDefaults.standard.set(Array(favoriteRecipeIds), forKey: "favoriteRecipeIds")
    }
    
    // MARK: - Auth Management
    
    private func setupAuth() {
        // Bind auth service state to AppState
        authService.$currentUser
            .receive(on: RunLoop.main)
            .assign(to: \.authUser, on: self)
            .store(in: &cancellables)
            
        $authUser
            .map { $0 != nil }
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
            
        // Check initial state
        Task {
            await authService.checkCredentialState()
        }
    }
    
    func signInWithApple() async {
        do {
            _ = try await authService.signInWithApple()
        } catch {
            print("Sign in failed: \(error)")
        }
    }
    
    func signOut() {
        authService.signOut()
    }
    
    #if DEBUG
    func debugBypassAuth() {
        let debugUser = AuthUser(id: "debug_user", email: "debug@example.com", fullName: "Debug User")
        self.authUser = debugUser
        self.isAuthenticated = true
    }
    #endif
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

