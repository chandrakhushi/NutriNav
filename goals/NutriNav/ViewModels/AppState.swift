//
//  AppState.swift
//  NutriNav
//
//  Global app state management
//

import Foundation
import SwiftUI
import Combine

// MARK: - Water Container Types
enum WaterContainerType: String, Codable, CaseIterable {
    case glass = "Glass"
    case bottle = "Bottle"
    
    var icon: String {
        switch self {
        case .glass: return "drop.fill"
        case .bottle: return "waterbottle.fill"
        }
    }
    
    var defaultSizeOz: Double {
        switch self {
        case .glass: return 8.0  // Standard glass
        case .bottle: return 30.0 // Stanley-style bottle
        }
    }
}

struct WaterSettings: Codable {
    var containerType: WaterContainerType = .glass
    var customBottleSizeOz: Double = 30.0 // Default Stanley size
    
    var containerSizeOz: Double {
        switch containerType {
        case .glass: return 8.0
        case .bottle: return customBottleSizeOz
        }
    }
    
    var containerName: String {
        switch containerType {
        case .glass: return "glass"
        case .bottle: return "bottle"
        }
    }
    
    var containerNamePlural: String {
        switch containerType {
        case .glass: return "glasses"
        case .bottle: return "bottles"
        }
    }
}

class AppState: ObservableObject {
    @Published var user: User {
        didSet { saveUserProfile() }
    }
    @Published var dailyNutrition: DailyNutrition
    @Published var currentStreak: Streak {
        didSet { saveStreak() }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: PersistenceKeys.hasCompletedOnboarding) }
    }
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
    @Published var foodLogs: [FoodLog] = [] {
        didSet { saveFoodLogs() }
    }
    @Published var weeklyFoodLog: FoodLog?
    
    // Water tracking (stored in ounces for accuracy)
    @Published var waterConsumedOz: Double = 0 {
        didSet { saveWaterIntake() }
    }
    @Published var waterSettings: WaterSettings = WaterSettings() {
        didSet { saveWaterSettings() }
    }
    
    // Vacation Mode - switches to maintenance calories
    @Published var isVacationMode: Bool = false {
        didSet {
            UserDefaults.standard.set(isVacationMode, forKey: PersistenceKeys.vacationMode)
            if oldValue != isVacationMode {
                recalculateNutritionGoals()
                HapticFeedback.impact()
            }
        }
    }
    
    // MARK: - Water Computed Properties
    
    /// Recommended daily water intake in ounces based on user profile
    var recommendedDailyWaterOz: Double {
        calculateRecommendedWaterIntake()
    }
    
    /// Number of containers to reach daily goal
    var dailyWaterGoalContainers: Int {
        let containersNeeded = recommendedDailyWaterOz / waterSettings.containerSizeOz
        return Int(ceil(containersNeeded))
    }
    
    /// Number of containers consumed today
    var waterContainersConsumed: Int {
        Int(floor(waterConsumedOz / waterSettings.containerSizeOz))
    }
    
    /// Partial container progress (0.0 to 1.0)
    var waterContainerProgress: Double {
        let fullContainers = floor(waterConsumedOz / waterSettings.containerSizeOz)
        let partialOz = waterConsumedOz - (fullContainers * waterSettings.containerSizeOz)
        return partialOz / waterSettings.containerSizeOz
    }
    
    /// Progress toward daily goal (0.0 to 1.0+)
    var waterProgress: Double {
        guard recommendedDailyWaterOz > 0 else { return 0 }
        return waterConsumedOz / recommendedDailyWaterOz
    }
    
    /// Backward compatibility: glasses count for existing UI
    var waterGlasses: Int {
        get { waterContainersConsumed }
        set { waterConsumedOz = Double(newValue) * waterSettings.containerSizeOz }
    }
    
    // Favorite foods (stored by food name for easy lookup)
    @Published var favoriteFoodNames: Set<String> = []
    
    // Favorite recipes (stored by recipe ID)
    @Published var favoriteRecipeIds: Set<Int> = []
    
    // Body metrics (calculated)
    @Published var bodyMetrics: BodyMetrics?
    
    // Weight history for progress tracking
    @Published var weightHistory: [WeightEntry] = [] {
        didSet { saveWeightHistory() }
    }
    
    // Cycle tracking (for females)
    @Published var cycleData: CycleData = CycleData() {
        didSet {
            saveCycleData()
            // Update nutrition goals when cycle phase changes
            if oldValue.currentPhase != cycleData.currentPhase {
                recalculateNutritionGoals()
            }
        }
    }
    let cyclePredictionService = CyclePredictionService.shared
    
    // Services
    let bodyMetricsService = BodyMetricsService.shared
    let nutritionLogicService = NutritionLogicService.shared
    let lazyDayService = LazyDayService.shared
    let workoutRecommendationService = WorkoutRecommendationService.shared
    
    // Analytics
    let analyticsService = AnalyticsService.shared
    let subscriptionService = SubscriptionService.shared
    
    // MARK: - Persistence Keys
    private enum PersistenceKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userProfile = "userProfile"
        static let foodLogs = "foodLogs"
        static let currentStreak = "currentStreak"
        static let waterConsumedOz = "waterConsumedOz"
        static let waterSettings = "waterSettings"
        // Legacy key for migration
        static let waterGlassesLegacy = "waterGlasses"
        static let waterDate = "waterDate"
        static let weightHistory = "weightHistory"
        static let vacationMode = "vacationMode"
        static let cycleData = "cycleData"
    }
    
    init() {
        // PHASE 1: Initialize ALL stored properties before using 'self'
        
        // Load persisted onboarding state
        let savedOnboardingState = UserDefaults.standard.bool(forKey: PersistenceKeys.hasCompletedOnboarding)
        
        // Load persisted user profile or use default
        let loadedUser: User
        if let savedUser = Self.loadUserProfile() {
            loadedUser = savedUser
        } else {
            var defaultUser = User()
            defaultUser.name = ""
            defaultUser.email = ""
            loadedUser = defaultUser
        }
        
        // Load persisted streak or initialize
        let loadedStreak = Self.loadStreak() ?? Streak(currentDays: 0, lastDate: Date())
        
        // Load persisted food logs
        let loadedFoodLogs = Self.loadFoodLogs()
        
        // Load water settings
        let loadedWaterSettings = Self.loadWaterSettings()
        
        // Load water intake for today (with backward compatibility)
        let loadedWaterOz = Self.loadWaterIntake(settings: loadedWaterSettings)
        
        // Load weight history
        var loadedWeightHistory = Self.loadWeightHistory()
        
        // If no weight history but user has weight, seed with initial entry
        if loadedWeightHistory.isEmpty, let userWeight = loadedUser.weight {
            loadedWeightHistory = [WeightEntry(date: Date(), weight: userWeight)]
        }
        
        // Load vacation mode
        let loadedVacationMode = UserDefaults.standard.bool(forKey: PersistenceKeys.vacationMode)
        
        // Load cycle data
        let loadedCycleData = Self.loadCycleData()
        
        // Calculate initial nutrition (use loaded user data or defaults)
        let age = loadedUser.age ?? 23
        let gender = loadedUser.gender ?? .female
        let height = loadedUser.height ?? 164
        let weight = loadedUser.weight ?? 65
        let activityLevel = loadedUser.activityLevel ?? .moderatelyActive
        let userGoal = loadedUser.goal ?? .maintainWeight
        
        // If vacation mode is on, use maintenance calories
        let effectiveGoal: FitnessGoal = loadedVacationMode ? .maintainWeight : userGoal
        
        var initialNutrition = NutritionStats.calculateGoals(
            age: age,
            gender: gender,
            height: height,
            weight: weight,
            activityLevel: activityLevel,
            goal: effectiveGoal,
            cyclePhase: loadedUser.cyclePhase,
            activeCalories: 0
        )
        initialNutrition.weeklyBudget = NutritionLogicService.shared.calculateWeeklyBudget(
            dailyTarget: initialNutrition.calories.target
        )
        
        // Now assign all stored properties
        self.hasCompletedOnboarding = savedOnboardingState
        self.user = loadedUser
        self.currentStreak = loadedStreak
        self.foodLogs = loadedFoodLogs
        self.waterSettings = loadedWaterSettings
        self.waterConsumedOz = loadedWaterOz
        self.weightHistory = loadedWeightHistory
        self.isVacationMode = loadedVacationMode
        self.cycleData = loadedCycleData
        self.dailyNutrition = initialNutrition
        
        // PHASE 2: Now we can use 'self' safely
        
        // Calculate body metrics if user data is complete
        if loadedUser.age != nil && loadedUser.gender != nil && loadedUser.height != nil &&
           loadedUser.weight != nil && loadedUser.activityLevel != nil {
            self.bodyMetrics = bodyMetricsService.calculateAllMetrics(
                weight: weight,
                height: height,
                age: age,
                gender: gender,
                activityLevel: activityLevel,
                activeCalories: 0
            )
        }
        
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
        
        // Update nutrition from persisted food logs
        updateNutritionFromFoodLogs()
        
        // Calculate streak from food log history
        updateStreakFromFoodLogs()
        
        // Set up HealthKit observers
        setupHealthKit()
        
        setupAuth()
    }
    
    // MARK: - Persistence: User Profile
    
    private func saveUserProfile() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(user) {
            UserDefaults.standard.set(encoded, forKey: PersistenceKeys.userProfile)
        }
    }
    
    private static func loadUserProfile() -> User? {
        guard let data = UserDefaults.standard.data(forKey: PersistenceKeys.userProfile) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(User.self, from: data)
    }
    
    // MARK: - Persistence: Food Logs
    
    private func saveFoodLogs() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(foodLogs) {
            UserDefaults.standard.set(encoded, forKey: PersistenceKeys.foodLogs)
        }
    }
    
    private static func loadFoodLogs() -> [FoodLog] {
        guard let data = UserDefaults.standard.data(forKey: PersistenceKeys.foodLogs) else {
            return []
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode([FoodLog].self, from: data)) ?? []
    }
    
    // MARK: - Persistence: Streak
    
    private func saveStreak() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(currentStreak) {
            UserDefaults.standard.set(encoded, forKey: PersistenceKeys.currentStreak)
        }
    }
    
    private static func loadStreak() -> Streak? {
        guard let data = UserDefaults.standard.data(forKey: PersistenceKeys.currentStreak) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(Streak.self, from: data)
    }
    
    /// Update streak based on actual food log history
    func updateStreakFromFoodLogs() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get all unique dates that have food entries, sorted descending
        let datesWithEntries = Set(foodLogs.filter { !$0.entries.isEmpty }.map { calendar.startOfDay(for: $0.date) })
        let sortedDates = datesWithEntries.sorted(by: >)
        
        guard !sortedDates.isEmpty else {
            currentStreak = Streak(currentDays: 0, lastDate: today)
            return
        }
        
        // Check if user logged today or yesterday (streak is still active)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let mostRecentLog = sortedDates.first!
        
        guard mostRecentLog >= yesterday else {
            // Streak is broken if last log is older than yesterday
            currentStreak = Streak(currentDays: 0, lastDate: today)
            return
        }
        
        // Count consecutive days backwards from the most recent log
        var streakCount = 0
        var checkDate = mostRecentLog
        
        while datesWithEntries.contains(checkDate) {
            streakCount += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        currentStreak = Streak(currentDays: streakCount, lastDate: mostRecentLog)
    }
    
    // MARK: - Persistence: Water Intake
    
    private func saveWaterIntake() {
        let today = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(waterConsumedOz, forKey: PersistenceKeys.waterConsumedOz)
        UserDefaults.standard.set(today.timeIntervalSince1970, forKey: PersistenceKeys.waterDate)
    }
    
    private static func loadWaterIntake(settings: WaterSettings) -> Double {
        let savedDate = UserDefaults.standard.double(forKey: PersistenceKeys.waterDate)
        let today = Calendar.current.startOfDay(for: Date())
        
        // Only load water if it was saved today, otherwise reset
        if savedDate > 0 {
            let savedDay = Date(timeIntervalSince1970: savedDate)
            if Calendar.current.isDate(savedDay, inSameDayAs: today) {
                // Try loading new format first
                let ozValue = UserDefaults.standard.double(forKey: PersistenceKeys.waterConsumedOz)
                if ozValue > 0 {
                    return ozValue
                }
                
                // Backward compatibility: migrate from old glasses format
                let legacyGlasses = UserDefaults.standard.integer(forKey: PersistenceKeys.waterGlassesLegacy)
                if legacyGlasses > 0 {
                    // Convert glasses to oz (8 oz per glass)
                    return Double(legacyGlasses) * 8.0
                }
            }
        }
        return 0
    }
    
    // MARK: - Persistence: Water Settings
    
    private func saveWaterSettings() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(waterSettings) {
            UserDefaults.standard.set(encoded, forKey: PersistenceKeys.waterSettings)
        }
    }
    
    private static func loadWaterSettings() -> WaterSettings {
        guard let data = UserDefaults.standard.data(forKey: PersistenceKeys.waterSettings) else {
            return WaterSettings()
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode(WaterSettings.self, from: data)) ?? WaterSettings()
    }
    
    // MARK: - Persistence: Weight History
    
    private func saveWeightHistory() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(weightHistory) {
            UserDefaults.standard.set(encoded, forKey: PersistenceKeys.weightHistory)
        }
    }
    
    private static func loadWeightHistory() -> [WeightEntry] {
        guard let data = UserDefaults.standard.data(forKey: PersistenceKeys.weightHistory) else {
            return []
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode([WeightEntry].self, from: data)) ?? []
    }
    
    // MARK: - Persistence: Cycle Data
    
    private func saveCycleData() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(cycleData) {
            UserDefaults.standard.set(encoded, forKey: PersistenceKeys.cycleData)
        }
    }
    
    private static func loadCycleData() -> CycleData {
        guard let data = UserDefaults.standard.data(forKey: PersistenceKeys.cycleData) else {
            return CycleData()
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode(CycleData.self, from: data)) ?? CycleData()
    }
    
    // MARK: - Water Calculation
    
    /// Calculate recommended daily water intake based on user profile
    /// Formula: Base = 0.5 oz per lb of body weight, adjusted for activity and sex
    private func calculateRecommendedWaterIntake() -> Double {
        // Default to 64 oz (8 glasses) if user data is incomplete
        guard let weightKg = user.weight else { return 64.0 }
        
        // Convert kg to lbs
        let weightLbs = weightKg * 2.20462
        
        // Base: 0.5 oz per lb of body weight
        var baseOz = weightLbs * 0.5
        
        // Activity level adjustment
        let activityMultiplier: Double
        switch user.activityLevel {
        case .sedentary:
            activityMultiplier = 1.0
        case .lightlyActive:
            activityMultiplier = 1.1
        case .moderatelyActive:
            activityMultiplier = 1.2
        case .veryActive:
            activityMultiplier = 1.3
        case .extremelyActive:
            activityMultiplier = 1.4
        case .none:
            activityMultiplier = 1.0
        }
        
        baseOz *= activityMultiplier
        
        // Sex adjustment (males typically need slightly more)
        if user.gender == .male {
            baseOz *= 1.1
        }
        
        // Clamp to reasonable range (48-160 oz)
        return min(max(baseOz, 48.0), 160.0)
    }
    
    // MARK: - Water Actions
    
    /// Add one container of water
    func addWaterContainer() {
        let maxOz = recommendedDailyWaterOz * 1.5 // Allow up to 150% of goal
        let newAmount = waterConsumedOz + waterSettings.containerSizeOz
        waterConsumedOz = min(newAmount, maxOz)
    }
    
    /// Remove one container of water
    func removeWaterContainer() {
        let newAmount = waterConsumedOz - waterSettings.containerSizeOz
        waterConsumedOz = max(newAmount, 0)
    }
    
    /// Legacy method for backward compatibility
    func addWaterGlass() {
        addWaterContainer()
    }
    
    /// Legacy method for backward compatibility
    func removeWaterGlass() {
        removeWaterContainer()
    }
    
    /// Update water container preference
    func setWaterContainer(type: WaterContainerType, customSizeOz: Double? = nil) {
        waterSettings.containerType = type
        if let size = customSizeOz, type == .bottle {
            waterSettings.customBottleSizeOz = size
        }
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
            
            // Sync cycle data for females using CyclePredictionService
            if user.gender == .female {
                await syncCycleData()
            }
        } catch {
            print("Error syncing HealthKit data: \(error)")
        }
    }
    
    // MARK: - Cycle Data Management
    
    /// Sync cycle data from HealthKit or refresh existing data
    func syncCycleData() async {
        // Try to authorize and fetch from HealthKit
        do {
            try await cyclePredictionService.requestHealthKitAuthorization()
            let hkCycleData = try await cyclePredictionService.fetchHealthKitCycleData()
            await MainActor.run {
                self.cycleData = hkCycleData
            }
        } catch {
            // HealthKit not available or no data - use existing manual data
            print("Cycle sync from HealthKit failed: \(error)")
            await MainActor.run {
                // Just refresh the timestamp so phase recalculates
                self.cycleData.lastUpdated = Date()
            }
        }
    }
    
    /// Log period start date manually (fallback when HealthKit unavailable)
    func logPeriodStart(date: Date) {
        cyclePredictionService.logPeriodStart(date: date)
        cycleData = cyclePredictionService.cycleData
        HapticFeedback.success()
    }
    
    /// Recalculate nutrition goals based on updated user data or activity
    func recalculateNutritionGoals() {
        guard let age = user.age,
             let gender = user.gender,
             let height = user.height,
             let weight = user.weight,
             let activityLevel = user.activityLevel,
             let userGoal = user.goal else { return }
        
        // If vacation mode is on, use maintenance calories
        let effectiveGoal: FitnessGoal = isVacationMode ? .maintainWeight : userGoal
        
        // Recalculate body metrics with current HealthKit data
        bodyMetrics = bodyMetricsService.calculateAllMetrics(
            weight: weight,
            height: height,
            age: age,
            gender: gender,
            activityLevel: activityLevel,
            activeCalories: todayActiveCalories
        )
        
        // Recalculate nutrition goals (use cycleData.currentPhase for auto-calculated phase)
        let effectiveCyclePhase = cycleData.currentPhase ?? user.cyclePhase
        dailyNutrition = NutritionStats.calculateGoals(
            age: age,
            gender: gender,
            height: height,
            weight: weight,
            activityLevel: activityLevel,
            goal: effectiveGoal,
            cyclePhase: effectiveCyclePhase,
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
        
        // Update streak
        updateStreakFromFoodLogs()
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
    
    // MARK: - Weight Progress Management
    
    /// Log a new weight entry
    func logWeight(_ weight: Double, date: Date = Date()) {
        let entry = WeightEntry(date: date, weight: weight)
        
        // Check if there's already an entry for today
        let calendar = Calendar.current
        if let existingIndex = weightHistory.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            // Update existing entry
            var updatedHistory = weightHistory
            updatedHistory[existingIndex] = entry
            weightHistory = updatedHistory.sorted { $0.date < $1.date }
        } else {
            // Add new entry and sort by date
            weightHistory = (weightHistory + [entry]).sorted { $0.date < $1.date }
        }
        
        // Also update user's current weight
        user.weight = weight
        
        HapticFeedback.success()
    }
    
    /// Delete a weight entry
    func deleteWeightEntry(_ entry: WeightEntry) {
        weightHistory.removeAll { $0.id == entry.id }
    }
    
    /// Get starting weight (oldest entry)
    var startingWeight: Double? {
        weightHistory.first?.weight
    }
    
    /// Get current weight (latest entry)
    var currentWeight: Double? {
        weightHistory.last?.weight ?? user.weight
    }
    
    /// Calculate weight change from start
    var weightChangeFromStart: Double? {
        guard let start = startingWeight, let current = currentWeight else { return nil }
        return current - start
    }
    
    /// Check if on track based on goal
    var isOnTrackForGoal: Bool {
        guard let change = weightChangeFromStart, let goal = user.goal else { return true }
        
        switch goal {
        case .loseWeight:
            return change <= 0
        case .gainWeight, .buildMuscle:
            return change >= 0
        case .maintainWeight:
            return abs(change) < 2.0 // Within 2kg tolerance
        }
    }
    
    /// Get weight entries for the last N days
    func weightEntriesForLastDays(_ days: Int) -> [WeightEntry] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return weightHistory.filter { $0.date >= startDate }
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
        
        // Reset onboarding state so user sees onboarding on next sign-in
        hasCompletedOnboarding = false
        
        // Clear persisted data
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.userProfile)
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.foodLogs)
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.currentStreak)
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.waterConsumedOz)
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.waterSettings)
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.waterDate)
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.waterGlassesLegacy)
        UserDefaults.standard.removeObject(forKey: "favoriteFoodNames")
        UserDefaults.standard.removeObject(forKey: "favoriteRecipeIds")
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.weightHistory)
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.vacationMode)
        UserDefaults.standard.removeObject(forKey: PersistenceKeys.cycleData)
        
        // Reset in-memory state
        user = User()
        foodLogs = []
        favoriteFoodNames = []
        favoriteRecipeIds = []
        waterConsumedOz = 0
        waterSettings = WaterSettings()
        weightHistory = []
        isVacationMode = false
        cycleData = CycleData()
        currentStreak = Streak(currentDays: 0, lastDate: Date())
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

