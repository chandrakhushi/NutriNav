//
//  MockDataService.swift
//  NutriNav
//
//  Mock data service for MVP development
//

import Foundation

class MockDataService {
    static let shared = MockDataService()
    
    // MARK: - Mock Recipes
    func getRecipes() -> [Recipe] {
        return [
            Recipe(
                title: "Grilled Chicken & Rice Bowl",
                imageName: "chicken_rice_bowl",
                prepTime: 25,
                calories: 450,
                protein: 42,
                carbs: 45,
                fats: 12,
                difficulty: .easy,
                tags: [.highProtein, .quick],
                ingredients: ["chicken breast", "rice", "broccoli", "soy sauce", "sesame oil"],
                instructions: ["Cook rice", "Grill chicken", "Steam broccoli", "Combine and serve"]
            ),
            Recipe(
                title: "Protein-Packed Buddha Bowl",
                imageName: "buddha_bowl",
                prepTime: 30,
                calories: 520,
                protein: 35,
                carbs: 60,
                fats: 15,
                difficulty: .medium,
                tags: [.balanced, .filling],
                ingredients: ["brown rice", "chickpeas", "sweet potato", "kale", "feta cheese"],
                instructions: ["Roast sweet potato", "Cook rice", "Prepare chickpeas", "Assemble bowl"]
            ),
            Recipe(
                title: "Lemon Herb Chicken",
                imageName: "lemon_chicken",
                prepTime: 35,
                calories: 320,
                protein: 45,
                carbs: 10,
                fats: 12,
                difficulty: .easy,
                tags: [.highProtein, .lowCal],
                ingredients: ["chicken breast", "lemon", "herbs", "olive oil", "garlic"],
                instructions: ["Marinate chicken", "Pan sear", "Add lemon and herbs", "Serve"]
            )
        ]
    }
    
    func getRecipesForIngredients(_ ingredients: [String]) -> [Recipe] {
        // Simple matching logic - in production, use ML/NLP
        let allRecipes = getRecipes()
        return allRecipes.filter { recipe in
            ingredients.contains { ingredient in
                recipe.ingredients.contains { $0.lowercased().contains(ingredient.lowercased()) }
            }
        }
    }
    
    // MARK: - Mock Restaurants
    func getRestaurants() -> [Restaurant] {
        return [
            Restaurant(
                name: "Green Bowl Kitchen",
                cuisine: ["Healthy", "Bowls"],
                isOpen: true,
                rating: 4.8,
                priceRange: .moderate,
                distance: 0.3,
                averageCalories: 450,
                averageProtein: 35,
                imageName: "green_bowl",
                address: "123 Main St, San Francisco, CA",
                orderLink: "https://doordash.com/green-bowl-kitchen"
            ),
            Restaurant(
                name: "Protein Bar & Kitchen",
                cuisine: ["American", "Healthy"],
                isOpen: true,
                rating: 4.6,
                priceRange: .moderate,
                distance: 0.5,
                averageCalories: 520,
                averageProtein: 42,
                imageName: "protein_bar",
                address: "456 Market St, San Francisco, CA",
                orderLink: "https://ubereats.com/protein-bar"
            ),
            Restaurant(
                name: "Mediterranean Grill",
                cuisine: ["Mediterranean", "Healthy"],
                isOpen: true,
                rating: 4.7,
                priceRange: .moderate,
                distance: 0.8,
                averageCalories: 480,
                averageProtein: 38,
                imageName: "mediterranean_grill",
                address: "789 Mission St, San Francisco, CA"
            )
        ]
    }
    
    // MARK: - Mock Activities
    func getTodayActivities() -> [Activity] {
        return [
            Activity(
                name: "Morning Run",
                type: .running,
                duration: 1800, // 30 minutes
                caloriesBurned: 280,
                date: Date(),
                source: .healthKit
            )
        ]
    }
    
    // MARK: - Mock Hobbies
    func getHobbies() -> [Hobby] {
        return [
            Hobby(name: "Running", type: .running, isSelected: true, weeklyGoal: 5, currentWeekHours: 2.5),
            Hobby(name: "Cycling", type: .cycling, isSelected: false, weeklyGoal: 3),
            Hobby(name: "Yoga", type: .yoga, isSelected: true, weeklyGoal: 4, currentWeekHours: 1.5),
            Hobby(name: "Gym", type: .gym, isSelected: true, weeklyGoal: 6, currentWeekHours: 3.0),
            Hobby(name: "Swimming", type: .swimming, isSelected: false),
            Hobby(name: "Hiking", type: .hiking, isSelected: false),
            Hobby(name: "Dancing", type: .dancing, isSelected: false)
        ]
    }
    
    // MARK: - Mock Expenses
    func getExpenses() -> [MealExpense] {
        return [
            MealExpense(name: "Grilled Chicken Bowl", cost: 12.50, date: Date(), type: .restaurant),
            MealExpense(name: "Protein Smoothie", cost: 8.00, date: Date().addingTimeInterval(-86400), type: .recipe),
            MealExpense(name: "Salmon & Veggies", cost: 15.00, date: Date().addingTimeInterval(-172800), type: .restaurant),
            MealExpense(name: "Grocery Shopping", cost: 45.50, date: Date().addingTimeInterval(-259200), type: .grocery)
        ]
    }
}

