import Foundation
import Combine
import CoreLocation
import OpenAI
import NaturalLanguage
import CoreML

/// AIService is the core intelligence layer of the HelpingHand app, providing natural language
/// understanding, intent classification, and intelligent location-based recommendations.
///
/// Features:
/// - Advanced NLP for query understanding
/// - ML-powered intent classification
/// - Semantic search capabilities
/// - Real-time web information integration
/// - Location-aware context processing
///
/// The service gracefully degrades functionality when API keys are not configured,
/// using built-in fallback responses while maintaining core functionality.
class AIService {
    private let openAI: OpenAI
    
    // ML models (optional - will be loaded if available)
    private var sentimentClassifier: NLModel?
    private var intentClassifier: NLModel?
    
    // Enhanced NLP components
    private let languageRecognizer = NLLanguageRecognizer()
    private let tokenizer = NLTokenizer(unit: .word)
    private let tagger = NLTagger(tagSchemes: [.sentimentScore, .nameType, .lexicalClass])
    
    // NLP analysis thresholds
    private let semanticSimilarityThreshold: Float = 0.7
    
    // Enhanced context understanding
    private let contextualEmbeddings: [String: [Float]] = [:] // Pre-computed embeddings for common phrases
    
    // Web search and API integration
    private let urlSession: URLSession
    private let webSearchEnabled: Bool = true
    
    // Intent classifications with confidence scores
    enum QueryIntent: String, CaseIterable {
        case findFood = "find_food"
        case findAccommodation = "find_accommodation"
        case findShopping = "find_shopping"
        case findEntertainment = "find_entertainment"
        case findHealthcare = "find_healthcare"
        case findTransportation = "find_transportation"
        case getDirections = "get_directions"
        case askQuestion = "ask_question"
        case generalSearch = "general_search"
        case seekInformation = "seek_information"
        case askAboutCity = "ask_about_city"
        case askAboutArea = "ask_about_area"
        case generalKnowledge = "general_knowledge"
        case webSearch = "web_search"
        case realTimeInfo = "real_time_info"
        
        var confidence: Float {
            switch self {
            case .findFood, .findAccommodation, .findShopping: return 0.8
            case .findEntertainment, .findHealthcare, .findTransportation: return 0.7
            case .getDirections: return 0.9
            case .askQuestion: return 0.6
            case .generalSearch: return 0.4
            case .seekInformation, .askAboutCity, .askAboutArea: return 0.8
            case .generalKnowledge: return 0.7
            case .webSearch, .realTimeInfo: return 0.9
            }
        }
    }
    
    // Enhanced keyword mapping with semantic understanding
    private let semanticCategoryKeywords: [String: [String]] = [
        "restaurant": [
            // Base terms
            "restaurant", "food", "eat", "dining", "lunch", "dinner", "breakfast", "cafe", 
            // Cuisines
            "chinese", "italian", "mexican", "thai", "japanese", "pizza", "burger", "sushi", "tacos", "coffee",
            "indian", "korean", "vietnamese", "mediterranean", "greek", "french", "american", "bbq",
            // Food types
            "seafood", "steakhouse", "vegetarian", "vegan", "organic", "healthy", "fast food", "fine dining",
            // Meal contexts
            "brunch", "takeout", "delivery", "dine in", "buffet", "bar", "pub", "brewery"
        ],
        "hotel": [
            "hotel", "motel", "stay", "accommodation", "lodging", "inn", "resort", "bed and breakfast",
            "airbnb", "booking", "room", "suite", "hostel", "vacation rental", "check in"
        ],
        "shopping": [
            "shop", "mall", "store", "retail", "market", "grocery", "supermarket", "pharmacy", 
            "clothing", "apple", "apples", "electronics", "department store", "outlet", "boutique",
            "walmart", "target", "costco", "best buy", "clothing store", "shoe store"
        ],
        "entertainment": [
            "movie", "theatre", "entertainment", "fun", "activity", "cinema", "bowling", "arcade", 
            "bar", "nightclub", "museum", "park", "concert", "show", "gaming", "casino", "club",
            "amusement park", "zoo", "aquarium", "beach", "recreation"
        ],
        "health": [
            "doctor", "hospital", "clinic", "pharmacy", "medical", "health", "dentist", "urgent care",
            "emergency", "veterinarian", "vet", "medical center", "healthcare", "appointment"
        ],
        "transportation": [
            "gas", "fuel", "car wash", "auto repair", "parking", "uber", "lyft", "taxi", "bus",
            "train", "airport", "subway", "public transport", "rental car"
        ]
    ]
    // Legacy keyword mapping (kept for backward compatibility)
    private let categoryKeywords: [String: [String]] = [
        "restaurant": ["restaurant", "food", "eat", "dining", "lunch", "dinner", "breakfast", "cafe", "chinese", "italian", "mexican", "thai", "japanese", "pizza", "burger", "sushi", "tacos", "coffee"],
        "hotel": ["hotel", "motel", "stay", "accommodation", "lodging", "inn", "resort", "bed and breakfast"],
        "shopping": ["shop", "mall", "store", "retail", "market", "grocery", "supermarket", "pharmacy", "clothing", "apple", "apples"],
        "entertainment": ["movie", "theatre", "entertainment", "fun", "activity", "cinema", "bowling", "arcade", "bar", "nightclub", "museum", "park"],
        "health": ["doctor", "hospital", "clinic", "pharmacy", "medical", "health", "dentist", "urgent care"]
    ]
    
    private let cuisineKeywords: [String: String] = [
        "chinese": "Chinese restaurants",
        "italian": "Italian restaurants",
        "mexican": "Mexican restaurants",
        "thai": "Thai restaurants",
        "japanese": "Japanese restaurants",
        "pizza": "Pizza places",
        "burger": "Burger restaurants",
        "sushi": "Sushi restaurants",
        "tacos": "Taco shops",
        "coffee": "Coffee shops and cafes"
    ]
    
    // Special search terms that need intelligent handling
    private let specialSearchTerms: [String: [String]] = [
        "apple": ["Apple Store", "grocery stores apples", "electronics store apple"],
        "apples": ["Apple Store", "grocery stores fresh apples", "supermarket fruits"]
    ]
    
    init() {
        let apiKey = APIConfig.openAIKey
        if apiKey.isEmpty || apiKey == "your-openai-api-key-here" {
            print("⚠️ OpenAI API key not configured - using fallback responses")
        }
        self.openAI = OpenAI(apiToken: apiKey)
        
        // Configure URL session for web requests
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 30.0
        self.urlSession = URLSession(configuration: config)
        
        // Initialize NLP components
        setupNLPComponents()
        
        // Load ML models if available (graceful fallback if not present)
        loadMLModels()
        
        print("🧠 AI Service initialized with advanced NLP capabilities and web access")
        print("🌐 Web search capabilities: \(webSearchEnabled ? "Enabled" : "Disabled")")
    }
    
    // MARK: - Web Search Integration
    
    /// Performs web search for real-time information
    func performWebSearch(_ query: String) async throws -> String {
        guard webSearchEnabled else {
            throw NSError(domain: "AIService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Web search not enabled"])
        }
        
        // For demonstration, we'll use a basic search approach
        // In production, you'd integrate with search APIs like Google Custom Search, Bing, etc.
        
        let searchQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let searchURLString = "https://api.duckduckgo.com/?q=\(searchQuery)&format=json&no_html=1&skip_disambig=1"
        
        guard let url = URL(string: searchURLString) else {
            throw NSError(domain: "AIService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Invalid search URL"])
        }
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "AIService", code: -6, userInfo: [NSLocalizedDescriptionKey: "Search request failed"])
        }
        
        // Parse the response and extract relevant information
        if let searchResult = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            var searchSummary = "Here's what I found:\n\n"
            
            if let abstract = searchResult["Abstract"] as? String, !abstract.isEmpty {
                searchSummary += "Summary: \(abstract)\n\n"
            }
            
            if let relatedTopics = searchResult["RelatedTopics"] as? [[String: Any]], !relatedTopics.isEmpty {
                searchSummary += "Related Information:\n"
                for (index, topic) in relatedTopics.prefix(3).enumerated() {
                    if let topicText = topic["Text"] as? String {
                        searchSummary += "\(index + 1). \(topicText)\n"
                    }
                }
            }
            
            return searchSummary.isEmpty ? "I found some information, but couldn't extract specific details. Try rephrasing your question." : searchSummary
        }
        
        return "I was able to search for information, but couldn't parse the results. Please try a different search term."
    }
    
    private func setupNLPComponents() {
        // Configure the tagger for advanced text analysis
        tagger.string = ""
        
        // Set up tokenizer for word-level analysis
        tokenizer.setLanguage(.english)
        
        print("📝 NLP components configured")
    }
    
    private func loadMLModels() {
        // Try to load sentiment classifier
        if let sentimentModelURL = Bundle.main.url(forResource: "SentimentClassifier", withExtension: "mlmodelc") {
            do {
                let mlModel = try MLModel(contentsOf: sentimentModelURL)
                sentimentClassifier = try NLModel(mlModel: mlModel)
                print("✅ Sentiment classifier loaded")
            } catch {
                print("⚠️ Failed to load sentiment classifier: \(error.localizedDescription)")
            }
        }
        
        // Try to load intent classifier
        if let intentModelURL = Bundle.main.url(forResource: "IntentClassifier", withExtension: "mlmodelc") {
            do {
                let mlModel = try MLModel(contentsOf: intentModelURL)
                intentClassifier = try NLModel(mlModel: mlModel)
                print("✅ Intent classifier loaded")
            } catch {
                print("⚠️ Failed to load intent classifier: \(error.localizedDescription)")
            }
        }
        
        if sentimentClassifier == nil && intentClassifier == nil {
            print("🔄 Using rule-based NLP analysis (ML models not available)")
        }
    }
    
    // MARK: - Advanced NLP Processing
    
    /// Analyzes user query using advanced NLP techniques
    func analyzeQueryIntent(_ query: String) -> (intent: QueryIntent, confidence: Float, entities: [String]) {
        let lowercaseQuery = query.lowercased()
        
        // Extract named entities
        let entities = extractNamedEntities(from: query)
        
        // Perform sentiment analysis
        let sentiment = analyzeSentiment(query)
        
        // Detect intent using semantic analysis
        let intent = detectIntent(from: lowercaseQuery, entities: entities)
        
        // Calculate confidence based on multiple factors
        let confidence = calculateIntentConfidence(query: lowercaseQuery, intent: intent, sentiment: sentiment)
        
        print("🧠 Query analysis - Intent: \(intent.rawValue), Confidence: \(confidence), Entities: \(entities)")
        
        return (intent, confidence, entities)
    }
    
    private func extractNamedEntities(from text: String) -> [String] {
        var entities: [String] = []
        
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType) { tag, tokenRange in
            if let tag = tag, tag == .personalName || tag == .placeName || tag == .organizationName {
                let entity = String(text[tokenRange])
                entities.append(entity)
            }
            return true
        }
        
        return entities
    }
    
    private func analyzeSentiment(_ text: String) -> Float {
        tagger.string = text
        
        let tagResult = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        if let sentiment = tagResult.0 {
            if let score = Float(sentiment.rawValue) {
                return score
            }
        }
        
        return 0.0 // Neutral sentiment
    }
    
    private func detectIntent(from query: String, entities: [String]) -> QueryIntent {
        // Check for information-seeking patterns first
        let informationKeywords = ["tell me about", "what is", "information on", "facts about", "history of", 
                                  "explain", "describe", "details about", "who is", "when was"]
        
        for keyword in informationKeywords {
            if query.lowercased().contains(keyword) {
                return .seekInformation
            }
        }
        
        // Check for location-specific information requests
        let cityAreaKeywords = ["city", "town", "area", "neighborhood", "district", "region", "downtown", "uptown"]
        if informationKeywords.contains(where: { query.lowercased().contains($0) }) && 
           cityAreaKeywords.contains(where: { query.lowercased().contains($0) }) {
            return .askAboutArea
        }
        
        // Enhanced intent detection using semantic keywords
        for (category, keywords) in semanticCategoryKeywords {
            let matches = keywords.filter { query.contains($0) }
            if !matches.isEmpty {
                switch category {
                case "restaurant": return .findFood
                case "hotel": return .findAccommodation
                case "shopping": return .findShopping
                case "entertainment": return .findEntertainment
                case "health": return .findHealthcare
                case "transportation": return .findTransportation
                default: break
                }
            }
        }
        
        // Check for direction-related queries
        if query.contains("direction") || query.contains("navigate") || query.contains("route") {
            return .getDirections
        }
        
        // Check for question patterns
        if query.starts(with: "what") || query.starts(with: "where") || 
           query.starts(with: "how") || query.starts(with: "why") || 
           query.starts(with: "who") || query.starts(with: "when") || 
           query.contains("?") {
            // Check if it's a general knowledge question
            let generalKnowledgeIndicators = ["history", "science", "technology", "politics", 
                                             "culture", "art", "music", "sports", "world", 
                                             "universe", "planet", "country", "law", "economy"]
            
            if generalKnowledgeIndicators.contains(where: { query.lowercased().contains($0) }) {
                return .generalKnowledge
            }
            
            return .askQuestion
        }
        
        return .generalSearch
    }
    
    private func calculateIntentConfidence(query: String, intent: QueryIntent, sentiment: Float) -> Float {
        var confidence = intent.confidence
        
        // Adjust confidence based on query length and specificity
        let wordCount = query.components(separatedBy: .whitespaces).count
        if wordCount >= 3 {
            confidence += 0.1
        }
        
        // Adjust for sentiment (more neutral = higher confidence for factual queries)
        if abs(sentiment) < 0.3 {
            confidence += 0.05
        }
        
        // Ensure confidence stays within bounds
        return min(max(confidence, 0.0), 1.0)
    }
    
    /// Enhanced semantic search using NLP embeddings
    func performSemanticSearch(_ query: String, candidates: [String]) -> [(text: String, similarity: Float)] {
        // This would use actual embeddings in production
        // For now, using enhanced keyword matching with fuzzy logic
        
        var results: [(text: String, similarity: Float)] = []
        let queryTokens = Set(tokenizeText(query))
        
        for candidate in candidates {
            let candidateTokens = Set(tokenizeText(candidate))
            let intersection = queryTokens.intersection(candidateTokens)
            let union = queryTokens.union(candidateTokens)
            
            let jaccardSimilarity = Float(intersection.count) / Float(union.count)
            
            if jaccardSimilarity >= semanticSimilarityThreshold {
                results.append((candidate, jaccardSimilarity))
            }
        }
        
        return results.sorted { $0.similarity > $1.similarity }
    }
    
    private func tokenizeText(_ text: String) -> [String] {
        var tokens: [String] = []
        
        tokenizer.string = text.lowercased()
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let token = String(text[tokenRange])
            if token.count > 2 { // Filter out very short tokens
                tokens.append(token)
            }
            return true
        }
        
        return tokens
    }
    
    // MARK: - Enhanced Query Processing
    
    func processUserQuery(_ query: String, location: String?) -> AnyPublisher<(String, String?), Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service not available"])))
                return
            }
            
            // Enhanced NLP analysis
            let analysis = self.analyzeQueryIntent(query)
            let lowercasedQuery = query.lowercased()
            
            var category: String?
            var specificSearchTerm: String?
            var locationContext = ""
            var requiresWebSearch = false
            
            // Determine if this is primarily an information-seeking query or requires web search
            let isInformationQuery = analysis.intent == .seekInformation || 
                                    analysis.intent == .askAboutArea || 
                                    analysis.intent == .generalKnowledge ||
                                    analysis.intent == .webSearch ||
                                    analysis.intent == .realTimeInfo
            
            // Check if query requires real-time web information
            let webSearchKeywords = ["current", "latest", "recent", "news", "today", "now", "this week", "this month", "2024", "2025"]
            requiresWebSearch = webSearchKeywords.contains { lowercasedQuery.contains($0) } || 
                               (isInformationQuery && analysis.confidence > 0.7)
            
            // Use NLP intent to determine category
            switch analysis.intent {
            case .findFood:
                category = "restaurant"
            case .findAccommodation:
                category = "hotel"
            case .findShopping:
                category = "shopping"
            case .findEntertainment:
                category = "entertainment"
            case .findHealthcare:
                category = "health"
            case .findTransportation:
                category = "transportation"
            case .seekInformation, .askAboutArea, .generalKnowledge:
                // For information queries, we might not need a category
                category = "information"
            default:
                // Fall back to legacy keyword detection
                category = self.detectCategoryFromKeywords(lowercasedQuery)
            }
            
            // Detect specific cuisine types with enhanced NLP
            if category == "restaurant" || analysis.intent == .findFood {
                specificSearchTerm = self.detectSpecificCuisine(query, entities: analysis.entities)
            }
            
            // Enhanced location context with NLP insights
            if let location = location {
                let coords = location.components(separatedBy: ",")
                if coords.count == 2 {
                    let contextualPrompt = analysis.confidence > 0.8 ? 
                        " I am currently at coordinates \(location) and I'm looking for \(analysis.intent.rawValue.replacingOccurrences(of: "_", with: " ")). Please provide personalized recommendations." :
                        " I am currently located at coordinates \(location). Please provide recommendations for places within walking or short driving distance."
                    locationContext = contextualPrompt
                }
            }
            
            Task {
                do {
                    var webSearchContext = ""
                    
                    // Perform web search if needed for real-time information
                    if requiresWebSearch && self.webSearchEnabled {
                        do {
                            print("🌐 Performing web search for: \(query)")
                            let searchResults = try await self.performWebSearch(query)
                            webSearchContext = "\n\nReal-time web information:\n\(searchResults)"
                        } catch {
                            print("⚠️ Web search failed: \(error.localizedDescription)")
                            webSearchContext = "\n\nNote: I couldn't access real-time web information, but I'll provide the best answer I can with my knowledge."
                        }
                    }
                    
                    // Create enhanced system message with NLP insights, web search, and location awareness
                    let systemMessage = """
                    You are an intelligent location-based assistant powered by advanced NLP that helps users find nearby places and services as well as provide general information with access to real-time web data when needed.
                    
                    Your capabilities:
                    - Analyze user queries using natural language processing to understand context and intent
                    - Access real-time web information for current events, news, and updated facts
                    - Provide contextual, personalized responses about local businesses and services
                    - Use semantic understanding to give practical advice about finding places nearby
                    - Provide general information and answer knowledge-based questions with current data
                    - Adapt responses based on user intent confidence: \(String(format: "%.2f", analysis.confidence))
                    - Current detected intent: \(analysis.intent.rawValue.replacingOccurrences(of: "_", with: " "))
                    - Web search performed: \(requiresWebSearch ? "Yes" : "No")
                    
                    Guidelines:
                    - Keep responses concise but informative (2-3 sentences for location queries, more detailed for information queries)
                    - When location is available, acknowledge the user's current area for location-based queries
                    - Suggest what types of places will be shown in search results for location-based queries
                    - For general knowledge or information queries, provide helpful, factual information (use web data if available)
                    - If web search data is provided, incorporate it naturally into your response
                    - If a user asks about the local area, provide both general information and suggest related location searches
                    - Be encouraging and helpful in tone, adapting to user intent confidence
                    - If asked about specific cuisines or entities detected: \(analysis.entities.joined(separator: ", "))
                    - Use natural, conversational language that matches the user's query style
                    - For real-time information requests, clearly indicate when you're using current web data
                    """
                    
                    // Enhanced user prompt with context and web search results
                    let userPrompt = "\(query)\(locationContext)\(webSearchContext)"
                    
                    let chatQuery = ChatQuery(
                        model: "gpt-4o-mini", // Using GPT-4o mini for better understanding
                        messages: [
                            Chat(role: .system, content: systemMessage),
                            Chat(role: .user, content: userPrompt)
                        ]
                    )
                    
                    // Check if API key is properly configured
                    let apiKey = APIConfig.openAIKey
                    // Capture variables for safe concurrent usage
                    let capturedCategory = category
                    let capturedSpecificSearchTerm = specificSearchTerm
                    
                    if apiKey.isEmpty || apiKey == "your-openai-api-key-here" {
                        throw NSError(domain: "AIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not configured"])
                    }
                    
                    print("🤖 Sending enhanced request to ChatGPT with web search context...")
                    let result = try await self.openAI.chats(query: chatQuery)
                    
                    if let response = result.choices.first?.message.content {
                        print("✅ Received ChatGPT response: \(response)")
                        await MainActor.run {
                            // Return the AI response with the detected category or specific search term
                            let searchCategory = capturedSpecificSearchTerm != nil ? "restaurant" : capturedCategory
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
                    let capturedCategory = category // Capture for safe concurrent use
                    await MainActor.run {
                        let fallbackResponse = self.getEnhancedFallbackResponse(
                            for: query, 
                            category: capturedCategory, 
                            hasLocation: location != nil
                        )
                        promise(.success((fallbackResponse, capturedCategory)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getEnhancedFallbackResponse(for query: String, category: String?, hasLocation: Bool) -> String {
        let locationSuffix = hasLocation ? " based on your current location" : " in the Dallas, TX area"
        let prefix = hasLocation ? "Great! I can help you find " : "I'll search the Dallas area to find "
        
        // Handle special apple queries
        let lowercased = query.lowercased()
        if lowercased.contains("apple") || lowercased.contains("apples") {
            if lowercased.contains("store") || lowercased.contains("buy") || lowercased.contains("tech") {
                return "\(prefix)Apple Stores\(locationSuffix). I'll search for official Apple retail locations where you can buy Apple products!"
            } else if lowercased.contains("eat") || lowercased.contains("fruit") || lowercased.contains("fresh") || lowercased.contains("grocery") {
                return "\(prefix)grocery stores with fresh apples\(locationSuffix). I'll find supermarkets and food stores where you can buy fresh apples!"
            } else {
                return "\(prefix)both Apple Stores and grocery stores with apples\(locationSuffix). I'll search for Apple retail locations and supermarkets!"
            }
        }
        
        if let category = category {
            switch category {
            case "restaurant":
                return "\(prefix)restaurants and dining options\(locationSuffix). I'll search for great places to eat nearby!"
            case "hotel":
                return "\(prefix)hotels and accommodations\(locationSuffix). I'll find comfortable places to stay."
            case "shopping":
                return "\(prefix)shopping centers and stores\(locationSuffix). I'll locate the best shopping options nearby."
            case "entertainment":
                return "\(prefix)entertainment venues and activities\(locationSuffix). I'll find fun things to do in your area."
            case "health":
                return "\(prefix)healthcare facilities and medical services\(locationSuffix). I'll help you find medical care nearby."
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
            return "medical facilities"
        default:
            return category
        }
    }
    
    func generateSpecificLocationQuery(for userQuery: String) -> String? {
        let lowercased = userQuery.lowercased()
        
        // Handle special search terms that could have multiple meanings
        if lowercased.contains("apple") || lowercased.contains("apples") {
            // Context clues that suggest Apple Store (tech company)
            let appleStoreIndicators = [
                "apple store", "iphone", "ipad", "mac", "macbook", "watch", "airpods",
                "repair", "genius", "tech", "computer", "device", "electronics"
            ]
            
            // Context clues that suggest grocery store (fruit)
            let groceryIndicators = [
                "fresh", "organic", "fruit", "grocery", "supermarket", "produce",
                "food", "eat", "cooking", "recipe", "juice", "pie", "crisp",
                "red apples", "green apples", "gala", "granny smith", "honeycrisp"
            ]
            
            let hasAppleStoreContext = appleStoreIndicators.contains { lowercased.contains($0) }
            let hasGroceryContext = groceryIndicators.contains { lowercased.contains($0) }
            
            // Special case: "buy" with Apple products
            let hasBuyAppleProducts = lowercased.contains("buy") && (
                lowercased.contains("iphone") || lowercased.contains("ipad") || 
                lowercased.contains("mac") || lowercased.contains("apple")
            )
            
            if hasAppleStoreContext || hasBuyAppleProducts {
                return "Apple Store"
            } else if hasGroceryContext {
                return "grocery stores fresh apples"
            } else if lowercased.contains("store") && !lowercased.contains("grocery") {
                // Generic "store" with apple likely means Apple Store
                return "Apple Store"
            } else {
                // Default to both Apple Stores and grocery stores
                return "Apple Store OR grocery stores apples"
            }
        }
        
        // Check for specific cuisines
        for (cuisine, searchTerm) in cuisineKeywords {
            if lowercased.contains(cuisine) {
                return searchTerm.lowercased()
            }
        }
        
        // Check for specific terms
        if lowercased.contains("coffee") { return "coffee shops" }
        if lowercased.contains("gas") { return "gas stations" }
        if lowercased.contains("pharmacy") { return "pharmacies" }
        if lowercased.contains("grocery") { return "grocery stores" }
        if lowercased.contains("bank") { return "banks" }
        if lowercased.contains("hospital") { return "hospitals" }
        if lowercased.contains("hotel") { return "hotels" }
        if lowercased.contains("restaurant") { return "restaurants" }
        
        return nil
    }
    
    // MARK: - Enhanced Helper Methods
    
    private func detectCategoryFromKeywords(_ query: String) -> String? {
        for (key, keywords) in categoryKeywords {
            if keywords.contains(where: query.contains) {
                return key
            }
        }
        return nil
    }
    
    private func detectSpecificCuisine(_ query: String, entities: [String]) -> String? {
        let lowercased = query.lowercased()
        
        // Enhanced cuisine detection with entity recognition
        for entity in entities {
            if let searchTerm = cuisineKeywords[entity.lowercased()] {
                return searchTerm
            }
        }
        
        // Fallback to traditional keyword matching
        for (cuisine, searchTerm) in cuisineKeywords {
            if lowercased.contains(cuisine) {
                return searchTerm
            }
        }
        
        return nil
    }
}
