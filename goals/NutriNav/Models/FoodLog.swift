//
//  FoodLog.swift
//  NutriNav
//
//  Food logging models with accurate nutrition data
//

import Foundation

struct FoodLog: Identifiable, Codable {
    var id: UUID
    var date: Date
    var entries: [FoodEntry]
    
    init(id: UUID = UUID(), date: Date = Date(), entries: [FoodEntry] = []) {
        self.id = id
        self.date = date
        self.entries = entries
    }
    
    var totalCalories: Double {
        entries.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Double {
        entries.reduce(0) { $0 + $1.protein }
    }
    
    var totalCarbs: Double {
        entries.reduce(0) { $0 + $1.carbs }
    }
    
    var totalFats: Double {
        entries.reduce(0) { $0 + $1.fats }
    }
}

struct FoodEntry: Identifiable, Codable {
    var id: UUID
    var name: String
    var source: FoodSource
    var calories: Double
    var protein: Double
    var carbs: Double
    var fats: Double
    var servingSize: String?
    var quantity: Double
    var timestamp: Date
    var mealType: MealType?
    var confirmedByUser: Bool // User confirmed AI-detected food
    var barcode: String? // If scanned
    var restaurantId: UUID? // If from restaurant
    var photoId: UUID? // If from photo scan (future)
    
    init(
        id: UUID = UUID(),
        name: String,
        source: FoodSource,
        calories: Double,
        protein: Double,
        carbs: Double,
        fats: Double,
        servingSize: String? = nil,
        quantity: Double = 1.0,
        timestamp: Date = Date(),
        mealType: MealType? = nil,
        confirmedByUser: Bool = true,
        barcode: String? = nil,
        restaurantId: UUID? = nil,
        photoId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.servingSize = servingSize
        self.quantity = quantity
        self.timestamp = timestamp
        self.mealType = mealType
        self.confirmedByUser = confirmedByUser
        self.barcode = barcode
        self.restaurantId = restaurantId
        self.photoId = photoId
    }
}

enum MealType: String, Codable, CaseIterable, Hashable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snacks = "Snacks"
}

enum FoodSource: String, Codable {
    case manual = "Manual Entry"
    case barcode = "Barcode Scan"
    case restaurant = "Restaurant"
    case photoScan = "Photo Scan" // Future feature
}

// MARK: - Verified Nutrition Database Models

struct NutritionDatabase {
    // Placeholder for verified nutrition database
    // In production, this would connect to USDA FoodData Central or similar
    
    static func getNutritionForFood(_ foodName: String) -> FoodEntry? {
        // TODO: Implement database lookup
        return nil
    }
    
    static func getNutritionForBarcode(_ barcode: String) -> FoodEntry? {
        // TODO: Implement barcode lookup (Open Food Facts API)
        return nil
    }
}

// MARK: - Restaurant Chain Nutrition

struct RestaurantChain {
    let id: UUID
    let name: String
    let menuItems: [MenuItem]
}

struct MenuItem: Identifiable, Codable {
    var id: UUID
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fats: Double
    var verified: Bool // Whether nutrition data is verified by restaurant
    
    init(
        id: UUID = UUID(),
        name: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fats: Double,
        verified: Bool = false
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.verified = verified
    }
}

