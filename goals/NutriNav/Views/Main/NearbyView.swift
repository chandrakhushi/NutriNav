//
//  NearbyView.swift
//  NutriNav
//
//  Nearby restaurants screen with filters
//

import SwiftUI

struct NearbyView: View {
    @EnvironmentObject var appState: AppState
    @State private var restaurants = MockDataService.shared.getRestaurants()
    @State private var selectedPriceRange: PriceRange?
    @State private var location = "San Francisco, CA"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nearby Food")
                            .font(.system(size: 32, weight: .bold))
                        
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.green)
                            Text(location)
                                .font(.system(size: 16))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Budget filter
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Budget Filter")
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.horizontal, 20)
                                
                                HStack(spacing: 10) {
                                    ForEach([PriceRange.budget, .moderate, .expensive], id: \.self) { priceRange in
                                        Button(action: {
                                            if selectedPriceRange == priceRange {
                                                selectedPriceRange = nil
                                            } else {
                                                selectedPriceRange = priceRange
                                            }
                                        }) {
                                            Text(priceRange.rawValue)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(selectedPriceRange == priceRange ? .white : .green)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(selectedPriceRange == priceRange ? Color.green : Color.green.opacity(0.1))
                                                .cornerRadius(10)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                Button(action: {}) {
                                    Text("Show Map")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 10)
                            
                            // Restaurants section
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text("Restaurants Near You")
                                        .font(.system(size: 20, weight: .bold))
                                    
                                    Spacer()
                                    
                                    Text("\(restaurants.count) places")
                                        .font(.system(size: 14))
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.horizontal, 20)
                                
                                ForEach(filteredRestaurants) { restaurant in
                                    RestaurantCard(restaurant: restaurant)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .padding(.top, 10)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
        }
    }
    
    private var filteredRestaurants: [Restaurant] {
        if let priceRange = selectedPriceRange {
            return restaurants.filter { $0.priceRange == priceRange }
        }
        return restaurants
    }
}

struct RestaurantCard: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // Restaurant image placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(restaurant.name)
                        .font(.system(size: 18, weight: .bold))
                    
                    Text(restaurant.cuisine.joined(separator: ", "))
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            Text(restaurant.isOpen ? "Open" : "Closed")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", restaurant.rating))
                                .font(.system(size: 12))
                        }
                        
                        Text(restaurant.priceRange.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                        
                        Text("• \(String(format: "%.1f", restaurant.distance)) mi")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                            Text("\(restaurant.averageCalories) cal")
                                .font(.system(size: 12))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            Text("\(restaurant.averageProtein)g")
                                .font(.system(size: 12))
                        }
                    }
                }
                
                Spacer()
            }
            .padding(15)
            .background(Color.white)
            .cornerRadius(15)
            
            // Order button
            if let orderLink = restaurant.orderLink {
                Button(action: {
                    // TODO: Open order link (DoorDash/UberEats)
                    AnalyticsService.shared.trackNearbyFoodUsed(
                        restaurantId: restaurant.id.uuidString,
                        restaurantName: restaurant.name,
                        ordered: true
                    )
                }) {
                    HStack {
                        Text("Order Now")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 15)
            }
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

