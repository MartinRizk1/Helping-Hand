import Foundation
import CoreLocation
import MapKit
import OpenAI

class SearchService: ObservableObject {
    @Published var searchResults: [Place] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let openAI: OpenAI
    private let locationManager: CLLocationManager
    
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        // For now, use a simple fallback to avoid compilation errors
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-api-key-here"
        self.openAI = OpenAI(apiToken: apiKey)
    }
    
    func search(query: String) async {
        guard let location = locationManager.location else {
            error = NSError(domain: "SearchError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location not available"])
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // First, use AI to enhance the search query
            let enhancedQuery = try await enhanceSearchQuery(userQuery: query, userLocation: location)
            
            // Then perform the local search using MapKit
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = enhancedQuery
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 5000,  // 5km radius
                longitudinalMeters: 5000
            )
            
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            // Convert MKMapItems to our Place model
            let places = response.mapItems.map { mapItem -> Place in
                let distance = location.distance(from: mapItem.placemark.location ?? location)
                var place = Place.from(mapItem)
                place.distance = distance
                return place
            }
            
            // Sort by distance
            await MainActor.run {
                self.searchResults = places.sorted { $0.distance ?? 0 < $1.distance ?? 0 }
                self.error = nil
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.searchResults = []
            }
        }
    }
    
    private func enhanceSearchQuery(userQuery: String, userLocation: CLLocation) async throws -> String {
        let prompt = """
        Help me optimize this local search query: "\(userQuery)"
        Location context: Latitude \(userLocation.coordinate.latitude), Longitude \(userLocation.coordinate.longitude)
        
        Return ONLY the enhanced search query, nothing else. Make it specific and suited for finding local businesses.
        For example:
        - "food" → "restaurants food near me"
        - "coffee" → "coffee shops cafes near me"
        - "doctor" → "medical clinics doctors healthcare near me"
        """
        
        // Use the OpenAI SDK's ChatQuery structure properly
        let chatQuery = ChatQuery(
            model: .gpt3_5Turbo,
            messages: [
                .init(role: .user, content: prompt)
            ]
        )
        
        let result = try await openAI.chats(query: chatQuery)
        
        if let enhancedQuery = result.choices.first?.message.content?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
            return enhancedQuery
        }
        
        return userQuery
    }
}
