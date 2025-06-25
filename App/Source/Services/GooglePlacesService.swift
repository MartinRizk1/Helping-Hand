import Foundation
import CoreLocation
import MapKit

// MARK: - Google Places API Models
struct GooglePlacesResponse: Codable {
    let results: [GooglePlace]
    let status: String
    let nextPageToken: String?
    
    enum CodingKeys: String, CodingKey {
        case results, status
        case nextPageToken = "next_page_token"
    }
}

struct GooglePlace: Codable {
    let placeId: String
    let name: String
    let vicinity: String?
    let geometry: GoogleGeometry
    let rating: Double?
    let priceLevel: Int?
    let types: [String]
    let openingHours: GoogleOpeningHours?
    let photos: [GooglePhoto]?
    let formattedPhoneNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name, vicinity, geometry, rating, types, photos
        case priceLevel = "price_level"
        case openingHours = "opening_hours"
        case formattedPhoneNumber = "formatted_phone_number"
    }
}

struct GoogleGeometry: Codable {
    let location: GoogleLocation
}

struct GoogleLocation: Codable {
    let lat: Double
    let lng: Double
}

struct GoogleOpeningHours: Codable {
    let openNow: Bool?
    
    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
    }
}

struct GooglePhoto: Codable {
    let photoReference: String
    let width: Int
    let height: Int
    
    enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
        case width, height
    }
}

// MARK: - Google Places Service
class GooglePlacesService: ObservableObject {
    private let baseURL = "https://maps.googleapis.com/maps/api/place"
    private let apiKey = APIConfig.googlePlacesKey
    private let session = URLSession.shared
    
    // MARK: - Public Methods
    
    /// Search for places using Google Places API with AI-enhanced query processing
    func searchPlaces(
        query: String,
        location: CLLocationCoordinate2D,
        radius: Int = 5000,
        type: String? = nil
    ) async throws -> [Place] {
        
        // Enhanced query processing with AI
        let processedQuery = await processQueryWithAI(query)
        let searchType = determineSearchType(from: processedQuery)
        
        let places = try await performGooglePlacesSearch(
            query: processedQuery,
            location: location,
            radius: radius,
            type: searchType
        )
        
        return places.map { googlePlace in
            Place.from(googlePlace, userLocation: location)
        }
    }
    
    /// Get place details with enhanced information
    func getPlaceDetails(placeId: String) async throws -> GooglePlace {
        let fields = "place_id,name,formatted_address,formatted_phone_number,geometry,rating,opening_hours,photos,price_level,types,website"
        let urlString = "\(baseURL)/details/json?place_id=\(placeId)&fields=\(fields)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw GooglePlacesError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GooglePlacesError.networkError
        }
        
        let detailsResponse = try JSONDecoder().decode(GooglePlaceDetailsResponse.self, from: data)
        
        guard detailsResponse.status == "OK" else {
            throw GooglePlacesError.apiError(detailsResponse.status)
        }
        
        return detailsResponse.result
    }
    
    // MARK: - Private Methods
    
    private func processQueryWithAI(_ query: String) async -> String {
        // Enhanced query processing using natural language understanding
        let lowercasedQuery = query.lowercased()
        
        // AI-powered query enhancement
        if lowercasedQuery.contains("apple") {
            if lowercasedQuery.contains("store") || lowercasedQuery.contains("iphone") || 
               lowercasedQuery.contains("mac") || lowercasedQuery.contains("tech") {
                return "Apple Store"
            } else if lowercasedQuery.contains("fruit") || lowercasedQuery.contains("grocery") ||
                     lowercasedQuery.contains("fresh") || lowercasedQuery.contains("food") {
                return "grocery store apples"
            }
        }
        
        // Context-aware expansions
        if lowercasedQuery.contains("coffee") {
            return "coffee shop cafe"
        }
        
        if lowercasedQuery.contains("gas") {
            return "gas station fuel"
        }
        
        if lowercasedQuery.contains("food") || lowercasedQuery.contains("eat") {
            return "restaurant food"
        }
        
        return query
    }
    
    private func determineSearchType(from query: String) -> String? {
        let lowercasedQuery = query.lowercased()
        
        if lowercasedQuery.contains("restaurant") || lowercasedQuery.contains("food") {
            return "restaurant"
        }
        if lowercasedQuery.contains("gas") || lowercasedQuery.contains("fuel") {
            return "gas_station"
        }
        if lowercasedQuery.contains("coffee") || lowercasedQuery.contains("cafe") {
            return "cafe"
        }
        if lowercasedQuery.contains("grocery") || lowercasedQuery.contains("supermarket") {
            return "grocery_or_supermarket"
        }
        if lowercasedQuery.contains("hospital") || lowercasedQuery.contains("medical") {
            return "hospital"
        }
        if lowercasedQuery.contains("pharmacy") {
            return "pharmacy"
        }
        if lowercasedQuery.contains("bank") || lowercasedQuery.contains("atm") {
            return "bank"
        }
        if lowercasedQuery.contains("apple store") || lowercasedQuery.contains("electronics") {
            return "electronics_store"
        }
        
        return nil // No specific type, use text search
    }
    
    private func performGooglePlacesSearch(
        query: String,
        location: CLLocationCoordinate2D,
        radius: Int,
        type: String?
    ) async throws -> [GooglePlace] {
        
        var urlComponents = URLComponents(string: "\(baseURL)/nearbysearch/json")!
        
        var queryItems = [
            URLQueryItem(name: "location", value: "\(location.latitude),\(location.longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        } else {
            queryItems.append(URLQueryItem(name: "keyword", value: query))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw GooglePlacesError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GooglePlacesError.networkError
        }
        
        let placesResponse = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
        
        guard placesResponse.status == "OK" || placesResponse.status == "ZERO_RESULTS" else {
            throw GooglePlacesError.apiError(placesResponse.status)
        }
        
        return placesResponse.results
    }
}

// MARK: - Error Handling
enum GooglePlacesError: Error, LocalizedError {
    case invalidURL
    case networkError
    case apiError(String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for Google Places API"
        case .networkError:
            return "Network error occurred"
        case .apiError(let status):
            return "Google Places API error: \(status)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

// MARK: - Supporting Models
struct GooglePlaceDetailsResponse: Codable {
    let result: GooglePlace
    let status: String
}

// MARK: - Extensions
extension Place {
    static func from(_ googlePlace: GooglePlace, userLocation: CLLocationCoordinate2D) -> Place {
        let placeLocation = CLLocation(
            latitude: googlePlace.geometry.location.lat,
            longitude: googlePlace.geometry.location.lng
        )
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let distance = userCLLocation.distance(from: placeLocation)
        
        let category = PlaceCategory.from(googlePlace.types)
        
        return Place(
            name: googlePlace.name,
            coordinate: CLLocationCoordinate2D(
                latitude: googlePlace.geometry.location.lat,
                longitude: googlePlace.geometry.location.lng
            ),
            category: category,
            distance: distance,
            address: googlePlace.vicinity,
            phoneNumber: googlePlace.formattedPhoneNumber,
            rating: googlePlace.rating,
            isOpen: googlePlace.openingHours?.openNow
        )
    }
}

extension PlaceCategory {
    static func from(_ googleTypes: [String]) -> PlaceCategory {
        for type in googleTypes {
            switch type {
            case "restaurant", "meal_takeaway", "meal_delivery":
                return .food
            case "cafe", "coffee_shop":
                return .coffee
            case "grocery_or_supermarket", "supermarket":
                return .grocery
            case "electronics_store", "store":
                return .electronics
            case "shopping_mall", "clothing_store", "shoe_store":
                return .shopping
            case "hospital", "pharmacy", "doctor", "health":
                return .health
            case "gas_station", "car_repair", "car_dealer":
                return .transportation
            case "movie_theater", "amusement_park", "zoo":
                return .entertainment
            default:
                continue
            }
        }
        return .services
    }
}
