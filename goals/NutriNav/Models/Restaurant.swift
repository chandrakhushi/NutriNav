//
//  Restaurant.swift
//  NutriNav
//
//  Restaurant model for nearby food
//

import Foundation
import CoreLocation

struct Restaurant: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var cuisine: [String]
    var isOpen: Bool
    var rating: Double
    var priceRange: PriceRange
    var distance: Double // in miles
    var averageCalories: Int
    var averageProtein: Int // in grams
    var imageName: String // For mock data
    var imageURL: String? // Optional image URL (provider-agnostic)
    var address: String
    var phoneNumber: String?
    var orderLink: String? // DoorDash/UberEats link
    var latitude: Double? // For map view
    var longitude: Double? // For map view
    
    // Computed property for location coordinate
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    init(id: UUID = UUID(), name: String, cuisine: [String], isOpen: Bool, rating: Double, priceRange: PriceRange, distance: Double, averageCalories: Int, averageProtein: Int, imageName: String, address: String, phoneNumber: String? = nil, orderLink: String? = nil, imageURL: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.cuisine = cuisine
        self.isOpen = isOpen
        self.rating = rating
        self.priceRange = priceRange
        self.distance = distance
        self.averageCalories = averageCalories
        self.averageProtein = averageProtein
        self.imageName = imageName
        self.address = address
        self.phoneNumber = phoneNumber
        self.orderLink = orderLink
        self.imageURL = imageURL
        self.latitude = latitude
        self.longitude = longitude
    }
}

enum PriceRange: String, Codable {
    case budget = "$"
    case moderate = "$$"
    case expensive = "$$$"
    case veryExpensive = "$$$$"
}

