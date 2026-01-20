//
//  NutritionEstimationService.swift
//  NutriNav
//
//  Nutrition estimation based on cuisine type
//

import Foundation

class NutritionEstimationService {
    static let shared = NutritionEstimationService()
    
    private init() {}
    
    // MARK: - Cuisine-Based Nutrition Estimates
    
    /// Estimate average calories and protein for a restaurant based on cuisine type
    /// Returns: (calories: Int, protein: Int)
    func estimateNutrition(for cuisineTypes: [String], priceRange: PriceRange) -> (calories: Int, protein: Int) {
        // Normalize cuisine types to lowercase for matching
        let normalizedCuisines = cuisineTypes.map { $0.lowercased() }
        
        // Base estimates by cuisine category
        var baseCalories: Int = 500 // Default
        var baseProtein: Int = 30 // Default in grams
        
        // Determine primary cuisine category
        if normalizedCuisines.contains(where: { $0.contains("healthy") || $0.contains("bowl") || $0.contains("salad") }) {
            // Healthy/Bowl restaurants
            baseCalories = 450
            baseProtein = 35
        } else if normalizedCuisines.contains(where: { $0.contains("mediterranean") || $0.contains("greek") }) {
            // Mediterranean
            baseCalories = 480
            baseProtein = 38
        } else if normalizedCuisines.contains(where: { $0.contains("asian") || $0.contains("chinese") || $0.contains("japanese") || $0.contains("thai") || $0.contains("korean") }) {
            // Asian cuisine
            baseCalories = 520
            baseProtein = 32
        } else if normalizedCuisines.contains(where: { $0.contains("mexican") || $0.contains("taco") || $0.contains("burrito") }) {
            // Mexican
            baseCalories = 580
            baseProtein = 28
        } else if normalizedCuisines.contains(where: { $0.contains("italian") || $0.contains("pizza") || $0.contains("pasta") }) {
            // Italian
            baseCalories = 620
            baseProtein = 25
        } else if normalizedCuisines.contains(where: { $0.contains("american") || $0.contains("burger") || $0.contains("bbq") }) {
            // American
            baseCalories = 680
            baseProtein = 40
        } else if normalizedCuisines.contains(where: { $0.contains("indian") }) {
            // Indian
            baseCalories = 550
            baseProtein = 22
        } else if normalizedCuisines.contains(where: { $0.contains("seafood") || $0.contains("fish") }) {
            // Seafood
            baseCalories = 480
            baseProtein = 42
        } else if normalizedCuisines.contains(where: { $0.contains("vegetarian") || $0.contains("vegan") }) {
            // Vegetarian/Vegan
            baseCalories = 420
            baseProtein = 20
        } else if normalizedCuisines.contains(where: { $0.contains("fast food") || $0.contains("fast-food") }) {
            // Fast food
            baseCalories = 600
            baseProtein = 25
        }
        
        // Adjust based on price range (more expensive = typically larger portions or higher quality ingredients)
        let priceMultiplier: Double
        switch priceRange {
        case .budget:
            priceMultiplier = 0.9 // Slightly smaller portions
        case .moderate:
            priceMultiplier = 1.0 // Standard
        case .expensive:
            priceMultiplier = 1.15 // Larger portions or richer ingredients
        case .veryExpensive:
            priceMultiplier = 1.25 // Premium portions
        }
        
        let estimatedCalories = Int(Double(baseCalories) * priceMultiplier)
        let estimatedProtein = Int(Double(baseProtein) * priceMultiplier)
        
        return (calories: estimatedCalories, protein: estimatedProtein)
    }
}

