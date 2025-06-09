import Foundation
import CoreLocation
import Combine
import MapKit

class LocationService: NSObject, ObservableObject {
    @Published var lastLocationResults: [LocationResult]? = nil
    @Published var currentLocation: CLLocation? = nil
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManagerDelegate = LocationManagerDelegate()
        locationManagerDelegate?.onLocationUpdate = { [weak self] location in
            DispatchQueue.main.async {
                self?.currentLocation = location
                print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                print("📍 Accuracy: \(location.horizontalAccuracy)m, Speed: \(location.speed >= 0 ? "\(location.speed)m/s" : "N/A")")
            }
        }
        locationManagerDelegate?.onAuthorizationChange = { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                print("🔐 Location authorization changed: \(status.rawValue)")
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    self?.startUpdatingLocation()
                }
            }
        }
        locationManagerDelegate?.onError = { [weak self] error in
            print("❌ Location error: \(error.localizedDescription)")
        }
        
        locationManager.delegate = locationManagerDelegate
        
        // Configure for highest accuracy real-time location tracking
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Update every 5 meters for precise real-time tracking
        
        // Request precise location for iOS 14+
        if #available(iOS 14.0, *) {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            
            // Request temporary precise location access if reduced accuracy
            if locationManager.accuracyAuthorization == .reducedAccuracy {
                locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "HelpingHandLocationAccess")
            }
        }
        
        // Configure activity type for general location tracking
        locationManager.activityType = .other
        
        // Disable background location updates (for now)
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = false
        }
        
        // Enable automatic pausing when location data is not needed
        locationManager.pausesLocationUpdatesAutomatically = true
    }
     func requestLocationPermission() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("❌ Location services not enabled")
            return
        }
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("⚠️ Location access denied or restricted")
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        @unknown default:
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func startUpdatingLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("❌ Location services disabled")
            return
        }
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("⚠️ Location not authorized")
            return
        }
        
        print("🚀 Starting real-time location updates...")
        print("📍 Configured for \(locationManager.desiredAccuracy)m accuracy")
        print("📍 Updates every \(locationManager.distanceFilter)m of movement")
        
        // Request a one-time location first for immediate results
        locationManager.requestLocation()
        
        // Start continuous real-time updates
        locationManager.startUpdatingLocation()
        
        // Configuration info for debugging
        #if targetEnvironment(simulator)
        print("📱 Running in iOS Simulator")
        print("💡 For testing real locations:")
        print("   • Use Device > Location in Simulator menu")
        print("   • Select a city or 'Custom Location'")
        print("   • Or use a GPX file for route simulation")
        #else
        print("📱 Running on physical device - using real GPS")
        #endif
    }
    
    private var locationManagerDelegate: LocationManagerDelegate?
    
    func searchNearbyPlaces(for userQuery: String, query: String?) {
        guard let query = query else {
            print("🔍 Search query is missing")
            return
        }
        guard let location = currentLocation else {
            print("📍 Location is not available for search")
            return
        }
        
        print("🔍 Searching for: '\(query)' near \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 5000, // Increased to 5km radius for better results
            longitudinalMeters: 5000
        )
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let response = response, error == nil else {
                print("❌ Search error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            print("✅ Found \(response.mapItems.count) results")
            
            let results = response.mapItems.map { item -> LocationResult in
                let distance = item.placemark.location?.distance(from: location)
                let category = item.pointOfInterestCategory?.rawValue ?? "Place"
                return LocationResult(
                    name: item.name ?? "Unknown Place",
                    address: self?.formatAddress(from: item.placemark) ?? "",
                    coordinate: item.placemark.coordinate,
                    category: category,
                    phoneNumber: item.phoneNumber,
                    website: item.url,
                    rating: nil, // MapKit doesn't provide ratings
                    distance: distance
                )
            }
            .sorted { (first, second) in
                // Sort by distance (closest first)
                guard let firstDistance = first.distance,
                      let secondDistance = second.distance else {
                    return false
                }
                return firstDistance < secondDistance
            }
            
            DispatchQueue.main.async {
                self?.lastLocationResults = results
            }
        }
    }
    
    private func formatAddress(from placemark: MKPlacemark) -> String {
        let components = [
            placemark.subThoroughfare,  // street number
            placemark.thoroughfare,      // street name
            placemark.locality,          // city
            placemark.administrativeArea, // state
            placemark.postalCode         // zip code
        ].compactMap { $0 }
        
        return components.joined(separator: " ")
    }
    
    func refreshCurrentLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("❌ Location services disabled")
            return
        }
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("⚠️ Location not authorized - requesting permission")
            requestLocationPermission()
            return
        }
        
        print("🔄 Refreshing current location for real-time data...")
        
        // Stop current updates to force fresh data
        locationManager.stopUpdatingLocation()
        
        // Wait a moment for the location manager to reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Request immediate fresh location
            self.locationManager.requestLocation()
            
            // Restart continuous updates for real-time tracking
            self.locationManager.startUpdatingLocation()
            
            print("📍 Location refresh initiated - waiting for new GPS fix...")
        }
    }
    
    func stopLocationUpdates() {
        print("⏹ Stopping location updates")
        locationManager.stopUpdatingLocation()
    }
}
