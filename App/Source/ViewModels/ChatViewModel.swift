import Foundation
import Combine
import CoreLocation

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var selectedMessage: ChatMessage? = nil
    @Published var error: String? = nil
    
    private let aiService: AIService
    private let locationService: LocationService
    private var cancellables = Set<AnyCancellable>()
    
    // Expose locationService for UI access
    var locationServiceInstance: LocationService { return locationService }
    
    init(aiService: AIService = AIService(), locationService: LocationService = LocationService()) {
        self.aiService = aiService
        self.locationService = locationService
        
        // Subscribe to location results
        locationService.$lastLocationResults
            .compactMap { $0 }
            .sink { [weak self] results in
                self?.handleLocationResults(results)
            }
            .store(in: &cancellables)
        
        // Subscribe to location authorization changes
        locationService.$authorizationStatus
            .sink { [weak self] status in
                self?.handleLocationAuthorizationChange(status)
            }
            .store(in: &cancellables)
            
        // Add welcome message
        let welcomeMessage = ChatMessage(
            content: "👋 Hi there! I'm your AI location assistant. I can help you find amazing places nearby and answer questions about locations or general information!\n\nTry asking me about:\n• Restaurants (like \"Chinese food\" or \"pizza\")\n• Hotels and accommodations\n• Shopping and services\n• Entertainment venues\n• Healthcare facilities\n• Information about cities or areas\n• General knowledge questions\n\nPlease allow location access so I can provide personalized recommendations based on where you are! 📍",
            isUser: false
        )
        messages.append(welcomeMessage)
        
        // Request location permission
        locationService.requestLocationPermission()
    }
    
    func sendMessage(_ text: String) {
        // Add user message
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)

        isTyping = true
        
        // Refresh location for real-time data before processing
        locationService.refreshCurrentLocation()
        
        // Small delay to allow location refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Process with AI service using current location
            self.aiService.processUserQuery(text, location: self.formatCurrentLocation())
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isTyping = false
                        if case .failure(let error) = completion {
                            self?.handleError(error)
                        }
                    },
                    receiveValue: { [weak self] (response, category) in
                        self?.isTyping = false
                        let aiMessage = ChatMessage(content: response, isUser: false)
                        self?.messages.append(aiMessage)
                        
                        // Analyze if this was an information-seeking query
                        let isInformationQuery = text.lowercased().contains("tell me about") || 
                                               text.lowercased().contains("what is") || 
                                               text.lowercased().contains("explain") ||
                                               text.starts(with: "Who") ||
                                               text.starts(with: "When") ||
                                               text.starts(with: "Why")
                        
                        // Only trigger location search if category is provided and not an information-only query
                        if let category = category, !isInformationQuery || category.contains("restaurant") || category.contains("store") {
                            // Enhanced search logic for better Apple Store/grocery detection
                            let specificQuery = self?.aiService.generateSpecificLocationQuery(for: text)
                            let searchQuery = specificQuery ?? self?.aiService.generateLocationQuery(for: category)
                            
                            print("🔍 Performing search with query: \(searchQuery ?? "unknown")")
                            print("🔍 Original user query: '\(text)'")
                            print("🔍 Detected category: '\(category)'")
                            
                            self?.locationService.searchNearbyPlaces(for: text, query: searchQuery)
                        } else if !isInformationQuery {
                            // If no category detected and not an information query, try to extract meaningful search terms
                            let fallbackQuery = self?.extractSearchTermsFromQuery(text)
                            if let fallbackQuery = fallbackQuery {
                                print("🔍 Performing fallback search with query: \(fallbackQuery)")
                                self?.locationService.searchNearbyPlaces(for: text, query: fallbackQuery)
                            }
                        } else {
                            // For information queries, we don't need to trigger a location search
                            print("ℹ️ Information query detected, skipping location search")
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    private func handleLocationResults(_ results: [LocationResult]) {
        guard let lastMessage = messages.last(where: { !$0.isUser }),
              lastMessage.locationResults == nil else { return }
        
        let updatedMessage = ChatMessage(
            id: lastMessage.id,
            content: lastMessage.content,
            isUser: false,
            timestamp: lastMessage.timestamp,
            locationResults: results
        )
        
        if let index = messages.firstIndex(where: { $0.id == lastMessage.id }) {
            messages[index] = updatedMessage
            selectedMessage = updatedMessage
        }
    }
    
    private func handleLocationAuthorizationChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            let message = ChatMessage(
                content: "I notice that location access is not enabled. To provide you with the best local recommendations, please enable location access in your device settings.",
                isUser: false
            )
            messages.append(message)
        case .authorizedWhenInUse, .authorizedAlways:
            locationService.startUpdatingLocation()
        default:
            break
        }
    }
    
    private func formatCurrentLocation() -> String? {
        guard let location = locationService.currentLocation else { return nil }
        return "\(location.coordinate.latitude),\(location.coordinate.longitude)"
    }
    
    func selectMessage(_ message: ChatMessage) {
        selectedMessage = message
    }
    
    func clearError() {
        DispatchQueue.main.async {
            self.error = nil
        }
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error.localizedDescription
            self.isTyping = false
        }
    }
    
    // MARK: - Real-time Location Methods
    
    func getCurrentLocationStatus() -> String {
        guard let location = locationService.currentLocation else {
            return "Location not available"
        }
        
        let age = -location.timestamp.timeIntervalSinceNow
        let accuracy = location.horizontalAccuracy
        
        if age < 30 && accuracy < 100 {
            return "Real-time location active (±\(Int(accuracy))m)"
        } else if age < 60 {
            return "Recent location (\(Int(age))s ago, ±\(Int(accuracy))m)"
        } else {
            return "Outdated location (\(Int(age/60))min ago)"
        }
    }
    
    func forceLocationRefresh() {
        print("🔄 Manual location refresh requested")
        locationService.refreshCurrentLocation()
    }
    
    func isLocationRealTime() -> Bool {
        guard let location = locationService.currentLocation else { return false }
        let age = -location.timestamp.timeIntervalSinceNow
        return age < 30 && location.horizontalAccuracy < 100
    }
    
    // MARK: - Search Enhancement Methods
    
    private func extractSearchTermsFromQuery(_ query: String) -> String? {
        let lowercased = query.lowercased()
        
        // Common search patterns
        let searchPatterns = [
            "find": "",
            "where": "",
            "locate": "",
            "search for": "",
            "looking for": "",
            "need": "",
            "want": ""
        ]
        
        var cleanQuery = lowercased
        for (pattern, replacement) in searchPatterns {
            cleanQuery = cleanQuery.replacingOccurrences(of: pattern, with: replacement)
        }
        
        cleanQuery = cleanQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If the cleaned query is meaningful, use it
        if cleanQuery.count > 2 && !cleanQuery.contains("near") && !cleanQuery.contains("nearby") {
            return cleanQuery
        }
        
        return nil
    }
}
