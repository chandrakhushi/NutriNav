//
//  HealthKitService.swift
//  NutriNav
//
//  HealthKit integration for activity, steps, calories, and cycle data
//

import Foundation
import HealthKit
import Combine

class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var todaySteps: Double = 0
    @Published var todayActiveCalories: Double = 0
    @Published var todayWorkouts: [Activity] = []
    @Published var cyclePhase: CyclePhase?
    
    // HealthKit types we want to read
    private let readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        ]
        
        // Add cycle tracking for females (iOS 9.0+)
        if #available(iOS 9.0, *) {
            types.insert(HKObjectType.categoryType(forIdentifier: .menstrualFlow)!)
        }
        
        return types
    }()
    
    // HealthKit types we want to write (optional)
    private let writeTypes: Set<HKSampleType> = {
        return [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]
    }()
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Request HealthKit authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            await MainActor.run {
                self.isAuthorized = true
            }
            await loadTodayData()
        } catch {
            throw HealthKitError.authorizationFailed(error)
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            isAuthorized = false
            return
        }
        
        // Check if we have authorization for at least one type
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let status = healthStore.authorizationStatus(for: stepType)
        isAuthorized = status == .sharingAuthorized
    }
    
    // MARK: - Steps
    
    /// Get today's step count
    func getTodaySteps() async throws -> Double {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.invalidType
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let steps = sum.doubleValue(for: HKUnit.count())
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Active Calories
    
    /// Get today's active calories burned
    func getTodayActiveCalories() async throws -> Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.invalidType
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Workouts
    
    /// Get today's workouts
    func getTodayWorkouts() async throws -> [Activity] {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let activities = workouts.map { workout in
                    self.convertWorkoutToActivity(workout)
                }
                
                continuation.resume(returning: activities)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Convert HKWorkout to our Activity model
    private func convertWorkoutToActivity(_ workout: HKWorkout) -> Activity {
        let activityType = mapWorkoutType(workout.workoutActivityType)
        let duration = workout.duration
        let calories = workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
        
        return Activity(
            name: workout.workoutActivityType.name,
            type: activityType,
            duration: duration,
            caloriesBurned: calories,
            date: workout.startDate,
            source: .healthKit
        )
    }
    
    /// Map HKWorkoutActivityType to our ActivityType
    private func mapWorkoutType(_ hkType: HKWorkoutActivityType) -> ActivityType {
        switch hkType {
        case .running, .trackAndField:
            return .running
        case .cycling:
            return .cycling
        case .yoga:
            return .yoga
        case .traditionalStrengthTraining, .crossTraining:
            return .gym
        case .walking:
            return .walking
        case .swimming:
            return .swimming
        case .hiking:
            return .hiking
        case .dance, .danceInspiredTraining:
            return .dancing
        default:
            return .gym // Default fallback
        }
    }
    
    // MARK: - Body Measurements
    
    /// Get latest height from HealthKit
    func getLatestHeight() async throws -> Double? {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else {
            throw HealthKitError.invalidType
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let heightInMeters = sample.quantity.doubleValue(for: HKUnit.meter())
                let heightInCm = heightInMeters * 100
                continuation.resume(returning: heightInCm)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Get latest weight from HealthKit
    func getLatestWeight() async throws -> Double? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.invalidType
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let weightInKg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                continuation.resume(returning: weightInKg)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Cycle Tracking (for females)
    
    /// Get current menstrual cycle phase
    @available(iOS 9.0, *)
    func getCyclePhase() async throws -> CyclePhase? {
        guard let cycleType = HKCategoryType.categoryType(forIdentifier: .menstrualFlow) else {
            throw HealthKitError.invalidType
        }
        
        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: thirtyDaysAgo, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: cycleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let cycleSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Simple phase detection based on recent cycle data
                // In production, use more sophisticated cycle tracking
                let phase = self.determineCyclePhase(from: cycleSamples)
                continuation.resume(returning: phase)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Determine cycle phase from HealthKit samples
    @available(iOS 9.0, *)
    private func determineCyclePhase(from samples: [HKCategorySample]) -> CyclePhase? {
        guard !samples.isEmpty else { return nil }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Find most recent period
        let recentPeriods = samples.filter { sample in
            sample.value == HKCategoryValueMenstrualFlow.unspecified.rawValue ||
            sample.value == HKCategoryValueMenstrualFlow.light.rawValue ||
            sample.value == HKCategoryValueMenstrualFlow.medium.rawValue ||
            sample.value == HKCategoryValueMenstrualFlow.heavy.rawValue
        }
        
        guard let lastPeriod = recentPeriods.first else { return nil }
        
        let daysSincePeriod = calendar.dateComponents([.day], from: lastPeriod.endDate, to: now).day ?? 0
        
        // Simplified phase detection (in production, use proper cycle tracking)
        if daysSincePeriod <= 5 {
            return .menstruation
        } else if daysSincePeriod <= 13 {
            return .follicular
        } else if daysSincePeriod <= 16 {
            return .ovulation
        } else {
            return .luteal
        }
    }
    
    // MARK: - Load All Today's Data
    
    /// Load all today's activity data
    func loadTodayData() async {
        guard isAuthorized else { return }
        
        do {
            async let steps = getTodaySteps()
            async let calories = getTodayActiveCalories()
            async let workouts = getTodayWorkouts()
            
            let (stepsValue, caloriesValue, workoutsValue) = try await (steps, calories, workouts)
            
            await MainActor.run {
                self.todaySteps = stepsValue
                self.todayActiveCalories = caloriesValue
                self.todayWorkouts = workoutsValue
            }
        } catch {
            print("Error loading today's data: \(error)")
        }
    }
    
    /// Set up observer for real-time updates
    func startObserving() {
        guard isAuthorized else { return }
        
        // Observe steps
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, error in
                if error == nil {
                    Task {
                        await self?.loadTodayData()
                    }
                }
                completionHandler()
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - HealthKit Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationFailed(Error)
    case invalidType
    case queryFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationFailed(let error):
            return "Failed to authorize HealthKit: \(error.localizedDescription)"
        case .invalidType:
            return "Invalid HealthKit type"
        case .queryFailed(let error):
            return "HealthKit query failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - HKWorkoutActivityType Extension

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .yoga: return "Yoga"
        case .traditionalStrengthTraining: return "Strength Training"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .dance: return "Dancing"
        default: return "Workout"
        }
    }
}

