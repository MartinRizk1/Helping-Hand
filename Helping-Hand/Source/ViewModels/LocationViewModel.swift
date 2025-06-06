import Foundation
import CoreLocation
import Combine
import UIKit

class LocationViewModel: ObservableObject {
    @Published var userLocation: CLLocation?
    @Published var locationError: Error?
    @Published var isLocationAccessGranted = false
    
    private let locationManager = CLLocationManager()
    private var locationManagerDelegate: LocationManagerDelegate?
    
    init() {
        setupLocationManager()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupLocationManager() {
        // In test mode, we'll simulate that location access is granted
        if AppDelegate.isTestMode {
            print("TEST: Setting simulated location for San Francisco")
            self.isLocationAccessGranted = true
            self.userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194) // San Francisco
            return
        }
        
        // Real location handling for non-test mode
        locationManagerDelegate = LocationManagerDelegate()
        locationManagerDelegate?.onLocationUpdate = { [weak self] location in
            self?.userLocation = location
        }
        locationManagerDelegate?.onAuthorizationChange = { [weak self] status in
            self?.isLocationAccessGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
        }
        locationManagerDelegate?.onError = { [weak self] error in
            self?.locationError = error
        }
        
        locationManager.delegate = locationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // Update if moved 50 meters
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
}

// Delegate to handle CLLocationManager callbacks
class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    var onError: ((Error) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            onLocationUpdate?(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onError?(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        onAuthorizationChange?(status)
    }
}
