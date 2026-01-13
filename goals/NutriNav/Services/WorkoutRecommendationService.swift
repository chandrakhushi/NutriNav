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
        userPreferences: [ActivityType] = []
    ) -> WorkoutRecommendation {
        
        // Determine workout intensity based on available calories
        let intensity = determineIntensity(availableCalories: availableCalories)
        
        // Check protein status
        let proteinStatus = getProteinStatus(consumed: proteinConsumed, target: proteinTarget)
        
        // Get activity recommendations
        let activities = recommendActivities(
            intensity: intensity,
            proteinStatus: proteinStatus,
            activityHistory: activityHistory,
            cyclePhase: cyclePhase,
            userPreferences: userPreferences
        )
        
        // Generate message
        let message = generateRecommendationMessage(
            intensity: intensity,
            proteinStatus: proteinStatus,
            cyclePhase: cyclePhase
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
            recommendations = [.running, .gym, .swimming]
        case .veryIntense:
            recommendations = [.gym, .running, .cycling, .swimming]
        }
        
        // Adjust for protein status
        if proteinStatus == .low {
            // Prefer lighter activities if protein is low
            recommendations = recommendations.filter { $0 != .gym && $0 != .swimming }
            recommendations.insert(.yoga, at: 0)
        }
        
        // Adjust for cycle phase (women)
        if let phase = cyclePhase {
            switch phase {
            case .menstruation:
                // Lighter activities during period
                recommendations = [.yoga, .walking, .hiking]
            case .follicular:
                // Great time for intense workouts
                if intensity == .light { recommendations = [.running, .gym, .cycling] }
            case .ovulation:
                // Peak energy - maximize
                recommendations = [.gym, .running, .swimming, .cycling]
            case .luteal:
                // Moderate intensity
                recommendations = [.running, .yoga, .cycling]
            }
        }
        
        // Filter by user preferences if available
        if !userPreferences.isEmpty {
            recommendations = recommendations.filter { userPreferences.contains($0) }
        }
        
        // Consider activity history (suggest variety)
        let recentTypes = Set(activityHistory.suffix(5).map { $0.type })
        recommendations = recommendations.filter { !recentTypes.contains($0) }
        
        return Array(recommendations.prefix(3)) // Return top 3
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
        cyclePhase: CyclePhase?
    ) -> String {
        var messages: [String] = []
        
        // Intensity message
        switch intensity {
        case .light:
            messages.append("Light activity recommended")
        case .moderate:
            messages.append("Moderate workout would be great")
        case .intense:
            messages.append("You have energy for an intense workout")
        case .veryIntense:
            messages.append("Perfect time for a challenging workout")
        }
        
        // Protein message
        if proteinStatus == .low {
            messages.append("Consider eating more protein first")
        }
        
        // Cycle message
        if let phase = cyclePhase {
            switch phase {
            case .follicular:
                messages.append("Great time to push yourself")
            case .ovulation:
                messages.append("Peak energy phase - maximize your workout")
            case .luteal:
                messages.append("Moderate intensity recommended")
            case .menstruation:
                messages.append("Listen to your body - rest if needed")
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

