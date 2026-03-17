//
//  AnalyticsService.swift
//  NutriNav
//
//  TelemetryDeck analytics integration
//

import Foundation

class AnalyticsService {
    static let shared = AnalyticsService()
    
    private var apiKey: String? = nil // Add your TelemetryDeck API key here
    private var appId: String = "nutrinav" // Your app ID
    
    private init() {}
    
    // MARK: - Event Tracking
    
    /// Track when user achieves a nutrition goal
    func trackGoalAchieved(goalType: String, value: Double, target: Double) {
        let event = AnalyticsEvent(
            name: "goal_achieved",
            properties: [
                "goal_type": goalType,
                "value": value,
                "target": target,
                "percentage": (value / target) * 100
            ]
        )
        logEvent(event)
    }
    
    /// Track when user views a recipe
    func trackRecipeViewed(recipeId: String, recipeName: String) {
        let event = AnalyticsEvent(
            name: "recipe_viewed",
            properties: [
                "recipe_id": recipeId,
                "recipe_name": recipeName
            ]
        )
        logEvent(event)
    }
    
    /// Track when user tries a recipe
    func trackRecipeTried(recipeId: String, recipeName: String) {
        let event = AnalyticsEvent(
            name: "recipe_tried",
            properties: [
                "recipe_id": recipeId,
                "recipe_name": recipeName
            ]
        )
        logEvent(event)
    }
    
    /// Track nearby food usage
    func trackNearbyFoodUsed(restaurantId: String, restaurantName: String, ordered: Bool) {
        let event = AnalyticsEvent(
            name: "nearby_food_used",
            properties: [
                "restaurant_id": restaurantId,
                "restaurant_name": restaurantName,
                "ordered": ordered
            ]
        )
        logEvent(event)
    }
    
    /// Track activity/hobby completion
    func trackActivityCompleted(activityType: String, duration: TimeInterval, caloriesBurned: Double) {
        let event = AnalyticsEvent(
            name: "activity_completed",
            properties: [
                "activity_type": activityType,
                "duration_minutes": duration / 60,
                "calories_burned": caloriesBurned
            ]
        )
        logEvent(event)
    }
    
    /// Track badge unlocked
    func trackBadgeUnlocked(badgeName: String, badgeType: String) {
        let event = AnalyticsEvent(
            name: "badge_unlocked",
            properties: [
                "badge_name": badgeName,
                "badge_type": badgeType
            ]
        )
        logEvent(event)
    }
    
    /// Track onboarding completion
    func trackOnboardingCompleted(age: Int, gender: String, goal: String) {
        let event = AnalyticsEvent(
            name: "onboarding_completed",
            properties: [
                "age": age,
                "gender": gender,
                "goal": goal
            ]
        )
        logEvent(event)
    }
    
    /// Track HealthKit connection
    func trackHealthKitConnected(connected: Bool) {
        let event = AnalyticsEvent(
            name: "healthkit_connected",
            properties: [
                "connected": connected
            ]
        )
        logEvent(event)
    }
    
    // MARK: - Private Methods
    
    private func logEvent(_ event: AnalyticsEvent) {
        // TODO: Replace with actual TelemetryDeck API call
        // For MVP, just print to console
        print("📊 Analytics Event: \(event.name)")
        print("   Properties: \(event.properties)")
        
        // In production, send to TelemetryDeck:
        // sendToTelemetryDeck(event)
    }
    
    private func sendToTelemetryDeck(_ event: AnalyticsEvent) {
        guard let apiKey = apiKey else {
            print("⚠️ TelemetryDeck API key not set")
            return
        }
        
        // TODO: Implement TelemetryDeck API call
        // Example structure:
        /*
        let url = URL(string: "https://nom.telemetrydeck.com/api/v1/apps/\(appId)/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "event": event.name,
            "properties": event.properties,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle response
        }.resume()
        */
    }
}

struct AnalyticsEvent {
    let name: String
    let properties: [String: Any]
}

