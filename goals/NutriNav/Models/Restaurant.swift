//
//  Restaurant.swift
//  NutriNav
//
//  Restaurant model for nearby food
//

import Foundation

struct Restaurant: Identifiable, Codable {
    var id: UUID
    var name: String
    var cuisine: [String]
    var isOpen: Bool
    var rating: Double
    var priceRange: PriceRange
    var distance: Double // in miles
    var averageCalories: Int
    var averageProtein: Int // in grams
    var imageName: String
    var address: String
    var phoneNumber: String?
    var orderLink: String? // DoorDash/UberEats link
    
    init(id: UUID = UUID(), name: String, cuisine: [String], isOpen: Bool, rating: Double, priceRange: PriceRange, distance: Double, averageCalories: Int, averageProtein: Int, imageName: String, address: String, phoneNumber: String? = nil, orderLink: String? = nil) {
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
    }
}

enum PriceRange: String, Codable {
    case budget = "$"
    case moderate = "$$"
    case expensive = "$$$"
    case veryExpensive = "$$$$"
}

