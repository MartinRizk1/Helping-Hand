# HelpingHand AI/ML Integration Example

This document demonstrates how to use the advanced AI and ML features in HelpingHand.

## 🚀 Quick Start Examples

### Basic AI-Powered Search
```swift
// In your view controller or SwiftUI view
let chatViewModel = ChatViewModel()

// Send a natural language query
chatViewModel.sendMessage("Find me a good coffee shop nearby")

// The AI system will:
// 1. Analyze the query using NLP (intent: find_food/coffee)
// 2. Search both MapKit and Google Places API
// 3. Rank results using ML-based user preferences
// 4. Return personalized recommendations
```

### Advanced Context-Aware Search
```swift
// Handle ambiguous queries intelligently
chatViewModel.sendMessage("I need apples")

// AI determines context:
// - If user mentions "buy iPhone" recently → Apple Store
// - If user mentions "grocery" or "cooking" → Grocery stores
// - Default → Both Apple Stores and grocery stores
```

### Machine Learning Preference Learning
```swift
// Track user interactions for ML learning
let userPreferenceService = UserPreferenceService()

// Record user selection
userPreferenceService.recordUserInteraction(
    place: selectedPlace,
    duration: 45.0, // seconds spent viewing
    userLocation: currentLocation.coordinate
)

// Get ML-ranked recommendations
let rankedPlaces = await userPreferenceService.analyzeAndRankPlaces(
    searchResults,
    userLocation: currentLocation.coordinate
)
```

## 🧠 Advanced AI Features

### 1. Natural Language Processing
```swift
let aiService = AIService()

// Analyze user query with advanced NLP
let analysis = aiService.analyzeQueryIntent("Find Italian restaurants for dinner")

// Results:
// - Intent: .findFood (confidence: 0.8)
// - Entities: ["Italian", "restaurants", "dinner"]
// - Sentiment: neutral (0.0)
// - Context: evening dining preference detected
```

### 2. Semantic Search
```swift
// Perform semantic similarity search
let candidates = ["Italian Restaurant", "Pizza Place", "Sushi Bar", "Coffee Shop"]
let results = aiService.performSemanticSearch("Italian food", candidates: candidates)

// Returns ranked results based on semantic similarity:
// [("Italian Restaurant", 0.9), ("Pizza Place", 0.7), ...]
```

### 3. TensorFlow Lite Predictions
```swift
let tensorFlowService = TensorFlowLiteService()

// Get user context
let userContext = UserContext(
    timeOfDay: 18, // 6 PM
    dayOfWeek: 5,  // Friday
    weatherCondition: .sunny,
    locationFamiliarity: 0.8,
    currentActivity: .leisure
)

// Get ML-powered recommendations
let recommendations = tensorFlowService.recommendPlaces(
    places: searchResults,
    userContext: userContext
)

// Each recommendation includes:
// - place: Place object
// - score: ML confidence score (0.0-1.0)
// - confidence: Prediction confidence
// - reasoningFactors: ["Highly rated", "Close to location", "Matches preferences"]
```

## 📊 ML Model Training

### Data Collection
```swift
let trainingService = MLModelTrainingService()

// Record user interactions for model training
trainingService.recordUserInteraction(
    place: place,
    userLocation: userLocation,
    interactionType: "select", // view, select, call, navigate, bookmark
    userContext: userContext,
    interactionDuration: 30.0
)
```

### Automatic Model Retraining
```swift
// Check if model should be retrained
if trainingService.shouldRetrainModel() {
    // Automatically retrain with new data
    await trainingService.autoRetrainIfNeeded()
    
    // Listen for model updates
    NotificationCenter.default.addObserver(
        forName: .mlModelUpdated,
        object: nil,
        queue: .main
    ) { notification in
        if let newModel = notification.object as? MLModel {
            print("New ML model available!")
            // Update services with new model
        }
    }
}
```

## 🌍 Hybrid Search Integration

### Google Places + MapKit + AI
```swift
let locationService = LocationService()

// Trigger hybrid search
locationService.searchNearbyPlaces(
    for: "sushi restaurants", // Original user query
    query: "sushi restaurants near me" // AI-enhanced query
)

// Process:
// 1. MapKit search (fast, local results)
// 2. Google Places API search (comprehensive data)
// 3. ML ranking based on user preferences
// 4. Intelligent duplicate removal
// 5. Context-aware filtering
```

## 🎯 Personalization Examples

### Time-Based Recommendations
```swift
// Morning (7 AM) - Coffee shops ranked higher
// Lunch (12 PM) - Restaurants prioritized
// Evening (7 PM) - Entertainment venues boosted

let preferences = userPreferenceService.preferences
let coffeePreference = preferences[.coffee]?.score ?? 0.5

// ML automatically adjusts based on time context
```

### Location Familiarity
```swift
// Areas user visits frequently get familiarity bonus
// New areas are weighted for exploration vs. safety
let familiarityScore = userPreferenceService.getLocationFamiliarityScore(
    coordinate: place.coordinate
)

// Score: 0.0 (unknown) to 1.0 (very familiar)
```

### Behavioral Pattern Recognition
```swift
// ML learns patterns like:
// - User prefers highly-rated places (>4 stars)
// - User explores new places on weekends
// - User prefers closer places during work hours
// - User likes specific cuisines at certain times
```

## 🔧 Configuration Examples

### API Setup
```swift
// Configure in APIConfig.swift or secrets.json
let apiConfig = APIConfig()
print("OpenAI Key configured: \(!apiConfig.openAIKey.isEmpty)")
print("Google Places Key configured: \(!apiConfig.googlePlacesKey.isEmpty)")
```

### Custom ML Features
```swift
// Extend UserContext for custom features
extension UserContext {
    static func create(from location: CLLocation) -> UserContext {
        let calendar = Calendar.current
        let now = Date()
        
        return UserContext(
            timeOfDay: calendar.component(.hour, from: now),
            dayOfWeek: calendar.component(.weekday, from: now),
            weatherCondition: WeatherService.current(), // Custom weather integration
            locationFamiliarity: LocationAnalytics.familiarity(for: location),
            currentActivity: ActivityDetector.current() // Custom activity detection
        )
    }
}
```

## 🚀 Performance Optimization

### Efficient ML Inference
```swift
// TensorFlow Lite runs efficiently on device
// Models are loaded once and cached
// Batch predictions for multiple places
let batchRecommendations = tensorFlowService.recommendPlaces(
    places: allSearchResults, // Process multiple at once
    userContext: currentContext
)
```

### Smart Caching
```swift
// User preferences are cached and persisted
// ML models are lazy-loaded
// Search results are intelligently cached
userPreferenceService.preferences // Loaded from UserDefaults
tensorFlowService.generateEmbedding(for: "restaurant") // Cached embeddings
```

## 🔐 Privacy & Security

### On-Device Processing
```swift
// Most ML happens on device - no data sent to servers
let localPrediction = tensorFlowService.predictUserPreference(
    for: "restaurant",
    userFeatures: extractedFeatures
)

// Only anonymized training data can be exported
let anonymizedData = trainingService.exportTrainingData()
```

### User Control
```swift
// Users can reset all learned data
userPreferenceService.resetUserData()

// Users can see their preferences
for (category, preference) in userPreferenceService.preferences {
    print("\(category.rawValue): \(preference.score)")
}
```

## 🧪 Testing & Debugging

### AI Analysis Testing
```swift
#if DEBUG
let testQueries = [
    "Find Apple Store",
    "Fresh apples grocery",
    "Chinese food dinner",
    "Coffee shop morning"
]

for query in testQueries {
    let analysis = aiService.analyzeQueryIntent(query)
    print("Query: \(query)")
    print("Intent: \(analysis.intent.rawValue) (confidence: \(analysis.confidence))")
    print("Entities: \(analysis.entities)")
}
#endif
```

### ML Model Validation
```swift
#if DEBUG
// Test ML predictions with known data
let testPlace = Place(/* test data */)
let testContext = UserContext(/* test context */)

let recommendation = tensorFlowService.recommendPlaces(
    places: [testPlace],
    userContext: testContext
).first

print("ML Score: \(recommendation?.score ?? 0)")
print("Reasoning: \(recommendation?.reasoningFactors ?? [])")
#endif
```

This integration provides a foundation for building highly intelligent, personalized location-based experiences that learn and adapt to user preferences over time.
