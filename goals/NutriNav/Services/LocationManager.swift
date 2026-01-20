//
//  LocationManager.swift
//  NutriNav
//
//  Location manager for user location tracking
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestAuthorization()
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        // Request authorization if needed
        if authorizationStatus == .notDetermined {
            requestAuthorization()
            // Wait a bit for authorization
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            throw LocationError.notAuthorized
        }
        
        if let location = location {
            return location
        }
        
        // Request location update
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            var observer: NSObjectProtocol?
            
            // Set up a one-time location update
            observer = NotificationCenter.default.addObserver(
                forName: .locationUpdated,
                object: nil,
                queue: .main
            ) { _ in
                if !hasResumed, let location = self.location, let observer = observer {
                    hasResumed = true
                    NotificationCenter.default.removeObserver(observer)
                    continuation.resume(returning: location)
                }
            }
            
            // Also observe errors
            var errorObserver: NSObjectProtocol?
            errorObserver = NotificationCenter.default.addObserver(
                forName: .locationError,
                object: nil,
                queue: .main
            ) { _ in
                if !hasResumed, let errorObserver = errorObserver {
                    hasResumed = true
                    NotificationCenter.default.removeObserver(errorObserver)
                    if let observer = observer {
                        NotificationCenter.default.removeObserver(observer)
                    }
                    continuation.resume(throwing: LocationError.unknown)
                }
            }
            
            // Start updating location
            self.startUpdatingLocation()
            
            // Timeout after 10 seconds
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                if !hasResumed {
                    hasResumed = true
                    if let observer = observer {
                        NotificationCenter.default.removeObserver(observer)
                    }
                    if let errorObserver = errorObserver {
                        NotificationCenter.default.removeObserver(errorObserver)
                    }
                    continuation.resume(throwing: LocationError.timeout)
                }
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        locationError = nil
        NotificationCenter.default.post(name: .locationUpdated, object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        NotificationCenter.default.post(name: .locationError, object: nil)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            locationError = LocationError.notAuthorized
        default:
            break
        }
    }
}

extension Notification.Name {
    static let locationUpdated = Notification.Name("locationUpdated")
    static let locationError = Notification.Name("locationError")
}

enum LocationError: LocalizedError {
    case notAuthorized
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Location access is required to find nearby restaurants."
        case .timeout:
            return "Location request timed out. Please try again."
        case .unknown:
            return "An unknown location error occurred."
        }
    }
}

