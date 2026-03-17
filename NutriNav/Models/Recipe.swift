//
//  Recipe.swift
//  NutriNav
//
//  Recipe model
//

import Foundation

struct Recipe: Identifiable, Codable {
    var id: UUID
    var title: String
    var description: String?
    var imageName: String
    var prepTime: Int // in minutes
    var calories: Int
    var protein: Int // in grams
    var carbs: Int? // in grams
    var fats: Int? // in grams
    var difficulty: Difficulty
    var tags: [RecipeTag]
    var ingredients: [String]
    var instructions: [String]
    var isFavorite: Bool
    
    init(id: UUID = UUID(), title: String, description: String? = nil, imageName: String, prepTime: Int, calories: Int, protein: Int, carbs: Int? = nil, fats: Int? = nil, difficulty: Difficulty, tags: [RecipeTag], ingredients: [String], instructions: [String], isFavorite: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.imageName = imageName
        self.prepTime = prepTime
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.difficulty = difficulty
        self.tags = tags
        self.ingredients = ingredients
        self.instructions = instructions
        self.isFavorite = isFavorite
    }
}

enum Difficulty: String, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "orange"
        case .hard: return "red"
        }
    }
}

enum RecipeTag: String, Codable {
    case highProtein = "High Protein"
    case quick = "Quick"
    case balanced = "Balanced"
    case filling = "Filling"
    case lowCal = "Low Cal"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
}

