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
            }
        }
        locationManagerDelegate?.onAuthorizationChange = { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                if status == .authorizedWhenInUse {
                    self?.startUpdatingLocation()
                }
            }
        }
        locationManager.delegate = locationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // Update location when user moves 50 meters
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    private var locationManagerDelegate: LocationManagerDelegate?
    
    func searchNearbyPlaces(for userQuery: String, query: String?) {
        guard let query = query else {
            print("Search query is missing")
            return
        }
        guard let location = currentLocation else {
            print("Location is not available")
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 2000, // 2km radius
            longitudinalMeters: 2000
        )
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let response = response, error == nil else {
                print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
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
}
