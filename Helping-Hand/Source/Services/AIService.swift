import Foundation
import Combine

class AIService {
    struct Response {
        let text: String
        let requiresLocation: Bool
        let locationSearchQuery: String?
        let suggestedMood: Character.Mood
    }
    
    // In a real app, this would integrate with an actual AI service like OpenAI
    func processUserMessage(_ message: String) -> AnyPublisher<Response, Error> {
        return Future<Response, Error> { promise in
            // Print message for testing purposes
            print("Processing message: \(message)")
            
            // Simulate network request with a shorter delay for testing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let lowercasedMessage = message.lowercased()
                
                // Test case 1: Broken window
                if lowercasedMessage.contains("broken window") || 
                   lowercasedMessage.contains("fix window") || 
                   lowercasedMessage.contains("repair") {
                    
                    print("TEST: Detected window repair query")
                    let response = Response(
                        text: "I can help you find window repair services in your area. Here are some nearby places that might be able to help with your broken window:",
                        requiresLocation: true,
                        locationSearchQuery: "window repair glass replacement",
                        suggestedMood: .helping
                    )
                    promise(.success(response))
                    
                // Test case 2: Food related
                } else if lowercasedMessage.contains("chinese food") || 
                          lowercasedMessage.contains("restaurant") || 
                          lowercasedMessage.contains("food") ||
                          lowercasedMessage.contains("eat") {
                    
                    print("TEST: Detected food query")
                    var foodType = "restaurant"
                    if lowercasedMessage.contains("chinese") { foodType = "chinese restaurant" }
                    else if lowercasedMessage.contains("pizza") { foodType = "pizza" }
                    else if lowercasedMessage.contains("burger") { foodType = "burger" }
                    
                    let response = Response(
                        text: "I'd be happy to find some \(foodType) options near you. Here's what I found:",
                        requiresLocation: true,
                        locationSearchQuery: foodType,
                        suggestedMood: .happy
                    )
                    promise(.success(response))
                    
                // Test case 3: Accommodation
                } else if lowercasedMessage.contains("hotel") || 
                          lowercasedMessage.contains("place to stay") || 
                          lowercasedMessage.contains("motel") {
                          
                    print("TEST: Detected accommodation query")
                    let response = Response(
                        text: "Looking for accommodation? Here are some hotels and places to stay near your location:",
                        requiresLocation: true,
                        locationSearchQuery: "hotel accommodation",
                        suggestedMood: .helping
                    )
                    promise(.success(response))
                    
                } else {
                    // General response for messages that don't require location
                    print("TEST: Using general response")
                    let response = Response(
                        text: "I'm here to help you find local services and businesses. You can ask me about restaurants, repair services, hotels, and more in your area.",
                        requiresLocation: false,
                        locationSearchQuery: nil,
                        suggestedMood: .neutral
                    )
                    promise(.success(response))
                }
            }
        }.eraseToAnyPublisher()
    }
}
