//
//  LazyDayService.swift
//  NutriNav
//
//  Lazy Day Mode - smart filtering for nearby food options
//

import Foundation
import CoreLocation

class LazyDayService {
    static let shared = LazyDayService()
    
    private init() {}
    
    // MARK: - Lazy Day Filtering
    
    /// Filter nearby restaurants based on remaining calories, protein needs, distance, and budget
    func filterLazyDayOptions(
        restaurants: [Restaurant],
        remainingCalories: Double,
        remainingProtein: Double,
        userLocation: CLLocation?,
        maxDistance: Double = 5.0, // miles
        budget: PriceRange? = nil,
        dietaryRestrictions: [DietaryRestriction] = []
    ) -> [Restaurant] {
        var filtered = restaurants
        
        // Filter by distance
        if let userLocation = userLocation {
            filtered = filtered.filter { restaurant in
                // Convert distance (assuming it's in miles) to check
                restaurant.distance <= maxDistance
            }
        }
        
        // Filter by budget
        if let budget = budget {
            filtered = filtered.filter { $0.priceRange == budget }
        }
        
        // Filter by dietary restrictions
        if !dietaryRestrictions.isEmpty {
            // TODO: Add dietary restriction matching logic
            // This would require restaurant data to include dietary info
        }
        
        // Score and sort by relevance
        let scored = filtered.map { restaurant in
            let score = calculateLazyDayScore(
                restaurant: restaurant,
                remainingCalories: remainingCalories,
                remainingProtein: remainingProtein
            )
            return (restaurant: restaurant, score: score)
        }
        
        // Sort by score (highest first) and return restaurants
        return scored
            .sorted { $0.score > $1.score }
            .map { $0.restaurant }
    }
    
    /// Calculate relevance score for lazy day mode
    private func calculateLazyDayScore(
        restaurant: Restaurant,
        remainingCalories: Double,
        remainingProtein: Double
    ) -> Double {
        var score: Double = 0
        
        // Calorie match score (prefer restaurants with meals close to remaining calories)
        let calorieDiff = abs(Double(restaurant.averageCalories) - remainingCalories)
        let calorieScore = max(0, 100 - (calorieDiff / 10)) // Higher score for closer match
        score += calorieScore * 0.4
        
        // Protein match score
        let proteinDiff = abs(Double(restaurant.averageProtein) - remainingProtein)
        let proteinScore = max(0, 100 - (proteinDiff * 2)) // Protein is more important
        score += proteinScore * 0.4
        
        // Distance score (closer is better)
        let distanceScore = max(0, 100 - (restaurant.distance * 20))
        score += distanceScore * 0.2
        
        // Bonus for verified nutrition data
        // TODO: Add verified flag to Restaurant model
        // if restaurant.hasVerifiedNutrition {
        //     score += 10
        // }
        
        return score
    }
    
    /// Get recommended meal options for lazy day
    func getRecommendedMeals(
        restaurants: [Restaurant],
        remainingCalories: Double,
        remainingProtein: Double
    ) -> [RecommendedMeal] {
        return restaurants.compactMap { restaurant in
            let calorieMatch = abs(Double(restaurant.averageCalories) - remainingCalories) < 200
            let proteinMatch = Double(restaurant.averageProtein) >= remainingProtein * 0.8
            
            if calorieMatch && proteinMatch {
                return RecommendedMeal(
                    restaurant: restaurant,
                    reason: generateRecommendationReason(
                        restaurant: restaurant,
                        remainingCalories: remainingCalories,
                        remainingProtein: remainingProtein
                    )
                )
            }
            return nil
        }
    }
    
    private func generateRecommendationReason(
        restaurant: Restaurant,
        remainingCalories: Double,
        remainingProtein: Double
    ) -> String {
        var reasons: [String] = []
        
        if abs(Double(restaurant.averageCalories) - remainingCalories) < 100 {
            reasons.append("Perfect calorie match")
        }
        
        if Double(restaurant.averageProtein) >= remainingProtein {
            reasons.append("High protein")
        }
        
        if restaurant.distance < 1.0 {
            reasons.append("Very close")
        }
        
        return reasons.joined(separator: " • ")
    }
}

// MARK: - Supporting Types

struct RecommendedMeal {
    let restaurant: Restaurant
    let reason: String
}

