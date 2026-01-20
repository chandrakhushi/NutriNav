//
//  PlaceSearchService.swift
//  NutriNav
//
//  Protocol for place/restaurant search services
//  Allows multiple providers (MapKit, Yelp, etc.) to be swapped easily
//

import Foundation
import CoreLocation

protocol PlaceSearchService {
    /// Search for nearby restaurants
    /// - Parameters:
    ///   - location: User's current location
    ///   - radius: Search radius in meters
    ///   - limit: Maximum number of results
    ///   - priceFilter: Optional price range filter ($, $$, $$$, $$$$)
    /// - Returns: Array of Restaurant objects
    func searchNearbyRestaurants(
        location: CLLocation,
        radius: Int,
        limit: Int,
        priceFilter: PriceRange?
    ) async throws -> [Restaurant]
    
    /// Check if the service is available/configured
    var isAvailable: Bool { get }
}

