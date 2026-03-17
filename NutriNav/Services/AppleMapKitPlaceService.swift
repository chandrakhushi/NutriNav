//
//  AppleMapKitPlaceService.swift
//  NutriNav
//
//  FREE restaurant search using Apple MapKit Local Search
//  No API keys required - works out of the box
//

import Foundation
import CoreLocation
import MapKit

class AppleMapKitPlaceService: PlaceSearchService {
    static let shared = AppleMapKitPlaceService()
    
    var isAvailable: Bool {
        return true // Always available, no API key needed
    }
    
    private init() {}
    
    // MARK: - PlaceSearchService Implementation
    
    func searchNearbyRestaurants(
        location: CLLocation,
        radius: Int,
        limit: Int,
        priceFilter: PriceRange?,
        query: String? = nil
    ) async throws -> [Restaurant] {
        // Create search request
        let request = MKLocalSearch.Request()
        
        // Use custom query if provided, otherwise default to "restaurant"
        if let query = query, !query.isEmpty {
            request.naturalLanguageQuery = "\(query) restaurant"
        } else {
            request.naturalLanguageQuery = "restaurant"
        }
        
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: Double(radius) * 2, // MapKit uses diameter
            longitudinalMeters: Double(radius) * 2
        )
        request.resultTypes = [.pointOfInterest, .address]
        
        // Perform search
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        // Convert MapKit results to Restaurant models
        var restaurants: [Restaurant] = []
        
        for item in response.mapItems.prefix(limit) {
            // Filter by price if specified
            if let priceFilter = priceFilter {
                let itemPriceLevel = estimatePriceLevel(from: item)
                if itemPriceLevel != priceFilter {
                    continue
                }
            }
            
            if let restaurant = convertMapItemToRestaurant(item, userLocation: location) {
                restaurants.append(restaurant)
            }
        }
        
        return restaurants
    }
    
    // MARK: - Helper Methods
    
    private func convertMapItemToRestaurant(_ item: MKMapItem, userLocation: CLLocation) -> Restaurant? {
        guard let name = item.name, !name.isEmpty else { return nil }
        
        // Extract cuisine/category from MapKit categories
        let cuisineTypes = extractCuisineTypes(from: item)
        
        // Estimate price level
        let priceLevel = estimatePriceLevel(from: item)
        
        // Calculate distance
        let restaurantLocation = item.placemark.location ?? userLocation
        let distanceInMeters = userLocation.distance(from: restaurantLocation)
        let distanceInMiles = distanceInMeters / 1609.34
        
        // Estimate nutrition based on cuisine
        let nutrition = NutritionEstimationService.shared.estimateNutrition(
            for: cuisineTypes,
            priceRange: priceLevel
        )
        
        // Build address
        let address = formatAddress(from: item.placemark)
        
        // Check if open (best effort - MapKit doesn't always provide this)
        let isOpen = item.pointOfInterestCategory != nil // Assume open if it's a POI
        
        return Restaurant(
            id: UUID(),
            name: name,
            cuisine: cuisineTypes,
            isOpen: isOpen,
            rating: 0.0, // MapKit doesn't provide ratings
            priceRange: priceLevel,
            distance: distanceInMiles,
            averageCalories: nutrition.calories,
            averageProtein: nutrition.protein,
            imageName: "", // Not used
            address: address,
            phoneNumber: item.phoneNumber,
            orderLink: nil, // Not available from MapKit
            imageURL: nil, // Not available from MapKit
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude
        )
    }
    
    private func extractCuisineTypes(from item: MKMapItem) -> [String] {
        var cuisines: [String] = []
        
        // Extract from restaurant name (primary method)
        if let name = item.name?.lowercased() {
            if name.contains("italian") || name.contains("pizza") || name.contains("pasta") {
                cuisines.append("Italian")
            } else if name.contains("chinese") || name.contains("asian") {
                cuisines.append("Asian")
            } else if name.contains("mexican") || name.contains("taco") || name.contains("burrito") {
                cuisines.append("Mexican")
            } else if name.contains("japanese") || name.contains("sushi") {
                cuisines.append("Japanese")
            } else if name.contains("thai") {
                cuisines.append("Thai")
            } else if name.contains("indian") {
                cuisines.append("Indian")
            } else if name.contains("mediterranean") || name.contains("greek") {
                cuisines.append("Mediterranean")
            } else if name.contains("american") || name.contains("burger") || name.contains("bbq") {
                cuisines.append("American")
            } else if name.contains("seafood") || name.contains("fish") {
                cuisines.append("Seafood")
            } else if name.contains("vegetarian") || name.contains("vegan") {
                cuisines.append("Vegetarian")
            } else if name.contains("healthy") || name.contains("bowl") || name.contains("salad") {
                cuisines.append("Healthy")
            } else if name.contains("korean") {
                cuisines.append("Korean")
            } else if name.contains("vietnamese") || name.contains("pho") {
                cuisines.append("Vietnamese")
            } else if name.contains("french") || name.contains("bistro") {
                cuisines.append("French")
            }
        }
        
        // Fallback to generic "Restaurant" if no specific cuisine found
        if cuisines.isEmpty {
            cuisines.append("Restaurant")
        }
        
        return cuisines
    }
    
    private func estimatePriceLevel(from item: MKMapItem) -> PriceRange {
        // MapKit doesn't provide price level directly
        // Use heuristics based on name and category
        
        guard let name = item.name?.lowercased() else {
            return .moderate // Default
        }
        
        // Expensive indicators (fine dining, upscale)
        if name.contains("fine dining") || name.contains("steakhouse") ||
           name.contains("bistro") || name.contains("grille") || name.contains("chophouse") {
            return .expensive
        }
        
        // Budget indicators (fast food, casual)
        if name.contains("fast food") || name.contains("fast-food") || name.contains("drive") ||
           name.contains("taqueria") || name.contains("taco") {
            return .budget
        }
        
        // Moderate indicators (casual dining, cafes)
        if name.contains("cafe") || name.contains("diner") || name.contains("restaurant") {
            return .moderate
        }
        
        // Default to moderate
        return .moderate
    }
    
    private func formatAddress(from placemark: MKPlacemark) -> String {
        var addressComponents: [String] = []
        
        if let streetNumber = placemark.subThoroughfare {
            addressComponents.append(streetNumber)
        }
        
        if let streetName = placemark.thoroughfare {
            addressComponents.append(streetName)
        }
        
        if let city = placemark.locality {
            addressComponents.append(city)
        }
        
        if let state = placemark.administrativeArea {
            addressComponents.append(state)
        }
        
        if let zipCode = placemark.postalCode {
            addressComponents.append(zipCode)
        }
        
        if addressComponents.isEmpty {
            return "Address not available"
        }
        
        return addressComponents.joined(separator: ", ")
    }
}

