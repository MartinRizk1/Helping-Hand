import Foundation
import Combine
import CoreLocation
import OpenAI

class AIService {
    private let openAI: OpenAI
    private let categoryKeywords: [String: [String]] = [
        "restaurant": ["restaurant", "food", "eat", "dining", "lunch", "dinner", "breakfast", "cafe", "chinese", "italian", "mexican", "thai", "japanese", "pizza", "burger", "sushi", "tacos", "coffee"],
        "hotel": ["hotel", "motel", "stay", "accommodation", "lodging", "inn", "resort", "bed and breakfast"],
        "shopping": ["shop", "mall", "store", "retail", "market", "grocery", "supermarket", "pharmacy", "clothing"],
        "entertainment": ["movie", "theatre", "entertainment", "fun", "activity", "cinema", "bowling", "arcade", "bar", "nightclub", "museum", "park"],
        "health": ["hospital", "doctor", "clinic", "medical", "pharmacy", "dentist", "urgent care", "emergency"],
        "transportation": ["transport", "bus", "train", "taxi", "station", "airport", "subway", "uber", "lyft"],
        "services": ["bank", "atm", "gas", "fuel", "repair", "salon", "spa", "gym", "fitness"],
        "education": ["school", "university", "library", "college", "education", "learning"]
    ]
    
    private let cuisineKeywords: [String: String] = [
        "chinese": "Chinese restaurants",
        "italian": "Italian restaurants", 
        "mexican": "Mexican restaurants",
        "thai": "Thai restaurants",
        "japanese": "Japanese restaurants and sushi",
        "indian": "Indian restaurants",
        "pizza": "Pizza places",
        "burger": "Burger restaurants",
        "sushi": "Sushi restaurants",
        "tacos": "Taco shops",
        "coffee": "Coffee shops and cafes"
    ]
    
    init() {
        let apiKey = APIConfig.openAIApiKey
        if apiKey.isEmpty || apiKey == "your-openai-api-key-here" {
            print("⚠️ OpenAI API key not configured - using fallback responses")
        }
        self.openAI = OpenAI(apiToken: apiKey)
    }
    
    func processUserQuery(_ query: String, location: String?) -> AnyPublisher<(String, String?), Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service not available"])))
                return
            }
            
            let lowercasedQuery = query.lowercased()
            var category: String?
            var specificSearchTerm: String?
            var locationContext = ""
            
            // Detect specific cuisine types first
            for (cuisine, searchTerm) in self.cuisineKeywords {
                if lowercasedQuery.contains(cuisine) {
                    category = "restaurant"
                    specificSearchTerm = searchTerm
                    break
                }
            }
            
            // If no specific cuisine found, detect general category
            if category == nil {
                for (key, keywords) in self.categoryKeywords {
                    if keywords.contains(where: lowercasedQuery.contains) {
                        category = key
                        break
                    }
                }
            }
            
            // Enhanced location context
            if let location = location {
                let coords = location.components(separatedBy: ",")
                if coords.count == 2 {
                    locationContext = " I am currently located at coordinates \(location). Please provide recommendations for places within walking or short driving distance."
                }
            }
            
            // Create enhanced system message with location awareness
            let systemMessage = """
            You are an intelligent location-based assistant that helps users find nearby places and services. 
            
            Your capabilities:
            - Analyze user queries to understand their specific needs
            - Provide helpful, contextual responses about local businesses and services
            - Give practical advice about finding places nearby
            - Be conversational and friendly while remaining helpful
            
            Guidelines:
            - Keep responses concise but informative (2-3 sentences)
            - When location is available, acknowledge the user's current area
            - Suggest what types of places will be shown in search results
            - Be encouraging and helpful in tone
            - If asked about specific cuisines (like "Chinese food"), mention you'll find those specific restaurants
            """
            
            // Enhanced user prompt with context
            let userPrompt = "\(query)\(locationContext)"
            
            let chatQuery = ChatQuery(
                messages: [
                    ChatQuery.ChatCompletionMessageParam(role: .system, content: systemMessage)!,
                    ChatQuery.ChatCompletionMessageParam(role: .user, content: userPrompt)!
                ],
                model: .gpt4_o_mini // Using GPT-4 for better understanding
            )
            
            Task {
                do {
                    // Check if API key is properly configured
                    let apiKey = APIConfig.openAIApiKey
                    if apiKey.isEmpty || apiKey == "your-openai-api-key-here" {
                        throw NSError(domain: "AIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not configured"])
                    }
                    
                    print("🤖 Sending request to ChatGPT...")
                    let result = try await self.openAI.chats(query: chatQuery)
                    
                    if let response = result.choices.first?.message.content {
                        print("✅ Received ChatGPT response: \(response)")
                        await MainActor.run {
                            // Return the AI response with the detected category or specific search term
                            let searchCategory = specificSearchTerm != nil ? "restaurant" : category
                            promise(.success((response, searchCategory)))
                        }
                    } else {
                        await MainActor.run {
                            promise(.failure(NSError(domain: "AIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No response from AI"])))
                        }
                    }
                } catch {
                    print("❌ ChatGPT API error: \(error.localizedDescription)")
                    // Enhanced fallback responses with location context
                    await MainActor.run {
                        let fallbackResponse = self.getEnhancedFallbackResponse(
                            for: category,
                            query: lowercasedQuery,
                            hasLocation: location != nil,
                            specificSearch: specificSearchTerm
                        )
                        let searchCategory = specificSearchTerm != nil ? "restaurant" : category
                        promise(.success((fallbackResponse, searchCategory)))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func getEnhancedFallbackResponse(for category: String?, query: String, hasLocation: Bool, specificSearch: String?) -> String {
        let locationSuffix = hasLocation ? " based on your current location" : ". Please enable location access for better results"
        
        // Add a subtle indicator that this is a fallback response
        let prefix = "Let me help you find "
        
        if let specificSearch = specificSearch {
            return "\(prefix)great \(specificSearch.lowercased()) near you\(locationSuffix). I'll search for places with good ratings and reviews!"
        }
        
        if let category = category {
            switch category {
            case "restaurant":
                return "\(prefix)some excellent dining options near you\(locationSuffix). I'll look for restaurants with good ratings and variety!"
            case "hotel":
                return "\(prefix)comfortable accommodations in your area\(locationSuffix). I'll search for well-rated hotels and lodging options."
            case "shopping":
                return "\(prefix)great shopping destinations nearby\(locationSuffix). Looking for popular stores and retail locations!"
            case "entertainment":
                return "\(prefix)fun entertainment venues in your area\(locationSuffix). I'll find movies, activities, and entertainment options!"
            case "health":
                return "\(prefix)healthcare facilities near you\(locationSuffix). Prioritizing the closest and most accessible options."
            case "transportation":
                return "\(prefix)transportation options in your area\(locationSuffix). I'll search for stations, stops, and transit information."
            case "services":
                return "\(prefix)helpful services near you\(locationSuffix). Looking for banks, gas stations, and other essential services!"
            case "education":
                return "\(prefix)educational facilities in your area\(locationSuffix). I'll search for schools, libraries, and learning centers."
            default:
                return "\(prefix)relevant places near you\(locationSuffix). I'll find what you're looking for!"
            }
        } else if query.contains("hi") || query.contains("hello") {
            return "Hello! I'm here to help you discover amazing places nearby. Try asking about restaurants, specific cuisines like 'Chinese food', hotels, shopping, or any other places you'd like to find!"
        } else {
            return "I can help you find local places and services\(locationSuffix). Try asking about restaurants, specific cuisines, hotels, shopping, entertainment, or other places you need!"
        }
    }
    
    func generateLocationQuery(for category: String) -> String {
        switch category {
        case "restaurant":
            return "restaurants"
        case "hotel":
            return "hotels"
        case "shopping":
            return "shopping centers"
        case "entertainment":
            return "entertainment venues"
        case "health":
            return "healthcare facilities"
        case "transportation":
            return "transportation stations"
        case "services":
            return "services"
        case "education":
            return "schools and libraries"
        default:
            return category
        }
    }
    
    func generateSpecificLocationQuery(for userQuery: String) -> String? {
        let lowercased = userQuery.lowercased()
        
        // Check for specific cuisine types
        for (cuisine, searchTerm) in cuisineKeywords {
            if lowercased.contains(cuisine) {
                return cuisine + " restaurants"
            }
        }
        
        // Check for other specific terms
        if lowercased.contains("coffee") || lowercased.contains("cafe") {
            return "coffee shops"
        }
        if lowercased.contains("grocery") || lowercased.contains("supermarket") {
            return "grocery stores"
        }
        if lowercased.contains("pharmacy") || lowercased.contains("drugstore") {
            return "pharmacies"
        }
        if lowercased.contains("gas") || lowercased.contains("fuel") {
            return "gas stations"
        }
        if lowercased.contains("bank") || lowercased.contains("atm") {
            return "banks"
        }
        
        return nil
    }
}
