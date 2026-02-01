//
//  NearbyView.swift
//  NutriNav
//
//  Nearby restaurants screen with Yelp API and MapKit integration
//

import SwiftUI
import MapKit
import Combine

struct NearbyView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = NearbyFoodViewModel()
    @State private var searchText: String = ""
    @State private var showLocationSearch = false
    
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
                
                // Search Bar
                searchBar
                    .padding(.horizontal, Spacing.md)
                
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
            
            // Tappable location button
            Button(action: {
                HapticFeedback.selection()
                showLocationSearch = true
            }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.primaryAccent)
                    
                    Text(viewModel.locationName)
                        .font(.input)
                        .foregroundColor(.textPrimary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
        .sheet(isPresented: $showLocationSearch) {
            LocationSearchView(viewModel: viewModel)
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
            
            TextField("Search restaurants...", text: $searchText)
                .font(.input)
                .foregroundColor(.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    viewModel.searchQuery = searchText
                    Task {
                        await viewModel.loadRestaurants()
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    viewModel.searchQuery = ""
                    Task {
                        await viewModel.loadRestaurants()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.inputBackground)
        .cornerRadius(Radius.md)
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
                            openOrderLink(for: restaurant)
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
    
    // MARK: - Order Link Handler
    
    private func openOrderLink(for restaurant: Restaurant) {
        // Try to open the restaurant's specific order link first
        if let orderLink = restaurant.orderLink,
           let url = URL(string: orderLink) {
            UIApplication.shared.open(url)
            return
        }
        
        // Fallback: Search for the restaurant on popular delivery platforms
        let encodedName = restaurant.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedAddress = restaurant.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Try DoorDash first (most popular)
        let doordashURL = "https://www.doordash.com/search/\(encodedName)/"
        if let url = URL(string: doordashURL) {
            UIApplication.shared.open(url)
            return
        }
        
        // Fallback to Google Maps for directions/info
        let mapsURL = "https://maps.google.com/?q=\(encodedName)+\(encodedAddress)"
        if let url = URL(string: mapsURL) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Restaurant Map View

struct RestaurantMapView: View {
    let restaurants: [Restaurant]
    let userLocation: CLLocation?
    
    @State private var region: MKCoordinateRegion
    @State private var selectedRestaurant: Restaurant? = nil
    
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
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: restaurants) { restaurant in
                MapAnnotation(coordinate: restaurant.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)) {
                    RestaurantMapPin(restaurant: restaurant)
                        .onTapGesture {
                            HapticFeedback.selection()
                            selectedRestaurant = restaurant
                        }
                }
            }
            .mapControls {
                MapCompass()
                MapUserLocationButton()
            }
            
            // Zoom controls overlay
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Zoom In
                        Button(action: {
                            HapticFeedback.selection()
                            withAnimation {
                                region.span.latitudeDelta /= 2
                                region.span.longitudeDelta /= 2
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.textPrimary)
                                .frame(width: 44, height: 44)
                        }
                        
                        Divider()
                        
                        // Zoom Out
                        Button(action: {
                            HapticFeedback.selection()
                            withAnimation {
                                region.span.latitudeDelta = min(region.span.latitudeDelta * 2, 1.0)
                                region.span.longitudeDelta = min(region.span.longitudeDelta * 2, 1.0)
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.textPrimary)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.2), radius: 4)
                    .padding(.trailing, Spacing.md)
                    .padding(.bottom, 120) // Above tab bar
                }
            }
            
            // Selected restaurant card
            if let restaurant = selectedRestaurant {
                VStack {
                    Spacer()
                    
                    selectedRestaurantCard(restaurant: restaurant)
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom))
                }
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
    
    private func selectedRestaurantCard(restaurant: Restaurant) -> some View {
        HStack(spacing: Spacing.md) {
            // Restaurant image
            AsyncImage(url: URL(string: restaurant.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(Color(hex: "E0E0E0"))
                        .overlay(
                            Image(systemName: "fork.knife")
                                .foregroundColor(.textTertiary)
                        )
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(restaurant.name)
                    .font(.h3)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: Spacing.sm) {
                    Text(restaurant.priceRange.rawValue)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    
                    Text("•")
                        .foregroundColor(.textTertiary)
                    
                    Text("\(String(format: "%.1f", restaurant.distance)) mi")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    
                    if restaurant.isOpen {
                        Text("Open")
                            .font(.bodySmall)
                            .foregroundColor(.primaryAccent)
                    }
                }
            }
            
            Spacer()
            
            // Close button
            Button(action: {
                withAnimation {
                    selectedRestaurant = nil
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(Radius.lg)
        .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
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

// MARK: - Location Search View
struct LocationSearchView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: NearbyFoodViewModel
    
    @State private var searchText: String = ""
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @StateObject private var searchCompleter = LocationSearchCompleter()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textSecondary)
                        
                        TextField("Search city or address...", text: $searchText)
                            .font(.input)
                            .foregroundColor(.textPrimary)
                            .autocorrectionDisabled()
                            .onChange(of: searchText) { _, newValue in
                                searchCompleter.search(query: newValue)
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchCompleter.results = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.inputBackground)
                    .cornerRadius(Radius.md)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    
                    // Current Location Button
                    Button(action: {
                        HapticFeedback.selection()
                        viewModel.resetToCurrentLocation()
                        dismiss()
                    }) {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primaryAccent)
                                .frame(width: 40, height: 40)
                                .background(Color.primaryAccent.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Use Current Location")
                                    .font(.input)
                                    .foregroundColor(.textPrimary)
                                
                                if viewModel.isUsingCustomLocation {
                                    Text("Switch back to GPS location")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                } else {
                                    Text("Currently active")
                                        .font(.bodySmall)
                                        .foregroundColor(.primaryAccent)
                                }
                            }
                            
                            Spacer()
                            
                            if !viewModel.isUsingCustomLocation {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.primaryAccent)
                            }
                        }
                        .padding(Spacing.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                        .padding(.horizontal, Spacing.md)
                    
                    // Search Results
                    if searchCompleter.results.isEmpty && !searchText.isEmpty {
                        VStack(spacing: Spacing.md) {
                            Spacer()
                            Text("No locations found")
                                .font(.input)
                                .foregroundColor(.textSecondary)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(searchCompleter.results, id: \.self) { result in
                                    locationResultRow(result: result)
                                    
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Change Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
    
    private func locationResultRow(result: MKLocalSearchCompletion) -> some View {
        Button(action: {
            selectLocation(result)
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.textSecondary)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.input)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    if !result.subtitle.isEmpty {
                        Text(result.subtitle)
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.textTertiary)
            }
            .padding(Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func selectLocation(_ completion: MKLocalSearchCompletion) {
        // Convert completion to coordinate
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        Task {
            do {
                let response = try await search.start()
                if let mapItem = response.mapItems.first {
                    let coordinate = mapItem.placemark.coordinate
                    let name = completion.title
                    
                    await MainActor.run {
                        viewModel.setCustomLocation(coordinate: coordinate, name: name)
                        HapticFeedback.success()
                        dismiss()
                    }
                }
            } catch {
                print("Location search error: \(error)")
            }
        }
    }
}

// MARK: - Location Search Completer
final class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    var results: [MKLocalSearchCompletion] = [] {
        willSet { objectWillChange.send() }
    }
    private let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }
    
    func search(query: String) {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.results = []
            }
            return
        }
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error)")
    }
}
