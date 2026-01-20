//
//  NearbyView.swift
//  NutriNav
//
//  Nearby restaurants screen with Yelp API and MapKit integration
//

import SwiftUI
import MapKit

struct NearbyView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = NearbyFoodViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                if viewModel.viewMode == .list {
                    listView
                } else {
                    mapView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    viewModeToggle
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadRestaurants()
                }
            }
        }
    }
    
    // MARK: - List View
    
    private var listView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header
                headerSection
                    .padding(.top, Spacing.xxl)
                
                // Budget Filter
                budgetFilterSection
                    .padding(.horizontal, Spacing.md)
                
                // Content
                if viewModel.isLoading {
                    loadingView
                        .padding(.top, Spacing.xl)
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                        .padding(.top, Spacing.xl)
                } else if viewModel.restaurants.isEmpty {
                    emptyView
                        .padding(.top, Spacing.xl)
                } else {
                    restaurantsSection
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xl)
                }
            }
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        ZStack(alignment: .top) {
            RestaurantMapView(restaurants: viewModel.restaurants, userLocation: viewModel.userLocation)
                .ignoresSafeArea()
            
            // Map header overlay
            VStack {
                headerSection
                    .padding(.top, Spacing.xxl)
                
                budgetFilterSection
                    .padding(.horizontal, Spacing.md)
                
                Spacer()
            }
            .background(
                LinearGradient(
                    colors: [Color.background.opacity(0.95), Color.background.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    // MARK: - View Mode Toggle
    
    private var viewModeToggle: some View {
        HStack(spacing: 0) {
            Button(action: {
                viewModel.viewMode = .list
            }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(viewModel.viewMode == .list ? .white : .primaryAccent)
                    .frame(width: 36, height: 36)
                    .background(viewModel.viewMode == .list ? Color.primaryAccent : Color.clear)
                    .cornerRadius(Radius.sm, corners: [.topLeft, .bottomLeft])
            }
            
            Button(action: {
                viewModel.viewMode = .map
            }) {
                Image(systemName: "map")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(viewModel.viewMode == .map ? .white : .primaryAccent)
                    .frame(width: 36, height: 36)
                    .background(viewModel.viewMode == .map ? Color.primaryAccent : Color.clear)
                    .cornerRadius(Radius.sm, corners: [.topRight, .bottomRight])
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sm)
                .stroke(Color.primaryAccent, lineWidth: 1)
        )
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Nearby Food")
                .font(.h1)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: Spacing.xs) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.primaryAccent)
                
                Text(viewModel.locationName)
                    .font(.input)
                    .foregroundColor(.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }
    
    // MARK: - Budget Filter
    
    private var budgetFilterSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Budget Filter")
                .font(.h3)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: Spacing.md) {
                ForEach([PriceRange.budget, .moderate, .expensive], id: \.self) { priceRange in
                    Button(action: {
                        viewModel.setPriceFilter(priceRange)
                    }) {
                        Text(priceRange.rawValue)
                            .font(.label)
                            .foregroundColor(viewModel.selectedPriceRange == priceRange ? .white : .primaryAccent)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                viewModel.selectedPriceRange == priceRange
                                    ? Color.primaryAccent
                                    : Color.white
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .stroke(Color.primaryAccent, lineWidth: 1)
                            )
                            .cornerRadius(Radius.md)
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
                    text: "\(viewModel.restaurants.count) places",
                    color: .primaryAccent
                )
            }
            
            ForEach(viewModel.restaurants) { restaurant in
                restaurantCard(restaurant: restaurant)
            }
        }
    }
    
    // MARK: - Restaurant Card
    
    private func restaurantCard(restaurant: Restaurant) -> some View {
        PrimaryCard {
            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    // Restaurant Image
                    AsyncImage(url: URL(string: restaurant.imageURL ?? "")) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: Radius.md)
                                .fill(Color(hex: "E0E0E0"))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    ProgressView()
                                        .tint(.primaryAccent)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        case .failure:
                            RoundedRectangle(cornerRadius: Radius.md)
                                .fill(Color(hex: "E0E0E0"))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 24))
                                        .foregroundColor(.textTertiary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(restaurant.name)
                                .font(.h3)
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                            
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
                            .cornerRadius(Radius.sm)
                        }
                        
                        Text(restaurant.cuisine.joined(separator: ", "))
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                        
                        HStack(spacing: Spacing.sm) {
                            // Only show rating if available (MapKit doesn't provide ratings)
                            if restaurant.rating > 0 {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.warning)
                                    Text(String(format: "%.1f", restaurant.rating))
                                        .font(.bodySmall)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                            
                            Text(restaurant.priceRange.rawValue)
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                            
                            if restaurant.rating > 0 {
                                Text("•")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Text("\(String(format: "%.1f", restaurant.distance)) mi")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                
                // Nutrition Info (Estimated)
                HStack(spacing: Spacing.md) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.calorieColor)
                        Text("~\(restaurant.averageCalories) cal")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 14))
                            .foregroundColor(.proteinColor)
                        Text("~\(restaurant.averageProtein)g protein")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("Estimated")
                        .font(.labelSmall)
                        .foregroundColor(.textTertiary)
                        .italic()
                }
                
                // Order Now Button
                if restaurant.isOpen {
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
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.primaryAccent)
            
            Text("Finding nearby restaurants...")
                .font(.body)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.error)
            
            Text("Error")
                .font(.h2)
                .foregroundColor(.textPrimary)
            
            Text(message)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            
            PrimaryButton(
                title: "Try Again",
                action: {
                    Task {
                        await viewModel.loadRestaurants()
                    }
                },
                icon: "arrow.clockwise"
            )
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.md)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)
            
            Text("No restaurants found")
                .font(.h2)
                .foregroundColor(.textPrimary)
            
            Text("Try adjusting your filters or location")
                .font(.body)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}

// MARK: - Restaurant Map View

struct RestaurantMapView: View {
    let restaurants: [Restaurant]
    let userLocation: CLLocation?
    
    @State private var region: MKCoordinateRegion
    
    init(restaurants: [Restaurant], userLocation: CLLocation?) {
        self.restaurants = restaurants
        self.userLocation = userLocation
        
        // Initialize region based on user location or first restaurant
        if let userLocation = userLocation {
            _region = State(initialValue: MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        } else if let firstRestaurant = restaurants.first,
                  let coordinate = firstRestaurant.coordinate {
            _region = State(initialValue: MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        } else {
            // Default to San Francisco
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: restaurants) { restaurant in
            MapAnnotation(coordinate: restaurant.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)) {
                RestaurantMapPin(restaurant: restaurant)
            }
        }
        .onAppear {
            updateRegion()
        }
        .onChange(of: restaurants) { _ in
            updateRegion()
        }
        .onChange(of: userLocation) { _ in
            updateRegion()
        }
    }
    
    private func updateRegion() {
        guard !restaurants.isEmpty else { return }
        
        // Calculate region to show all restaurants and user location
        var coordinates: [CLLocationCoordinate2D] = []
        
        if let userLocation = userLocation {
            coordinates.append(userLocation.coordinate)
        }
        
        for restaurant in restaurants {
            if let coordinate = restaurant.coordinate {
                coordinates.append(coordinate)
            }
        }
        
        guard !coordinates.isEmpty else { return }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        
        region = MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Restaurant Map Pin

struct RestaurantMapPin: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(restaurant.isOpen ? .primaryAccent : .textTertiary)
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                )
                .shadow(radius: 4)
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
