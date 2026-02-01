//
//  NearbyFoodViewModel.swift
//  NutriNav
//
//  ViewModel for NearbyFoodView
//

import Foundation
import CoreLocation
import Combine

@MainActor
class NearbyFoodViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedPriceRange: PriceRange?
    @Published var viewMode: ViewMode = .list
    @Published var userLocation: CLLocation?
    @Published var locationName: String = "Loading location..."
    @Published var searchQuery: String = ""
    @Published var isUsingCustomLocation: Bool = false
    
    enum ViewMode {
        case list
        case map
    }
    
    // Use Apple MapKit as the default (free) provider
    // Yelp can be used optionally if API key is set (see getPlaceService())
    private var placeService: PlaceSearchService {
        // TODO: Optionally use Yelp if API key is available
        // if YelpService.shared.isAvailable {
        //     return YelpService.shared
        // }
        return AppleMapKitPlaceService.shared
    }
    
    private let locationManager = LocationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupLocationObserver()
    }
    
    private func setupLocationObserver() {
        // Observe location updates
        locationManager.$location
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.userLocation = location
                if let location = location {
                    self?.reverseGeocodeLocation(location)
                }
            }
            .store(in: &cancellables)
        
        // Observe authorization status
        locationManager.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    self.locationManager.startUpdatingLocation()
                }
            }
            .store(in: &cancellables)
        
        // Request authorization on init if needed
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestAuthorization()
        } else if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func loadRestaurants() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Request location if needed
        if userLocation == nil {
            do {
                userLocation = try await locationManager.getCurrentLocation()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
                return
            }
        }
        
        guard let location = userLocation else {
            errorMessage = "Unable to get your location. Please enable location services."
            isLoading = false
            return
        }
        
        // Check if place service is available
        guard placeService.isAvailable else {
            errorMessage = "Restaurant search service is not available."
            isLoading = false
            return
        }
        
        do {
            var results = try await placeService.searchNearbyRestaurants(
                location: location,
                radius: 5000, // 5km
                limit: 20,
                priceFilter: selectedPriceRange,
                query: searchQuery.isEmpty ? nil : searchQuery
            )
            
            // Filter by search query if the API doesn't support it natively
            if !searchQuery.isEmpty {
                let lowercaseQuery = searchQuery.lowercased()
                results = results.filter { restaurant in
                    restaurant.name.lowercased().contains(lowercaseQuery) ||
                    restaurant.cuisine.joined(separator: " ").lowercased().contains(lowercaseQuery)
                }
            }
            
            restaurants = results
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    /// Set a custom location by address/city name
    func setCustomLocation(coordinate: CLLocationCoordinate2D, name: String) {
        userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        locationName = name
        isUsingCustomLocation = true
        Task {
            await loadRestaurants()
        }
    }
    
    /// Reset to current device location
    func resetToCurrentLocation() {
        isUsingCustomLocation = false
        locationManager.startUpdatingLocation()
        if let location = locationManager.location {
            userLocation = location
            reverseGeocodeLocation(location)
        }
        Task {
            await loadRestaurants()
        }
    }
    
    func toggleViewMode() {
        viewMode = viewMode == .list ? .map : .list
        HapticFeedback.selection()
    }
    
    func setPriceFilter(_ priceRange: PriceRange?) {
        selectedPriceRange = selectedPriceRange == priceRange ? nil : priceRange
        HapticFeedback.selection()
        Task {
            await loadRestaurants()
        }
    }
    
    private func reverseGeocodeLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let placemark = placemarks?.first {
                let city = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                if !city.isEmpty && !state.isEmpty {
                    self.locationName = "\(city), \(state)"
                } else if !city.isEmpty {
                    self.locationName = city
                } else {
                    self.locationName = "Current Location"
                }
            } else {
                self.locationName = "Current Location"
            }
        }
    }
}

