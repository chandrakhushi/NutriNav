//
//  WorkoutRecommendationService.swift
//  NutriNav
//
//  Workout recommendations based on calories, protein, activity, cycle
//

import Foundation

class WorkoutRecommendationService {
    static let shared = WorkoutRecommendationService()
    
    private init() {}
    
    // MARK: - Workout Recommendations
    
    /// Get recommended workout based on available calories, protein status, activity history, and cycle phase
    func getRecommendedWorkout(
        availableCalories: Double,
        proteinConsumed: Double,
        proteinTarget: Double,
        activityHistory: [Activity],
        cyclePhase: CyclePhase?,
        waterProgress: Double, // 0.0 to 1.0+
        stepProgress: Double,  // 0.0 to 1.0+
        userPreferences: [ActivityType] = []
    ) -> WorkoutRecommendation {
        
        // Determine base workout intensity based on available calories
        var intensity = determineIntensity(availableCalories: availableCalories)
        
        // Hydration check: Throttle intensity if dehydrated
        let isDehydrated = waterProgress < 0.5
        if isDehydrated && (intensity == .intense || intensity == .veryIntense) {
            intensity = .moderate // Safety throttle
        }
        
        // Check protein status
        let proteinStatus = getProteinStatus(consumed: proteinConsumed, target: proteinTarget)
        
        // Get activity recommendations
        let activities = recommendActivities(
            intensity: intensity,
            proteinStatus: proteinStatus,
            activityHistory: activityHistory,
            cyclePhase: cyclePhase,
            stepProgress: stepProgress,
            userPreferences: userPreferences
        )
        
        // Generate message
        let message = generateRecommendationMessage(
            intensity: intensity,
            proteinStatus: proteinStatus,
            cyclePhase: cyclePhase,
            waterProgress: waterProgress,
            stepProgress: stepProgress
        )
        
        return WorkoutRecommendation(
            activities: activities,
            intensity: intensity,
            message: message,
            estimatedCaloriesBurned: estimateCaloriesBurned(intensity: intensity, activities: activities)
        )
    }
    
    // MARK: - Intensity Determination
    
    private func determineIntensity(availableCalories: Double) -> WorkoutIntensity {
        switch availableCalories {
        case ..<300:
            return .light // Not enough calories for intense workout
        case 300..<600:
            return .moderate
        case 600..<900:
            return .intense
        default:
            return .veryIntense // Plenty of calories available
        }
    }
    
    // MARK: - Protein Status
    
    private func getProteinStatus(consumed: Double, target: Double) -> ProteinStatus {
        let percentage = (consumed / target) * 100
        
        switch percentage {
        case ..<50:
            return .low // Need more protein before workout
        case 50..<80:
            return .moderate
        default:
            return .adequate
        }
    }
    
    // MARK: - Activity Recommendations
    
    private func recommendActivities(
        intensity: WorkoutIntensity,
        proteinStatus: ProteinStatus,
        activityHistory: [Activity],
        cyclePhase: CyclePhase?,
        stepProgress: Double,
        userPreferences: [ActivityType]
    ) -> [ActivityType] {
        var recommendations: [ActivityType] = []
        
        // Base recommendations on intensity
        switch intensity {
        case .light:
            recommendations = [.yoga, .walking, .hiking]
        case .moderate:
            recommendations = [.running, .cycling, .yoga]
        case .intense:
            recommendations = [.running, .gym, .swimming, .cycling]
        case .veryIntense:
            recommendations = [.gym, .running, .cycling, .swimming]
        }
        
        // Adjust based on steps: If cardio goal is met (>90%), prioritize Strength or Recovery
        if stepProgress > 0.9 {
            recommendations = recommendations.filter { $0 != .walking && $0 != .running && $0 != .hiking }
            if recommendations.isEmpty { recommendations = [.gym, .yoga] }
            // Move gym to front if available
            if recommendations.contains(.gym) {
                recommendations.removeAll { $0 == .gym }
                recommendations.insert(.gym, at: 0)
            }
        }
        
        // Adjust for protein status
        if proteinStatus == .low {
            // Prefer lighter activities if protein is low to avoid excessive muscle breakdown
            recommendations = recommendations.filter { $0 != .gym && $0 != .swimming }
            if !recommendations.contains(.yoga) {
                recommendations.insert(.yoga, at: 0)
            }
        }
        
        // Adjust for cycle phase (women)
        if let phase = cyclePhase {
            switch phase {
            case .menstruation:
                recommendations = [.yoga, .walking, .hiking]
            case .follicular:
                if intensity == .light { recommendations = [.running, .gym, .cycling] }
            case .ovulation:
                recommendations = [.gym, .running, .swimming, .cycling]
            case .luteal:
                recommendations = [.running, .yoga, .cycling]
            }
        }
        
        // Filter by user preferences
        if !userPreferences.isEmpty {
            let preferred = recommendations.filter { userPreferences.contains($0) }
            if !preferred.isEmpty { recommendations = preferred }
        }
        
        // Variety Check: Filter out activities done in the last 3 sessions
        let recentTypes = Set(activityHistory.suffix(3).map { $0.type })
        let varied = recommendations.filter { !recentTypes.contains($0) }
        
        // Fallback to base recommendations if variety filter is too restrictive
        let finalRecommendations = varied.isEmpty ? recommendations : varied
        
        return Array(finalRecommendations.prefix(3))
    }
    
    // MARK: - Calorie Estimation
    
    private func estimateCaloriesBurned(intensity: WorkoutIntensity, activities: [ActivityType]) -> Double {
        let baseCalories: Double
        switch intensity {
        case .light:
            baseCalories = 150
        case .moderate:
            baseCalories = 300
        case .intense:
            baseCalories = 500
        case .veryIntense:
            baseCalories = 700
        }
        
        // Adjust based on activity types
        let multiplier = activities.contains(.gym) ? 1.2 : 1.0
        return baseCalories * multiplier
    }
    
    // MARK: - Message Generation
    
    private func generateRecommendationMessage(
        intensity: WorkoutIntensity,
        proteinStatus: ProteinStatus,
        cyclePhase: CyclePhase?,
        waterProgress: Double,
        stepProgress: Double
    ) -> String {
        var messages: [String] = []
        
        // Hydration check (High priority)
        if waterProgress < 0.3 {
            messages.append("⚠️ Hydrate immediately before any activity")
        } else if waterProgress < 0.6 {
            messages.append("Drink a glass of water before starting")
        }
        
        // Activity/Step check
        if stepProgress > 1.0 {
            messages.append("Step goal smashed! Focus on strength or recovery now")
        }
        
        // Protein message
        if proteinStatus == .low {
            messages.append("Fuel with protein to protect your muscles")
        }
        
        // Cycle message
        if let phase = cyclePhase {
            switch phase {
            case .follicular:
                messages.append("Energy is rising—great time to push weights")
            case .ovulation:
                messages.append("Peak performance window! Go for a PR")
            case .luteal:
                messages.append("Metabolism is higher; keep intensity moderate")
            case .menstruation:
                messages.append("Listen to your body; light movement is key")
            }
        }
        
        // Intensity fallback if no specific messages triggered
        if messages.isEmpty {
            switch intensity {
            case .light: messages.append("Perfect day for some light movement")
            case .moderate: messages.append("Great conditions for a solid workout")
            case .intense: messages.append("You've got the fuel for something intense")
            case .veryIntense: messages.append("Prime day for a high-performance session")
            }
        }
        
        return messages.joined(separator: ". ")
    }
}

// MARK: - Supporting Types

struct WorkoutRecommendation {
    let activities: [ActivityType]
    let intensity: WorkoutIntensity
    let message: String
    let estimatedCaloriesBurned: Double
}

enum WorkoutIntensity: String {
    case light = "Light"
    case moderate = "Moderate"
    case intense = "Intense"
    case veryIntense = "Very Intense"
}

enum ProteinStatus {
    case low
    case moderate
    case adequate
}

