//
//  BodyMetricsService.swift
//  NutriNav
//
//  Real body metrics calculations using verified formulas
//

import Foundation

class BodyMetricsService {
    static let shared = BodyMetricsService()
    
    private init() {}
    
    // MARK: - BMI Calculation
    
    /// Calculate BMI (Body Mass Index)
    /// Formula: weight (kg) / height (m)²
    func calculateBMI(weight: Double, height: Double) -> Double {
        guard height > 0, weight > 0 else { return 0 }
        let heightInMeters = height / 100.0 // Convert cm to meters
        return weight / (heightInMeters * heightInMeters)
    }
    
    /// Get BMI category
    func getBMICategory(bmi: Double) -> BMICategory {
        switch bmi {
        case ..<18.5:
            return .underweight
        case 18.5..<25.0:
            return .normal
        case 25.0..<30.0:
            return .overweight
        default:
            return .obese
        }
    }
    
    // MARK: - Lean Body Mass (Boer Formula)
    
    /// Calculate Lean Body Mass using Boer formula
    /// Men: LBM = 0.407 × weight + 0.267 × height - 19.2
    /// Women: LBM = 0.252 × weight + 0.473 × height - 48.3
    func calculateLeanBodyMass(weight: Double, height: Double, gender: Gender) -> Double {
        guard weight > 0, height > 0 else { return 0 }
        
        switch gender {
        case .male:
            return 0.407 * weight + 0.267 * height - 19.2
        case .female:
            return 0.252 * weight + 0.473 * height - 48.3
        case .other:
            // Use average of male and female formulas
            let maleLBM = 0.407 * weight + 0.267 * height - 19.2
            let femaleLBM = 0.252 * weight + 0.473 * height - 48.3
            return (maleLBM + femaleLBM) / 2.0
        }
    }
    
    /// Calculate Fat Mass
    func calculateFatMass(weight: Double, leanBodyMass: Double) -> Double {
        return max(0, weight - leanBodyMass)
    }
    
    /// Calculate Body Fat Percentage
    func calculateBodyFatPercentage(weight: Double, leanBodyMass: Double) -> Double {
        guard weight > 0 else { return 0 }
        let fatMass = calculateFatMass(weight: weight, leanBodyMass: leanBodyMass)
        return (fatMass / weight) * 100.0
    }
    
    // MARK: - BMR (Basal Metabolic Rate) - Mifflin-St Jeor Formula
    
    /// Calculate BMR using Mifflin-St Jeor equation
    /// Men: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) + 5
    /// Women: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) - 161
    func calculateBMR(weight: Double, height: Double, age: Int, gender: Gender) -> Double {
        guard weight > 0, height > 0, age > 0 else { return 0 }
        
        let baseBMR = 10 * weight + 6.25 * height - 5 * Double(age)
        
        switch gender {
        case .male:
            return baseBMR + 5
        case .female:
            return baseBMR - 161
        case .other:
            // Use average
            return baseBMR - 78
        }
    }
    
    // MARK: - TDEE (Total Daily Energy Expenditure)
    
    /// Calculate TDEE using BMR and activity multiplier
    /// TDEE = BMR × Activity Multiplier
    func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Double {
        let multiplier = activityLevel.multiplier
        return bmr * multiplier
    }
    
    /// Calculate TDEE with HealthKit activity data
    /// TDEE = BMR + Active Energy Burned
    func calculateTDEEWithActivity(bmr: Double, activeCalories: Double) -> Double {
        return bmr + activeCalories
    }
    
    // MARK: - Complete Body Metrics
    
    /// Calculate all body metrics at once
    func calculateAllMetrics(
        weight: Double,
        height: Double,
        age: Int,
        gender: Gender,
        activityLevel: ActivityLevel,
        activeCalories: Double = 0
    ) -> BodyMetrics {
        let bmi = calculateBMI(weight: weight, height: height)
        let leanBodyMass = calculateLeanBodyMass(weight: weight, height: height, gender: gender)
        let fatMass = calculateFatMass(weight: weight, leanBodyMass: leanBodyMass)
        let bodyFatPercentage = calculateBodyFatPercentage(weight: weight, leanBodyMass: leanBodyMass)
        let bmr = calculateBMR(weight: weight, height: height, age: age, gender: gender)
        
        let tdee: Double
        if activeCalories > 0 {
            tdee = calculateTDEEWithActivity(bmr: bmr, activeCalories: activeCalories)
        } else {
            tdee = calculateTDEE(bmr: bmr, activityLevel: activityLevel)
        }
        
        return BodyMetrics(
            bmi: bmi,
            bmiCategory: getBMICategory(bmi: bmi),
            leanBodyMass: leanBodyMass,
            fatMass: fatMass,
            bodyFatPercentage: bodyFatPercentage,
            bmr: bmr,
            tdee: tdee
        )
    }
}

// MARK: - Supporting Types

struct BodyMetrics {
    let bmi: Double
    let bmiCategory: BMICategory
    let leanBodyMass: Double
    let fatMass: Double
    let bodyFatPercentage: Double
    let bmr: Double
    let tdee: Double
}

enum BMICategory: String {
    case underweight = "Underweight"
    case normal = "Normal"
    case overweight = "Overweight"
    case obese = "Obese"
}

extension ActivityLevel {
    var multiplier: Double {
        switch self {
        case .sedentary:
            return 1.2
        case .lightlyActive:
            return 1.375
        case .moderatelyActive:
            return 1.55
        case .veryActive:
            return 1.725
        case .extremelyActive:
            return 1.9
        }
    }
}

