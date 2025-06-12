import Foundation
import CoreLocation
import SwiftUI
import MapKit

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
    private let searchService: SearchService
    
    override init() {
        self.searchService = SearchService(locationManager: locationManager)
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationAuthorization()
    }
    
    func search() {
        guard !searchText.isEmpty else { return }
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                await searchService.search(query: searchText)
                self.places = searchService.searchResults
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
                self.places = []
            }
        }
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
