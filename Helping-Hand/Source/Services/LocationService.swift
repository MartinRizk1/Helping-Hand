import Foundation
import CoreLocation
import Combine

class LocationService: ObservableObject {
    @Published var lastLocationResults: [LocationResult]? = nil
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var mapService = MapService()
    
    init() {
        // Initialize the service
    }
    
    func searchNearbyPlaces(for userQuery: String, query: String?) {
        guard let query = query else { return }
        
        // For testing, we'll always use mock data
        // In a real app, we'd check if we have location permission first
        createMockPlaces(for: query)
        
        // This is for logging purposes in testing
        print("Searching for: \(query) related to: \(userQuery)")
    }
    
    private func createMockPlaces(for query: String) {
        // Create mock location results based on query type
        var results: [LocationResult] = []
        
        if query.contains("window") || query.contains("repair") || query.contains("glass") {
            results = [
                createMockLocation(
                    name: "City Glass & Window", 
                    address: "123 Main Street",
                    category: "Window Repair",
                    distance: 1200,
                    rating: 4.7,
                    latOffset: 0.01,
                    lonOffset: 0.01
                ),
                createMockLocation(
                    name: "Quick Fix Glass", 
                    address: "456 Market Ave",
                    category: "Glass Replacement",
                    distance: 1800,
                    rating: 4.2,
                    latOffset: -0.005,
                    lonOffset: 0.015
                ),
                createMockLocation(
                    name: "Downtown Window Repair", 
                    address: "789 Central Blvd",
                    category: "Window Repair",
                    distance: 2500,
                    rating: 4.5,
                    latOffset: 0.02,
                    lonOffset: -0.01
                ),
                createMockLocation(
                    name: "Glass Masters", 
                    address: "101 Industrial Way",
                    category: "Glass Replacement",
                    distance: 3200,
                    rating: 4.8,
                    latOffset: -0.015,
                    lonOffset: -0.02
                )
            ]
        } 
        else if query.contains("restaurant") || query.contains("food") || query.contains("eat") {
            let cuisineType = query.contains("chinese") ? "Chinese" : "Restaurant"
            
            results = [
                createMockLocation(
                    name: cuisineType == "Chinese" ? "Golden Dragon" : "The Local Grill", 
                    address: "234 Dining Ave",
                    category: cuisineType,
                    distance: 800,
                    rating: 4.6,
                    latOffset: 0.005,
                    lonOffset: 0.008
                ),
                createMockLocation(
                    name: cuisineType == "Chinese" ? "Wok & Roll" : "Urban Bites", 
                    address: "567 Food Court",
                    category: cuisineType,
                    distance: 1100,
                    rating: 4.3,
                    latOffset: -0.007,
                    lonOffset: 0.003
                ),
                createMockLocation(
                    name: cuisineType == "Chinese" ? "Peking Palace" : "Seaside Kitchen", 
                    address: "890 Flavor St",
                    category: cuisineType,
                    distance: 1500,
                    rating: 4.7,
                    latOffset: 0.012,
                    lonOffset: -0.006
                ),
                createMockLocation(
                    name: cuisineType == "Chinese" ? "Shanghai Express" : "Cafe Delight", 
                    address: "321 Taste Blvd",
                    category: cuisineType,
                    distance: 2100,
                    rating: 4.1,
                    latOffset: -0.01,
                    lonOffset: -0.01
                ),
                createMockLocation(
                    name: cuisineType == "Chinese" ? "Lucky Bamboo" : "Fire & Fork", 
                    address: "654 Culinary Lane",
                    category: cuisineType,
                    distance: 2800,
                    rating: 4.4,
                    latOffset: 0.018,
                    lonOffset: 0.015
                )
            ]
        }
        else if query.contains("hotel") || query.contains("accommodation") {
            results = [
                createMockLocation(
                    name: "Grand Hotel", 
                    address: "100 Luxury Ave",
                    category: "Hotel",
                    distance: 1500,
                    rating: 4.8,
                    latOffset: 0.008,
                    lonOffset: 0.012
                ),
                createMockLocation(
                    name: "Comfort Inn", 
                    address: "200 Rest Blvd",
                    category: "Hotel",
                    distance: 2200,
                    rating: 4.3,
                    latOffset: -0.01,
                    lonOffset: 0.009
                ),
                createMockLocation(
                    name: "City Lodge", 
                    address: "300 Stay Street",
                    category: "Hotel",
                    distance: 2900,
                    rating: 4.0,
                    latOffset: 0.015,
                    lonOffset: -0.008
                )
            ]
        }
        else {
            // Generic places
            results = [
                createMockLocation(
                    name: "Local Business", 
                    address: "123 Main St",
                    category: "Business",
                    distance: 1000,
                    rating: 4.5,
                    latOffset: 0.01,
                    lonOffset: 0.01
                ),
                createMockLocation(
                    name: "Community Center", 
                    address: "456 Center Ave",
                    category: "Public",
                    distance: 1800,
                    rating: 4.2,
                    latOffset: -0.01,
                    lonOffset: 0.01
                )
            ]
        }
        
        // Publish the results
        self.lastLocationResults = results
    }
    
    private func createMockLocation(name: String, address: String, category: String, distance: CLLocationDistance, rating: Double, latOffset: Double, lonOffset: Double) -> LocationResult {
        // Create a coordinate based on user's location or a default location
        let baseLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // Default: San Francisco
        
        // Apply offset to create variation in locations
        let coordinate = CLLocationCoordinate2D(
            latitude: baseLocation.latitude + latOffset,
            longitude: baseLocation.longitude + lonOffset
        )
        
        // Create a mock phone number
        let areaCode = Int.random(in: 200...999)
        let prefix = Int.random(in: 200...999)
        let line = Int.random(in: 1000...9999)
        let phoneNumber = "(\(areaCode)) \(prefix)-\(line)"
        
        // Create a mock website
        let websiteString = "https://www.\(name.lowercased().replacingOccurrences(of: " ", with: ""))-example.com"
        let website = URL(string: websiteString)
        
        return LocationResult(
            name: name,
            address: address,
            coordinate: coordinate,
            category: category,
            phoneNumber: phoneNumber,
            website: website,
            rating: rating,
            distance: distance
        )
    }
}
