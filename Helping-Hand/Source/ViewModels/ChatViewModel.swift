import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var characterMood: Character.Mood = .neutral
    @Published var selectedMessage: ChatMessage? = nil
    
    private let aiService: AIService
    private let locationService: LocationService
    private let persistenceService = PersistenceService()
    private var cancellables = Set<AnyCancellable>()
    
    init(aiService: AIService = AIService(), locationService: LocationService = LocationService()) {
        self.aiService = aiService
        self.locationService = locationService
        
        // Load saved messages or add welcome message if none exists
        let savedMessages = persistenceService.loadChatHistory()
        
        if !savedMessages.isEmpty {
            messages = savedMessages
            print("Loaded \(savedMessages.count) messages from history")
        } else {
            // Add welcome message
            let welcomeMessage = ChatMessage(
                content: "Hi there! I'm your Helping Hand assistant. How can I help you today?",
                isUser: false
            )
            messages.append(welcomeMessage)
        }
        
        // Subscribe to location results
        locationService.$lastLocationResults
            .compactMap { $0 }
            .sink { [weak self] results in
                self?.handleLocationResults(results)
            }
            .store(in: &cancellables)
            
        // Subscribe to changes in messages to save them
        $messages
            .dropFirst() // Skip initial value
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main) // Don't save too frequently
            .sink { [weak self] messages in
                self?.persistenceService.saveChatHistory(messages)
            }
            .store(in: &cancellables)
    }
    
    func sendMessage(_ text: String) {
        // Add user message
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        
        // Show typing indicator
        isTyping = true
        characterMood = .thinking
        
        // Process with AI
        aiService.processUserMessage(text)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.handleError()
                    }
                    self?.isTyping = false
                },
                receiveValue: { [weak self] response in
                    self?.handleAIResponse(response, userQuery: text)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleAIResponse(_ response: AIService.Response, userQuery: String) {
        // Handle location query if detected
        if response.requiresLocation {
            characterMood = .helping
            locationService.searchNearbyPlaces(for: userQuery, query: response.locationSearchQuery)
        }
        
        // Add AI response message
        let responseMessage = ChatMessage(content: response.text, isUser: false)
        messages.append(responseMessage)
        
        // Update character mood
        characterMood = response.suggestedMood
    }
    
    private func handleLocationResults(_ results: [LocationResult]) {
        guard let lastMessage = messages.last, !lastMessage.isUser else { return }
        
        // Create a new version of the last message with location results
        let updatedMessage = ChatMessage(
            content: lastMessage.content,
            isUser: lastMessage.isUser,
            timestamp: lastMessage.timestamp,
            locationResults: results
        )
        
        // Replace last message with updated version
        if let index = messages.firstIndex(where: { $0.id == lastMessage.id }) {
            messages[index] = updatedMessage
            selectedMessage = updatedMessage
        }
    }
    
    private func handleError() {
        characterMood = .neutral
        let errorMessage = ChatMessage(
            content: "I'm sorry, I'm having trouble connecting right now. Please try again later.",
            isUser: false
        )
        messages.append(errorMessage)
    }
    
    // New methods for chat management
    
    func clearHistory() {
        messages = []
        persistenceService.clearChatHistory()
        
        // Re-add welcome message
        let welcomeMessage = ChatMessage(
            content: "Hi there! I'm your Helping Hand assistant. How can I help you today?",
            isUser: false
        )
        messages.append(welcomeMessage)
    }
}
