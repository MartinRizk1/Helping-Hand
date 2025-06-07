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
            content: "Hi there! I'm your AI assistant. I can help you find nearby places and services. Please allow location access so I can provide better recommendations.",
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
        
        // Process with AI service
        aiService.processUserQuery(text, location: formatCurrentLocation())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isTyping = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] (response, category) in
                    let aiMessage = ChatMessage(content: response, isUser: false)
                    self?.messages.append(aiMessage)
                    
                    if let category = category {
                        let searchQuery = self?.aiService.generateLocationQuery(for: category)
                        self?.locationService.searchNearbyPlaces(for: text, query: searchQuery)
                    }
                }
            )
            .store(in: &cancellables)
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
}
