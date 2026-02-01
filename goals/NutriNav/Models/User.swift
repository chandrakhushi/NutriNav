//
//  User.swift
//  NutriNav
//
//  User model for profile and onboarding data
//

import Foundation

struct User: Codable {
    var dateOfBirth: Date?
    
    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }
    
    var gender: Gender?
    var height: Double? // in cm
    var weight: Double? // in kg
    var activityLevel: ActivityLevel?
    var goal: FitnessGoal?
    var name: String
    var email: String
    var dietaryRestrictions: [DietaryRestriction]
    var cyclePhase: CyclePhase?
    
    init() {
        self.name = ""
        self.email = ""
        self.dietaryRestrictions = []
    }
}

enum Gender: String, Codable, CaseIterable {
    case female = "Female"
    case male = "Male"
    
    var symbol: String {
        switch self {
        case .female: return "person.fill" // SF Symbol name
        case .male: return "person.fill"    // SF Symbol name
        }
    }
    
    var emoji: String {
        switch self {
        case .female: return "👩"
        case .male: return "👨"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly Active"
    case moderatelyActive = "Moderately Active"
    case veryActive = "Very Active"
    case extremelyActive = "Extremely Active"
    
    var emoji: String {
        switch self {
        case .sedentary: return "🛋️"
        case .lightlyActive: return "🚶"
        case .moderatelyActive: return "🏃"
        case .veryActive: return "💪"
        case .extremelyActive: return "🔥"
        }
    }
    
    var description: String {
        switch self {
        case .sedentary: return "Little to no exercise"
        case .lightlyActive: return "Light exercise 1-3 days/week"
        case .moderatelyActive: return "Moderate exercise 3-5 days/week"
        case .veryActive: return "Hard exercise 6-7 days/week"
        case .extremelyActive: return "Very hard exercise, physical job"
        }
    }
}

enum FitnessGoal: String, Codable, CaseIterable {
    case loseWeight = "Lose Weight"
    case maintainWeight = "Maintain Weight"
    case gainWeight = "Gain Weight"
    case buildMuscle = "Build Muscle"
    
    var emoji: String {
        switch self {
        case .loseWeight: return "📉"
        case .maintainWeight: return "⚖️"
        case .gainWeight: return "📈"
        case .buildMuscle: return "💪"
        }
    }
    
    var description: String {
        switch self {
        case .loseWeight: return "Sustainable weight loss"
        case .maintainWeight: return "Maintain current weight"
        case .gainWeight: return "Increase body weight"
        case .buildMuscle: return "Gain muscle and strength"
        }
    }
}

enum DietaryRestriction: String, Codable, CaseIterable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case keto = "Keto"
    case paleo = "Paleo"
}

enum CyclePhase: String, Codable {
    case follicular = "Follicular"
    case ovulation = "Ovulation"
    case luteal = "Luteal"
    case menstruation = "Menstruation"
}

