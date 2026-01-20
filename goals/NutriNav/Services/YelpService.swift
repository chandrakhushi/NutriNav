//
//  YelpService.swift
//  NutriNav
//
//  OPTIONAL Yelp Fusion API service for nearby restaurants
//  NOTE: This is an optional provider. The app works without it using Apple MapKit.
//  To enable: Set API key via YelpService.shared.setAPIKey("your-key")
//

import Foundation
import CoreLocation

class YelpService: PlaceSearchService {
    static let shared = YelpService()
    
    private let baseURL = "https://api.yelp.com/v3"
    private let session = URLSession.shared
    
    // Yelp API Key - should be set via setAPIKey() method
    private var apiKey: String? {
        didSet {
            if let key = apiKey {
                UserDefaults.standard.set(key, forKey: "YELP_API_KEY")
            }
        }
    }
    
    var isAvailable: Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    private init() {
        // Try to load from UserDefaults
        if let savedKey = UserDefaults.standard.string(forKey: "YELP_API_KEY"), !savedKey.isEmpty {
            apiKey = savedKey
        }
    }
    
    // MARK: - API Key Management
    
    func setAPIKey(_ key: String) {
        apiKey = key
    }
    
    func hasAPIKey() -> Bool {
        return isAvailable
    }
    
    // MARK: - PlaceSearchService Implementation
    
    func searchNearbyRestaurants(
        location: CLLocation,
        radius: Int,
        limit: Int,
        priceFilter: PriceRange?
    ) async throws -> [Restaurant] {
        guard isAvailable else {
            throw YelpServiceError.apiKeyRequired
        }
        
        // Convert PriceRange to Yelp API format
        let price: String?
        if let priceFilter = priceFilter {
            switch priceFilter {
            case .budget: price = "1"
            case .moderate: price = "2"
            case .expensive: price = "3"
            case .veryExpensive: price = "4"
            }
        } else {
            price = nil
        }
        
        // Build URL
        var components = URLComponents(string: "\(baseURL)/businesses/search")!
        var queryItems = [
            URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "radius", value: String(radius)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "categories", value: "restaurants,food") // Restaurants and food places
        ]
        
        if let price = price {
            queryItems.append(URLQueryItem(name: "price", value: price))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw YelpServiceError.invalidURL
        }
        
        // Create request with API key
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        // Make request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YelpServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw YelpServiceError.invalidAPIKey
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("Yelp API Error Response: \(errorString)")
            }
            throw YelpServiceError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let searchResponse = try decoder.decode(YelpSearchResponse.self, from: data)
            
            // Convert Yelp businesses to Restaurant models
            let restaurants = searchResponse.businesses.compactMap { business in
                convertYelpBusinessToRestaurant(business, userLocation: location)
            }
            
            return restaurants
        } catch {
            print("Yelp API Decoding error: \(error)")
            throw YelpServiceError.decodingError
        }
    }
    
    // MARK: - Convert Yelp Business to Restaurant
    
    private func convertYelpBusinessToRestaurant(_ business: YelpBusiness, userLocation: CLLocation) -> Restaurant? {
        // Parse price range
        let priceRange: PriceRange
        if let price = business.price {
            switch price.count {
            case 1: priceRange = .budget
            case 2: priceRange = .moderate
            case 3: priceRange = .expensive
            case 4: priceRange = .veryExpensive
            default: priceRange = .moderate
            }
        } else {
            priceRange = .moderate // Default
        }
        
        // Extract cuisine categories
        let cuisineTypes = business.categories?.map { $0.title } ?? []
        
        // Calculate distance
        let restaurantLocation = CLLocation(
            latitude: business.coordinates.latitude,
            longitude: business.coordinates.longitude
        )
        let distanceInMeters = userLocation.distance(from: restaurantLocation)
        let distanceInMiles = distanceInMeters / 1609.34 // Convert to miles
        
        // Estimate nutrition based on cuisine
        let nutrition = NutritionEstimationService.shared.estimateNutrition(
            for: cuisineTypes,
            priceRange: priceRange
        )
        
        // Determine if open (check if hours are available and current time is within)
        let isOpen = business.isClosed == false
        
        // Build address
        let addressComponents = [
            business.location.address1,
            business.location.address2,
            business.location.city,
            business.location.state,
            business.location.zipCode
        ].compactMap { $0 }
        let address = addressComponents.joined(separator: ", ")
        
        return Restaurant(
            id: UUID(),
            name: business.name,
            cuisine: cuisineTypes,
            isOpen: isOpen,
            rating: business.rating,
            priceRange: priceRange,
            distance: distanceInMiles,
            averageCalories: nutrition.calories,
            averageProtein: nutrition.protein,
            imageName: "", // Not used for Yelp data
            address: address.isEmpty ? "Address not available" : address,
            phoneNumber: business.phone,
            orderLink: nil, // Not provided by Yelp API
            imageURL: business.imageUrl,
            latitude: business.coordinates.latitude,
            longitude: business.coordinates.longitude
        )
    }
}

// MARK: - Yelp API Response Models

private struct YelpSearchResponse: Codable {
    let businesses: [YelpBusiness]
    let total: Int?
    let region: YelpRegion?
}

private struct YelpBusiness: Codable {
    let id: String
    let name: String
    let imageUrl: String?
    let isClosed: Bool
    let url: String?
    let reviewCount: Int
    let categories: [YelpCategory]?
    let rating: Double
    let coordinates: YelpCoordinates
    let transactions: [String]?
    let price: String? // "$", "$$", "$$$", "$$$$"
    let location: YelpLocation
    let phone: String?
    let displayPhone: String?
    let distance: Double? // in meters
}

private struct YelpCategory: Codable {
    let alias: String
    let title: String
}

private struct YelpCoordinates: Codable {
    let latitude: Double
    let longitude: Double
}

private struct YelpLocation: Codable {
    let address1: String?
    let address2: String?
    let address3: String?
    let city: String?
    let zipCode: String?
    let country: String?
    let state: String?
    let displayAddress: [String]?
}

private struct YelpRegion: Codable {
    let center: YelpCoordinates?
}

// MARK: - Errors

enum YelpServiceError: LocalizedError {
    case apiKeyRequired
    case invalidAPIKey
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .apiKeyRequired:
            return "Yelp API key is required. Get a free key at https://www.yelp.com/developers"
        case .invalidAPIKey:
            return "Invalid Yelp API key. Please check your API key."
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from Yelp API"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError:
            return "Failed to decode Yelp API response"
        }
    }
}

