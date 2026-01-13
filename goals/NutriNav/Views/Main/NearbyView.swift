//
//  NearbyView.swift
//  NutriNav
//
//  Nearby restaurants screen - using DesignSystem
//

import SwiftUI

struct NearbyView: View {
    @EnvironmentObject var appState: AppState
    @State private var restaurants = MockDataService.shared.getRestaurants()
    @State private var selectedPriceRange: PriceRange?
    @State private var location = "San Francisco, CA"
    @State private var showMap = false
    
    var filteredRestaurants: [Restaurant] {
        if let priceRange = selectedPriceRange {
            return restaurants.filter { $0.priceRange == priceRange }
        }
        return restaurants
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea() // Design System: background = #ffffff
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        headerSection
                            .padding(.top, Spacing.xxl)
                        
                        // Budget Filter
                        budgetFilterSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Show Map Button - Disabled for now (placeholder)
                        SecondaryButton(
                            title: "Show Map",
                            action: {
                                showMap = true
                            },
                            icon: "map"
                        )
                        .padding(.horizontal, Spacing.md)
                        .disabled(true) // Disabled until map integration
                        
                        // Restaurants Section
                        restaurantsSection
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .sheet(isPresented: $showMap) {
                MapViewPlaceholder()
            }
        }
    }
    
    // MARK: - Header (Design System: h1=24pt medium, input=16pt regular)
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Nearby Food")
                .font(.h1) // 24pt, medium
                .foregroundColor(.textPrimary)
            
            HStack(spacing: Spacing.xs) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.primaryAccent)
                
                Text(location)
                    .font(.input) // 16pt, regular
                    .foregroundColor(.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }
    
    // MARK: - Budget Filter (Design System: h3=18pt medium, label=16pt medium, button padding=12, cornerRadius=md=8)
    private var budgetFilterSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Budget Filter")
                .font(.h3) // 18pt, medium
                .foregroundColor(.textPrimary)
            
            HStack(spacing: Spacing.md) {
                ForEach([PriceRange.budget, .moderate, .expensive], id: \.self) { priceRange in
                    Button(action: {
                        HapticFeedback.selection()
                        if selectedPriceRange == priceRange {
                            selectedPriceRange = nil
                        } else {
                            selectedPriceRange = priceRange
                        }
                    }) {
                        Text(priceRange.rawValue)
                            .font(.label) // 16pt, medium
                            .foregroundColor(selectedPriceRange == priceRange ? .white : .primaryAccent)
                            .frame(maxWidth: .infinity)
                            .padding(12) // Button.padding = 12
                            .background(
                                selectedPriceRange == priceRange
                                    ? Color.primaryAccent
                                    : Color.white
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md) // Button cornerRadius = 8
                                    .stroke(Color.primaryAccent, lineWidth: 1)
                            )
                            .cornerRadius(Radius.md) // Button cornerRadius = 8
                    }
                }
            }
        }
    }
    
    // MARK: - Restaurants Section
    
    private var restaurantsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                SectionHeader(title: "Restaurants Near You")
                
                Spacer()
                
                BadgeView(
                    text: "\(filteredRestaurants.count) places",
                    color: .primaryAccent
                )
            }
            
            ForEach(filteredRestaurants) { restaurant in
                restaurantCard(restaurant: restaurant)
            }
        }
    }
    
    // MARK: - Restaurant Card (Design System: h3=18pt medium, card padding=16, cornerRadius=lg=10)
    private func restaurantCard(restaurant: Restaurant) -> some View {
        PrimaryCard { // Card.padding=16, Card.cornerRadius=lg=10
            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    // Image placeholder
                    RoundedRectangle(cornerRadius: Radius.md) // Button cornerRadius = 8
                        .fill(Color(hex: "E0E0E0"))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.textTertiary)
                        )
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(restaurant.name)
                                .font(.h3) // 18pt, medium
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                    .foregroundColor(restaurant.isOpen ? .success : .error)
                                Text(restaurant.isOpen ? "Open" : "Closed")
                                    .font(.labelSmall)
                                    .foregroundColor(restaurant.isOpen ? .success : .error)
                            }
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(restaurant.isOpen ? Color.success.opacity(0.1) : Color.error.opacity(0.1))
                            .cornerRadius(Radius.sm) // Badge cornerRadius = 6
                        }
                        
                        Text(restaurant.cuisine.joined(separator: ", "))
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                        
                        HStack(spacing: Spacing.sm) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.warning)
                                Text(String(format: "%.1f", restaurant.rating))
                                    .font(.bodySmall)
                                    .foregroundColor(.textPrimary)
                            }
                            
                            Text(restaurant.priceRange.rawValue)
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                            
                            Text("• \(String(format: "%.1f", restaurant.distance)) mi")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                
                // Nutrition Info
                HStack(spacing: Spacing.md) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.calorieColor)
                        Text("\(restaurant.averageCalories) cal")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 14))
                            .foregroundColor(.proteinColor)
                        Text("\(restaurant.averageProtein)g")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // Order Button (only if open and has order link)
                if restaurant.isOpen, let _ = restaurant.orderLink {
                    PrimaryButton(
                        title: "Order Now",
                        action: {
                            AnalyticsService.shared.trackNearbyFoodUsed(
                                restaurantId: restaurant.id.uuidString,
                                restaurantName: restaurant.name,
                                ordered: true
                            )
                            // TODO: Open order link (DoorDash/UberEats)
                        },
                        icon: "arrow.up.right.square"
                    )
                }
            }
        }
    }
}

// MARK: - Map View Placeholder

// MARK: - Map View Placeholder (Design System: h1=24pt medium, input=16pt regular)
struct MapViewPlaceholder: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                VStack(spacing: Spacing.xl) {
                    Image(systemName: "map")
                        .font(.system(size: 60))
                        .foregroundColor(.primaryAccent)
                    
                    Text("Map View")
                        .font(.h1) // 24pt, medium
                        .foregroundColor(.textPrimary)
                    
                    Text("Map integration coming soon")
                        .font(.input) // 16pt, regular
                        .foregroundColor(.textSecondary)
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticFeedback.selection()
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
}
