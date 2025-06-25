import Foundation
import CoreLocation
import SwiftUI
import MapKit
import Combine

@MainActor
class MainViewModel: NSObject, ObservableObject {
    @Published var searchText = ""
    @Published var places: [Place] = []
    @Published var selectedPlace: Place?
    @Published var userLocation: CLLocation?
    @Published var isLocationAuthorized = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let locationManager = CLLocationManager()
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationAuthorization()
        
        // Subscribe to location results
        locationService.$lastLocationResults
            .sink { [weak self] results in
                if let results = results {
                    self?.places = results.map { locationResult in
                        Place(
                            name: locationResult.name,
                            coordinate: locationResult.coordinate,
                            category: PlaceCategory.from(locationResult.category),
                            distance: locationResult.distance,
                            address: locationResult.address,
                            phoneNumber: locationResult.phoneNumber,
                            rating: locationResult.rating,
                            isOpen: nil
                        )
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func search() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        locationService.searchNearbyPlaces(for: searchText, query: searchText)
        isLoading = false
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationAuthorized = true
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            isLocationAuthorized = false
            errorMessage = "Location access denied. Please enable in Settings."
        case .notDetermined:
            isLocationAuthorized = false
        @unknown default:
            isLocationAuthorized = false
        }
    }
}

extension MainViewModel: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            checkLocationAuthorization()
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            userLocation = location
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
        }
    }
}
