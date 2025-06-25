import Foundation
import CoreLocation
import Combine
import MapKit
import SwiftUI



class LocationService: NSObject, ObservableObject {
    @Published var lastLocationResults: [LocationResult]? = nil
    @Published var currentLocation: CLLocation? = nil
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUsingFallbackLocation: Bool = false
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // Enhanced services integration (lazy to avoid circular dependencies)
    private lazy var googlePlacesService = GooglePlacesService()
    private var prefService: PreferenceServiceProtocol? = nil
    private lazy var aiService = AIService()
    
    // Dallas coordinates as fallback location
    private let dallasLocation = CLLocation(latitude: 32.7767, longitude: -96.7970)
    
    override init() {
        super.init()
        setupLocationManager()
        
        // Set Dallas as initial location for immediate functionality
        DispatchQueue.main.async {
            self.currentLocation = self.dallasLocation
            self.isUsingFallbackLocation = true
            print("📍 Using Dallas as initial location: \(self.dallasLocation.coordinate.latitude), \(self.dallasLocation.coordinate.longitude)")
            
            // Initialize preference service on main thread
            Task {
                await MainActor.run {
                    self.prefService = UserPreferenceService()
                }
            }
        }
    }
    
    private func setupLocationManager() {
        locationManagerDelegate = LocationManagerDelegate()
        locationManagerDelegate?.onLocationUpdate = { [weak self] location in
            DispatchQueue.main.async {
                self?.currentLocation = location
                self?.isUsingFallbackLocation = false
                print("📍 Real GPS location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
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
        locationManagerDelegate?.onError = { _ in
            print("❌ Location error occurred")
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
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // For background location updates if needed
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = false
        }
    }
    
    func requestLocationPermission() {
        print("🔐 Requesting location permission...")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("❌ Location services are disabled")
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
        
        let searchLocation = currentLocation ?? dallasLocation
        let locationStatus = isUsingFallbackLocation ? "Dallas (fallback)" : "current GPS"
        
        print("🔍 Searching for: '\(query)' near \(searchLocation.coordinate.latitude), \(searchLocation.coordinate.longitude) (\(locationStatus))")
        
        // Enhanced search using both MapKit and Google Places API
        performHybridSearch(for: query, userQuery: userQuery, searchLocation: searchLocation)
    }
    
    /// Hybrid search combining MapKit and Google Places API with ML-powered ranking
    private func performHybridSearch(for query: String, userQuery: String, searchLocation: CLLocation) {
        var allResults: [LocationResult] = []
        let dispatchGroup = DispatchGroup()
        
        // 1. MapKit Search (fast, local)
        dispatchGroup.enter()
        performMapKitSearch(for: query, searchLocation: searchLocation) { results in
            allResults.append(contentsOf: results)
            dispatchGroup.leave()
        }
        
        // 2. Google Places API Search (comprehensive, rich data)
        dispatchGroup.enter()
        performGooglePlacesSearch(for: userQuery, location: searchLocation) { results in
            allResults.append(contentsOf: results)
            dispatchGroup.leave()
        }
        
        // 3. Process and rank results using ML
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.processAndRankResults(allResults, userQuery: userQuery, searchLocation: searchLocation)
        }
    }
    
    private func performMapKitSearch(for query: String, searchLocation: CLLocation, completion: @escaping ([LocationResult]) -> Void) {
        // Handle special "OR" queries for broader search results
        if query.contains(" OR ") {
            performMultipleSearches(for: query, userQuery: query, searchLocation: searchLocation)
            return
        }
        
        // Single search for regular queries
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: searchLocation.coordinate,
            latitudinalMeters: 10000, // 10km radius
            longitudinalMeters: 10000
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                print("❌ MapKit search error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            let results = response.mapItems.compactMap { item -> LocationResult? in
                let distance = item.placemark.location?.distance(from: searchLocation)
                if let distance = distance, distance > 50000 { return nil }
                
                let baseCategory = self.mapCategoryToFriendlyName(item.pointOfInterestCategory?.rawValue)
                let category = self.enhanceCategoryForAppleStores(item, baseCategory)
                
                return LocationResult(
                    name: item.name ?? "Unknown Place",
                    address: self.formatAddress(from: item.placemark),
                    coordinate: item.placemark.coordinate,
                    category: category,
                    phoneNumber: item.phoneNumber,
                    website: item.url,
                    rating: nil,
                    distance: distance
                )
            }
            
            print("📍 MapKit found \(results.count) results")
            completion(results)
        }
    }
    
    private func performGooglePlacesSearch(for query: String, location: CLLocation, completion: @escaping ([LocationResult]) -> Void) {
        print("🌍 Searching Google Places for: '\(query)'")
        
        Task {
            do {
                let places = try await googlePlacesService.searchPlaces(
                    query: query,
                    location: location.coordinate,
                    radius: 10000
                )
                
                let results = places.map { place in
                    LocationResult(
                        name: place.name,
                        address: place.address ?? "",
                        coordinate: place.coordinate,
                        category: place.category.rawValue,
                        phoneNumber: place.phoneNumber,
                        website: nil,
                        rating: place.rating,
                        distance: place.distance
                    )
                }
                
                await MainActor.run {
                    print("🌍 Google Places found \(results.count) results")
                    completion(results)
                }
                
            } catch {
                print("❌ Google Places search error: \(error.localizedDescription)")
                await MainActor.run {
                    completion([])
                }
            }
        }
    }
    
    private func processAndRankResults(_ results: [LocationResult], userQuery: String, searchLocation: CLLocation) {
        guard !results.isEmpty else {
            let noResults = [
                LocationResult(
                    name: "No results found for '\(userQuery)'",
                    address: "Try a different search term or check your location",
                    coordinate: searchLocation.coordinate,
                    category: "Search",
                    phoneNumber: nil,
                    website: nil,
                    rating: nil,
                    distance: nil
                )
            ]
            self.lastLocationResults = noResults
            return
        }
        
        // Remove duplicates based on name and location
        let uniqueResults = removeDuplicates(from: results)
        
        // Convert to Places for ML ranking
        let places = uniqueResults.map { result in
            Place(
                name: result.name,
                coordinate: result.coordinate,
                category: PlaceCategory.from(result.category),
                distance: result.distance,
                address: result.address,
                phoneNumber: result.phoneNumber,
                rating: result.rating,
                isOpen: nil
            )
        }
        
        // Use ML to rank results
        Task { [weak self] in
            // Capture self in a local variable to avoid reference in concurrently-executing code
            guard let weakSelf = self else { return }
            
            // For safety, check if preference service is initialized
            var rankedPlaces = places
            if let userPrefService = await MainActor.run(body: { weakSelf.prefService }) {
                rankedPlaces = await userPrefService.analyzeAndRankPlaces(
                    places,
                    userLocation: searchLocation.coordinate,
                    currentTime: Date()
                )
            }
            
            // Convert back to LocationResult
            let rankedResults = rankedPlaces.map { place in
                LocationResult(
                    name: place.name,
                    address: place.address ?? "",
                    coordinate: place.coordinate,
                    category: place.category.rawValue,
                    phoneNumber: place.phoneNumber,
                    website: nil,
                    rating: place.rating,
                    distance: place.distance
                )
            }
            
            await MainActor.run {
                weakSelf.lastLocationResults = rankedResults
                print("🧠 ML-ranked \(rankedResults.count) results")
                print("🔝 Top result: \(rankedResults.first?.name ?? "None")")
            }
        }
    }
    
    private func removeDuplicates(from results: [LocationResult]) -> [LocationResult] {
        var uniqueResults: [LocationResult] = []
        
        for result in results {
            let isDuplicate = uniqueResults.contains { existing in
                // Consider duplicates if name is similar and location is close
                let namesSimilar = existing.name.lowercased().levenshteinDistance(to: result.name.lowercased()) < 3
                let locationsClose = abs(existing.coordinate.latitude - result.coordinate.latitude) < 0.001 &&
                                   abs(existing.coordinate.longitude - result.coordinate.longitude) < 0.001
                return namesSimilar && locationsClose
            }
            
            if !isDuplicate {
                uniqueResults.append(result)
            }
        }
        
        return uniqueResults
    }
    
    private func performMultipleSearches(for query: String, userQuery: String, searchLocation: CLLocation) {
        let searchTerms = query.components(separatedBy: " OR ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var allResults: [LocationResult] = []
        let dispatchGroup = DispatchGroup()
        
        for searchTerm in searchTerms {
            dispatchGroup.enter()
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = searchTerm
            request.region = MKCoordinateRegion(
                center: searchLocation.coordinate,
                latitudinalMeters: 15000, // Larger radius for OR searches
                longitudinalMeters: 15000
            )
            
            let search = MKLocalSearch(request: request)
            search.start { [weak self] response, error in
                defer { dispatchGroup.leave() }
                
                guard let response = response, error == nil else {
                    print("❌ Search error for '\(searchTerm)': \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                print("✅ Found \(response.mapItems.count) results for '\(searchTerm)'")
                
                let results = response.mapItems.compactMap { item -> LocationResult? in
                    let distance = item.placemark.location?.distance(from: searchLocation)
                    if let distance = distance, distance > 75000 { // Larger radius for OR searches
                        return nil
                    }
                    
                    let baseCategory = self?.mapCategoryToFriendlyName(item.pointOfInterestCategory?.rawValue) ?? "Place"
                    let category = self?.enhanceCategoryForAppleStores(item, baseCategory) ?? baseCategory
                    return LocationResult(
                        name: item.name ?? "Unknown Place",
                        address: self?.formatAddress(from: item.placemark) ?? "",
                        coordinate: item.placemark.coordinate,
                        category: category,
                        phoneNumber: item.phoneNumber,
                        website: item.url,
                        rating: nil,
                        distance: distance
                    )
                }
                
                allResults.append(contentsOf: results)
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // Remove duplicates based on name and approximate location
            let uniqueResults = allResults.reduce(into: [LocationResult]()) { result, item in
                let isDuplicate = result.contains { existing in
                    existing.name.lowercased() == item.name.lowercased() &&
                    abs(existing.coordinate.latitude - item.coordinate.latitude) < 0.001 &&
                    abs(existing.coordinate.longitude - item.coordinate.longitude) < 0.001
                }
                if !isDuplicate {
                    result.append(item)
                }
            }
            
            let sortedResults = uniqueResults.sorted { (first, second) in
                guard let firstDistance = first.distance,
                      let secondDistance = second.distance else {
                    return false
                }
                return firstDistance < secondDistance
            }
            
            if sortedResults.isEmpty {
                let noResults = [
                    LocationResult(
                        name: "No results found for '\(userQuery)'",
                        address: "Try a different search term or check your location",
                        coordinate: searchLocation.coordinate,
                        category: "Search",
                        phoneNumber: nil,
                        website: nil,
                        rating: nil,
                        distance: nil
                    )
                ]
                self.lastLocationResults = noResults
            } else {
                self.lastLocationResults = sortedResults
                print("📋 Combined search returning \(sortedResults.count) unique results")
            }
        }
    }
    
    private func performSingleSearch(for query: String, userQuery: String, searchLocation: CLLocation) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: searchLocation.coordinate,
            latitudinalMeters: 10000, // 10km radius for better results
            longitudinalMeters: 10000
        )
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let response = response, error == nil else {
                print("❌ Search error: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    // Create a fallback response with helpful message
                    let fallbackResults = [
                        LocationResult(
                            name: "Search temporarily unavailable",
                            address: "Please try your search again in a moment",
                            coordinate: searchLocation.coordinate,
                            category: "Service",
                            phoneNumber: nil,
                            website: nil,
                            rating: nil,
                            distance: nil
                        )
                    ]
                    self?.lastLocationResults = fallbackResults
                }
                return
            }
            
            print("✅ Found \(response.mapItems.count) results for '\(query)'")
            
            let results = response.mapItems.compactMap { item -> LocationResult? in
                // Filter out results that are too far (more than 50km)
                let distance = item.placemark.location?.distance(from: searchLocation)
                if let distance = distance, distance > 50000 {
                    return nil
                }
                
                let baseCategory = self?.mapCategoryToFriendlyName(item.pointOfInterestCategory?.rawValue) ?? "Place"
                let category = self?.enhanceCategoryForAppleStores(item, baseCategory) ?? baseCategory
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
                if results.isEmpty {
                    // Create a "no results" message
                    let noResults = [
                        LocationResult(
                            name: "No results found for '\(userQuery)'",
                            address: "Try a different search term or check your location",
                            coordinate: searchLocation.coordinate,
                            category: "Search",
                            phoneNumber: nil,
                            website: nil,
                            rating: nil,
                            distance: nil
                        )
                    ]
                    self?.lastLocationResults = noResults
                } else {
                    self?.lastLocationResults = results
                    print("📋 Returning \(results.count) filtered and sorted results")
                }
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
    
    private func mapCategoryToFriendlyName(_ category: String?) -> String {
        guard let category = category else { return "Place" }
        
        switch category {
        case "MKPOICategoryRestaurant":
            return "Restaurant"
        case "MKPOICategoryCafe":
            return "Cafe"
        case "MKPOICategoryFoodMarket":
            return "Grocery Store"
        case "MKPOICategoryGasStation":
            return "Gas Station"
        case "MKPOICategoryHospital":
            return "Hospital"
        case "MKPOICategoryPharmacy":
            return "Pharmacy"
        case "MKPOICategorySchool":
            return "School"
        case "MKPOICategoryStore":
            return "Store"
        case "MKPOICategoryTravelAndTransport":
            return "Transportation"
        case "MKPOICategoryLodging":
            return "Hotel"
        case "MKPOICategoryEntertainment":
            return "Entertainment"
        case "MKPOICategoryFitnessCenter":
            return "Fitness Center"
        case "MKPOICategoryBank":
            return "Bank"
        case "MKPOICategoryATM":
            return "ATM"
        default:
            return "Place"
        }
    }
    
    private func enhanceCategoryForAppleStores(_ item: MKMapItem, _ category: String) -> String {
        let name = item.name?.lowercased() ?? ""
        
        // Enhanced Apple Store detection
        if name.contains("apple store") || name.contains("apple") && (name.contains("store") || name.contains("retail")) {
            return "Apple Store"
        }
        
        // Enhanced grocery store detection for apple fruit searches
        if (name.contains("grocery") || name.contains("supermarket") || name.contains("market") ||
            name.contains("walmart") || name.contains("target") || name.contains("kroger") ||
            name.contains("whole foods") || name.contains("trader joe")) && category == "Store" {
            return "Grocery Store"
        }
        
        return category
    }
}

// MARK: - String Extension for Duplicate Detection
extension String {
    func levenshteinDistance(to other: String) -> Int {
        let a = Array(self)
        let b = Array(other)
        
        var matrix = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        
        for i in 0...a.count {
            matrix[i][0] = i
        }
        
        for j in 0...b.count {
            matrix[0][j] = j
        }
        
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i-1] == b[j-1] {
                    matrix[i][j] = matrix[i-1][j-1]
                } else {
                    matrix[i][j] = Swift.min(
                        matrix[i-1][j] + 1,      // deletion
                        matrix[i][j-1] + 1,      // insertion
                        matrix[i-1][j-1] + 1     // substitution
                    )
                }
            }
        }
        
        return matrix[a.count][b.count]
    }
}
