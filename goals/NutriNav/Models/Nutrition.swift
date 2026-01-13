//
//  Nutrition.swift
//  NutriNav
//
//  Nutrition tracking models
//

import Foundation

struct DailyNutrition: Codable {
    var calories: NutritionGoal
    var protein: NutritionGoal
    var carbs: NutritionGoal
    var fats: NutritionGoal
    
    // Weekly banking support
    var weeklyBudget: Double = 0
    var consumedThisWeek: Double = 0
    var weekStartDate: Date = Date()
    
    var totalCompletion: Double {
        let total = calories.percentage + protein.percentage + carbs.percentage + fats.percentage
        return total / 4.0
    }
    
    /// Calculate remaining weekly calories
    var remainingWeeklyCalories: Double {
        return max(0, weeklyBudget - consumedThisWeek)
    }
    
    /// Calculate available calories today (with weekly banking)
    var availableCaloriesToday: Double {
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        return NutritionLogicService.shared.calculateAvailableCaloriesToday(
            dailyTarget: calories.target,
            weeklyBudget: weeklyBudget,
            consumedThisWeek: consumedThisWeek,
            consumedToday: calories.current,
            dayOfWeek: dayOfWeek
        )
    }
}

struct NutritionGoal: Codable {
    var current: Double
    var target: Double
    
    var percentage: Double {
        guard target > 0 else { return 0 }
        return min((current / target) * 100, 100)
    }
    
    var remaining: Double {
        return max(target - current, 0)
    }
}

struct NutritionStats {
    /// Calculate nutrition goals using real formulas from BodyMetricsService and NutritionLogicService
    static func calculateGoals(
        age: Int,
        gender: Gender,
        height: Double,
        weight: Double,
        activityLevel: ActivityLevel,
        goal: FitnessGoal,
        cyclePhase: CyclePhase? = nil,
        activeCalories: Double = 0
    ) -> DailyNutrition {
        let bodyMetrics = BodyMetricsService.shared.calculateAllMetrics(
            weight: weight,
            height: height,
            age: age,
            gender: gender,
            activityLevel: activityLevel,
            activeCalories: activeCalories
        )
        
        // Calculate protein target based on lean body mass
        let proteinTarget = NutritionLogicService.shared.calculateProteinTarget(
            leanBodyMass: bodyMetrics.leanBodyMass,
            goal: goal,
            isActiveDay: activeCalories > 300
        )
        
        // Calculate calorie target
        let calorieTarget = NutritionLogicService.shared.calculateCalorieTarget(
            tdee: bodyMetrics.tdee,
            goal: goal,
            cyclePhase: cyclePhase
        )
        
        // Calculate macro distribution
        let macros = NutritionLogicService.shared.calculateMacroDistribution(
            calories: calorieTarget,
            protein: proteinTarget,
            goal: goal
        )
        
        // Initialize with current values (will be updated from food logs)
        let calories = NutritionGoal(current: 0, target: calorieTarget)
        let protein = NutritionGoal(current: 0, target: proteinTarget)
        let carbs = NutritionGoal(current: 0, target: macros.carbs)
        let fats = NutritionGoal(current: 0, target: macros.fats)
        
        return DailyNutrition(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats
        )
    }
}

