//
//  Budget.swift
//  NutriNav
//
//  Budget and meal planning models
//

import Foundation

struct Budget: Codable {
    var weeklyBudget: Double
    var currentWeekSpending: Double
    var weekStartDate: Date
    
    var remaining: Double {
        return max(weeklyBudget - currentWeekSpending, 0)
    }
    
    var percentageUsed: Double {
        guard weeklyBudget > 0 else { return 0 }
        return min((currentWeekSpending / weeklyBudget) * 100, 100)
    }
    
    init(weeklyBudget: Double = 100.0, currentWeekSpending: Double = 0, weekStartDate: Date = Date()) {
        self.weeklyBudget = weeklyBudget
        self.currentWeekSpending = currentWeekSpending
        self.weekStartDate = weekStartDate
    }
}

struct MealExpense: Identifiable, Codable {
    var id: UUID
    var name: String
    var cost: Double
    var date: Date
    var type: ExpenseType
    var recipeId: UUID?
    var restaurantId: UUID?
    
    init(id: UUID = UUID(), name: String, cost: Double, date: Date = Date(), type: ExpenseType, recipeId: UUID? = nil, restaurantId: UUID? = nil) {
        self.id = id
        self.name = name
        self.cost = cost
        self.date = date
        self.type = type
        self.recipeId = recipeId
        self.restaurantId = restaurantId
    }
}

enum ExpenseType: String, Codable {
    case recipe = "Recipe"
    case restaurant = "Restaurant"
    case grocery = "Grocery"
    case other = "Other"
}

