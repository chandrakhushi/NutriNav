//
//  NutritionLogicService.swift
//  NutriNav
//
//  Nutrition logic with lean-mass protein, weekly banking, cycle adjustments
//

import Foundation

class NutritionLogicService {
    static let shared = NutritionLogicService()
    
    private init() {}
    
    // MARK: - Protein Targets (Lean Mass Based)
    
    /// Calculate protein target based on lean body mass
    /// General recommendation: 1.6-2.2g per kg of lean body mass
    /// For muscle building: 2.2g per kg LBM
    /// For maintenance: 1.6g per kg LBM
    func calculateProteinTarget(
        leanBodyMass: Double,
        goal: FitnessGoal,
        isActiveDay: Bool = false
    ) -> Double {
        guard leanBodyMass > 0 else { return 0 }
        
        let baseMultiplier: Double
        switch goal {
        case .buildMuscle:
            baseMultiplier = 2.2 // Higher for muscle building
        case .gainWeight:
            baseMultiplier = 2.0 // Higher for weight gain
        case .loseWeight:
            baseMultiplier = 2.0 // Higher to preserve muscle during deficit
        case .maintainWeight:
            baseMultiplier = 1.6 // Standard maintenance
        }
        
        // Increase on active days
        let multiplier = isActiveDay ? baseMultiplier * 1.1 : baseMultiplier
        
        return leanBodyMass * multiplier
    }
    
    // MARK: - Calorie Targets
    
    /// Calculate calorie target based on goal and TDEE
    func calculateCalorieTarget(
        tdee: Double,
        goal: FitnessGoal,
        cyclePhase: CyclePhase? = nil
    ) -> Double {
        guard tdee > 0 else { return 0 }
        
        var baseTarget: Double
        switch goal {
        case .loseWeight:
            baseTarget = tdee - 500 // 500 cal deficit for ~1lb/week
        case .buildMuscle:
            baseTarget = tdee + 300 // 300 cal surplus for muscle gain
        case .gainWeight:
            baseTarget = tdee + 300 // 300 cal surplus for weight gain
        case .maintainWeight:
            baseTarget = tdee
        }
        
        // Adjust for cycle phase (women only)
        if let phase = cyclePhase {
            baseTarget = adjustCaloriesForCyclePhase(baseTarget, phase: phase)
        }
        
        return baseTarget
    }
    
    /// Adjust calories based on menstrual cycle phase
    private func adjustCaloriesForCyclePhase(_ baseCalories: Double, phase: CyclePhase) -> Double {
        switch phase {
        case .menstruation:
            // Slightly lower during period, but add iron-rich foods
            return baseCalories - 50
        case .follicular:
            // Standard calories
            return baseCalories
        case .ovulation:
            // Slight increase for peak energy
            return baseCalories + 50
        case .luteal:
            // Increase for cravings and higher metabolism
            return baseCalories + 150
        }
    }
    
    // MARK: - Weekly Calorie Banking System
    
    /// Calculate weekly calorie budget
    func calculateWeeklyBudget(dailyTarget: Double) -> Double {
        return dailyTarget * 7
    }
    
    /// Calculate remaining weekly calories
    func calculateRemainingWeeklyCalories(
        weeklyBudget: Double,
        consumedThisWeek: Double
    ) -> Double {
        return max(0, weeklyBudget - consumedThisWeek)
    }
    
    /// Calculate calories available today (with weekly banking)
    func calculateAvailableCaloriesToday(
        dailyTarget: Double,
        weeklyBudget: Double,
        consumedThisWeek: Double,
        consumedToday: Double,
        dayOfWeek: Int // 1 = Sunday, 7 = Saturday
    ) -> Double {
        let remainingWeekly = calculateRemainingWeeklyCalories(
            weeklyBudget: weeklyBudget,
            consumedThisWeek: consumedThisWeek
        )
        
        let daysRemaining = max(1, 7 - dayOfWeek)
        let averageRemaining = remainingWeekly / Double(daysRemaining)
        
        // Allow flexibility: can use up to 150% of daily target if weekly budget allows
        let maxToday = dailyTarget * 1.5
        let available = min(maxToday, averageRemaining + (dailyTarget - consumedToday))
        
        return max(0, available)
    }
    
    // MARK: - Overeating Recovery Logic
    
    /// Calculate recovery adjustment after overeating
    func calculateRecoveryAdjustment(
        overateBy: Double,
        weeklyBudget: Double,
        consumedThisWeek: Double
    ) -> RecoveryPlan {
        let remainingWeekly = calculateRemainingWeeklyCalories(
            weeklyBudget: weeklyBudget,
            consumedThisWeek: consumedThisWeek
        )
        
        // If we have enough weekly budget, no adjustment needed
        if remainingWeekly >= overateBy {
            return RecoveryPlan(
                dailyReduction: 0,
                daysToRecover: 0,
                message: "No adjustment needed - within weekly budget"
            )
        }
        
        // Calculate how to spread the excess over remaining days
        let excess = overateBy - remainingWeekly
        let daysRemaining = 7 // Assume we'll spread over a week
        let dailyReduction = excess / Double(daysRemaining)
        
        return RecoveryPlan(
            dailyReduction: dailyReduction,
            daysToRecover: daysRemaining,
            message: "Spread \(Int(excess)) excess calories over \(daysRemaining) days"
        )
    }
    
    // MARK: - Macro Distribution
    
    /// Calculate macro distribution based on goal
    func calculateMacroDistribution(
        calories: Double,
        protein: Double,
        goal: FitnessGoal
    ) -> MacroDistribution {
        let proteinCalories = protein * 4
        let remainingCalories = calories - proteinCalories
        
        let (carbRatio, fatRatio): (Double, Double)
        switch goal {
        case .loseWeight:
            // Lower carbs, higher fat for satiety
            carbRatio = 0.35
            fatRatio = 0.40
        case .buildMuscle:
            // Higher carbs for energy
            carbRatio = 0.50
            fatRatio = 0.25
        case .gainWeight:
            // Higher carbs for weight gain
            carbRatio = 0.50
            fatRatio = 0.30
        case .maintainWeight:
            // Balanced
            carbRatio = 0.45
            fatRatio = 0.30
        }
        
        let carbs = (remainingCalories * carbRatio) / 4
        let fats = (remainingCalories * fatRatio) / 9
        
        return MacroDistribution(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats
        )
    }
}

// MARK: - Supporting Types

struct RecoveryPlan {
    let dailyReduction: Double
    let daysToRecover: Int
    let message: String
}

struct MacroDistribution {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double
}

