//
//  Hobby.swift
//  NutriNav
//
//  Hobby and activity selection models
//

import Foundation

struct Hobby: Identifiable, Codable {
    var id: UUID
    var name: String
    var type: ActivityType
    var isSelected: Bool
    var weeklyGoal: Int? // hours per week
    var currentWeekHours: Double
    var badges: [HobbyBadge]
    
    init(id: UUID = UUID(), name: String, type: ActivityType, isSelected: Bool = false, weeklyGoal: Int? = nil, currentWeekHours: Double = 0, badges: [HobbyBadge] = []) {
        self.id = id
        self.name = name
        self.type = type
        self.isSelected = isSelected
        self.weeklyGoal = weeklyGoal
        self.currentWeekHours = currentWeekHours
        self.badges = badges
    }
}

struct HobbyBadge: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var icon: String
    var unlockedDate: Date?
    var requirement: BadgeRequirement
    
    init(id: UUID = UUID(), name: String, description: String, icon: String, requirement: BadgeRequirement, unlockedDate: Date? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.requirement = requirement
        self.unlockedDate = unlockedDate
    }
    
    var isUnlocked: Bool {
        return unlockedDate != nil
    }
}

enum BadgeRequirement: Codable {
    case streak(days: Int)
    case workouts(count: Int)
    case caloriesBurned(total: Double)
    case recipesTried(count: Int)
    case weeklyGoal(weeks: Int)
}

