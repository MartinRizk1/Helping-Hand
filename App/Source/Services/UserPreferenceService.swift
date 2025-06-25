import Foundation
import CoreML
import CoreLocation
import Combine

// MARK: - User Preference Models
struct UserPreference: Codable {
    let category: PlaceCategory
    let score: Double
    let lastUpdated: Date
    let interactionCount: Int
    
    enum CodingKeys: String, CodingKey {
        case category, score, lastUpdated, interactionCount
    }
}

struct UserBehavior: Codable {
    let searchQuery: String
    let selectedPlace: String?
    let category: PlaceCategory
    let timeOfDay: Int // 0-23
    let dayOfWeek: Int // 1-7
    let location: UserLocation
    let duration: TimeInterval // Time spent viewing/interacting
    let timestamp: Date
}

struct UserLocation: Codable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Machine Learning Features
struct MLFeatures {
    let timeOfDay: Double
    let dayOfWeek: Double
    let category: Double
    let distanceFromUser: Double
    let rating: Double
    let priceLevel: Double
    let previousInteractions: Double
    let locationFamiliarity: Double
}

// MARK: - Models for ML Features and Context
enum WeatherCondition: Int, CaseIterable {
    case sunny = 0
    case cloudy = 1
    case rainy = 2
    case snowy = 3
    case unknown = 4
}

enum UserActivity: Int, CaseIterable {
    case commuting = 0
    case leisure = 1
    case business = 2
    case tourism = 3
    case emergency = 4
    case unknown = 5
}

struct UserContext {
    let timeOfDay: Int
    let dayOfWeek: Int
    let weatherCondition: WeatherCondition
    let locationFamiliarity: Float
    let currentActivity: UserActivity
}

struct PlaceRecommendation {
    let place: Place
    let score: Float
    let reasoningFactors: [String]
    
    init(place: Place, score: Float, reasoningFactors: [String] = []) {
        self.place = place
        self.score = score
        self.reasoningFactors = reasoningFactors
    }
}

// Protocol for UserPreferenceService to avoid circular dependencies
protocol PreferenceServiceProtocol: AnyObject {
    func analyzeAndRankPlaces(_ places: [Place], userLocation: CLLocationCoordinate2D, currentTime: Date) async -> [Place]
}

// MARK: - User Preference Service with Core ML
@MainActor
class UserPreferenceService: ObservableObject, PreferenceServiceProtocol {
    @Published var preferences: [PlaceCategory: UserPreference] = [:]
    @Published var isLoading = false
    
    private var behaviorHistory: [UserBehavior] = []
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "user_preferences"
    private let behaviorKey = "user_behavior_history"
    
    init() {
        loadPreferences()
        loadBehaviorHistory()
    }
    
    // MARK: - Preference Management
    
    private func loadPreferences() {
        if let data = userDefaults.data(forKey: preferencesKey) {
            do {
                let decoder = JSONDecoder()
                let loadedPreferences = try decoder.decode([PlaceCategory: UserPreference].self, from: data)
                self.preferences = loadedPreferences
                print("📊 Loaded user preferences: \(preferences.count) categories")
            } catch {
                print("❌ Error loading preferences: \(error)")
                initializeDefaultPreferences()
            }
        } else {
            print("ℹ️ No saved preferences found, initializing defaults")
            initializeDefaultPreferences()
        }
    }
    
    private func initializeDefaultPreferences() {
        let defaultScore = 5.0
        PlaceCategory.allCases.forEach { category in
            preferences[category] = UserPreference(
                category: category,
                score: defaultScore,
                lastUpdated: Date(),
                interactionCount: 0
            )
        }
        savePreferences()
    }
    
    private func savePreferences() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(preferences)
            userDefaults.set(data, forKey: preferencesKey)
        } catch {
            print("❌ Error saving preferences: \(error)")
        }
    }
    
    // MARK: - User Behavior Tracking
    
    private func loadBehaviorHistory() {
        if let data = userDefaults.data(forKey: behaviorKey) {
            do {
                let decoder = JSONDecoder()
                self.behaviorHistory = try decoder.decode([UserBehavior].self, from: data)
                print("📊 Loaded behavior history: \(behaviorHistory.count) entries")
            } catch {
                print("❌ Error loading behavior history: \(error)")
            }
        }
    }
    
    private func saveBehaviorHistory() {
        // Limit history size
        if behaviorHistory.count > 500 {
            behaviorHistory = Array(behaviorHistory.suffix(500))
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(behaviorHistory)
            userDefaults.set(data, forKey: behaviorKey)
        } catch {
            print("❌ Error saving behavior history: \(error)")
        }
    }
    
    /// Record a user interaction with a place
    func recordPlaceInteraction(place: Place, query: String, interactionDuration: TimeInterval = 30.0) {
        let calendar = Calendar.current
        let now = Date()
        
        let behavior = UserBehavior(
            searchQuery: query,
            selectedPlace: place.id.uuidString,
            category: place.category,
            timeOfDay: calendar.component(.hour, from: now),
            dayOfWeek: calendar.component(.weekday, from: now),
            location: UserLocation(
                latitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude
            ),
            duration: interactionDuration,
            timestamp: now
        )
        
        // Add to history
        behaviorHistory.append(behavior)
        saveBehaviorHistory()
        
        // Update preference score
        updatePreference(for: place.category)
    }
    
    /// Update preference score for a category based on user interaction
    private func updatePreference(for category: PlaceCategory) {
        // Get or create preference
        let preference = preferences[category] ?? UserPreference(
            category: category,
            score: 5.0,
            lastUpdated: Date(),
            interactionCount: 0
        )
        
        // Create updated preference with increased score and count
        let newScore = min(10.0, preference.score + 0.5)
        preferences[category] = UserPreference(
            category: category,
            score: newScore,
            lastUpdated: Date(),
            interactionCount: preference.interactionCount + 1
        )
        
        // Decrease scores for other categories slightly
        for otherCategory in PlaceCategory.allCases where otherCategory != category {
            if let otherPref = preferences[otherCategory] {
                // Slight decay for non-interacted categories
                let decayedScore = max(1.0, otherPref.score * 0.98)
                preferences[otherCategory] = UserPreference(
                    category: otherCategory,
                    score: decayedScore,
                    lastUpdated: otherPref.lastUpdated,
                    interactionCount: otherPref.interactionCount
                )
            }
        }
        
        savePreferences()
    }
    
    /// Reset user preferences and history
    func resetUserData() {
        print("�� Resetting user preferences and behavior history")
        preferences.removeAll()
        behaviorHistory.removeAll()
        userDefaults.removeObject(forKey: preferencesKey)
        userDefaults.removeObject(forKey: behaviorKey)
        initializeDefaultPreferences()
    }
    
    // MARK: - Location Familiarity
    
    /// Calculate how familiar a user is with a location (0.0 - 1.0)
    func getLocationFamiliarityScore(coordinate: CLLocationCoordinate2D) -> Double {
        // Count nearby recorded behaviors
        let nearbyThreshold = 1000.0 // meters
        let nearbyBehaviors = behaviorHistory.filter { behavior in
            let behaviorLocation = CLLocation(
                latitude: behavior.location.latitude,
                longitude: behavior.location.longitude
            )
            let userLocation = CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            return behaviorLocation.distance(from: userLocation) < nearbyThreshold
        }
        
        // Normalize score between 0 and 1
        let count = Double(nearbyBehaviors.count)
        return min(1.0, count / 50.0) // 50+ visits is considered fully familiar
    }
    
    /// Get previous interaction score for a category
    private func getPreviousInteractionScore(for category: PlaceCategory) -> Double {
        return preferences[category]?.score ?? 0.5
    }
    
    // MARK: - Place Ranking
    
    /// Use simple ML-inspired heuristics to rank places by user preference
    nonisolated func analyzeAndRankPlaces(_ places: [Place], userLocation: CLLocationCoordinate2D, currentTime: Date = Date()) async -> [Place] {
        await MainActor.run {
            self.isLoading = true
        }
        
        defer {
            Task { @MainActor in 
                self.isLoading = false
            }
        }
        
        return await MainActor.run {
            let calendar = Calendar.current
            let timeOfDay = calendar.component(.hour, from: currentTime)
            let dayOfWeek = calendar.component(.weekday, from: currentTime)
            
            // Create user context for preference ranking
            let userContext = UserContext(
                timeOfDay: timeOfDay,
                dayOfWeek: dayOfWeek,
                weatherCondition: .unknown, // Would be fetched from weather API
                locationFamiliarity: Float(getLocationFamiliarityScore(coordinate: userLocation)),
                currentActivity: .leisure // Would be inferred from context
            )
            
            // Use our simple ranking model
            let rankedPlaces = self.rankPlacesUsingHeuristics(
                places: places,
                userContext: userContext
            )
            
            print("🧠 ML-Heuristic ranked \(rankedPlaces.count) places")
            if let firstPlace = rankedPlaces.first {
                print("🔝 Top recommendation: \(firstPlace.name)")
            }
            
            return rankedPlaces
        }
    }
    
    /// Simple heuristic-based place ranking
    private func rankPlacesUsingHeuristics(places: [Place], userContext: UserContext) -> [Place] {
        // Calculate scores for each place based on user preferences and context
        let scoredPlaces = places.map { place -> (place: Place, score: Double) in
            var score: Double = 50.0  // Base score
            
            // Factor 1: User preference for this category
            if let preference = preferences[place.category] {
                score += preference.score * 30.0
            }
            
            // Factor 2: Distance (closer is better)
            if let distance = place.distance {
                // Normalize distance score (0-20 points)
                // Lower distances get higher scores
                let distanceScore = max(0, 20 - min(20, Double(distance) / 300.0))
                score += distanceScore
            }
            
            // Factor 3: Time of day appropriateness (0-15 points)
            score += getTimeAppropriatenessScore(for: place.category, hour: userContext.timeOfDay)
            
            // Factor 4: Rating (0-15 points)
            if let rating = place.rating {
                score += Double(rating) * 3.0
            }
            
            return (place, score)
        }
        
        // Sort by score (highest first) and return just the places
        return scoredPlaces.sorted { $0.score > $1.score }.map { $0.place }
    }
    
    /// Get score for how appropriate a category is for a given hour (0-15)
    private func getTimeAppropriatenessScore(for category: PlaceCategory, hour: Int) -> Double {
        switch category {
        case .food:
            if (7...10).contains(hour) || (12...14).contains(hour) || (17...21).contains(hour) {
                return 15.0 // Peak meal times
            }
            return 5.0
        case .coffee:
            if (6...11).contains(hour) || (14...16).contains(hour) {
                return 15.0 // Morning and afternoon coffee times
            }
            return 5.0
        case .shopping:
            if (10...19).contains(hour) {
                return 15.0 // Standard shopping hours
            }
            return 0.0
        default:
            return 7.5 // Neutral score for other categories
        }
    }
    
    /// Enhanced ML-based place analysis with recommendations
    func analyzeAndRankPlacesWithRecommendations(
        _ places: [Place],
        userLocation: CLLocationCoordinate2D,
        currentTime: Date = Date()
    ) async -> [PlaceRecommendation] {
        isLoading = true
        defer { isLoading = false }
        
        let calendar = Calendar.current
        let timeOfDay = calendar.component(.hour, from: currentTime)
        let dayOfWeek = calendar.component(.weekday, from: currentTime)
        
        let userContext = UserContext(
            timeOfDay: timeOfDay,
            dayOfWeek: dayOfWeek,
            weatherCondition: .unknown,
            locationFamiliarity: Float(getLocationFamiliarityScore(coordinate: userLocation)),
            currentActivity: .leisure
        )
        
        // Use our heuristic-based recommendations
        let recommendations = generatePlaceRecommendations(places: places, userLocation: userLocation)
        
        print("🎯 Generated \(recommendations.count) recommendations")
        
        return recommendations
    }
    
    /// Generate recommendations for places
    func generatePlaceRecommendations(places: [Place], userLocation: CLLocationCoordinate2D) -> [PlaceRecommendation] {
        let calendar = Calendar.current
        let currentTime = Date()
        let timeOfDay = calendar.component(.hour, from: currentTime)
        let dayOfWeek = calendar.component(.weekday, from: currentTime)
        
        // Context not used directly, but would be useful for future enhancements
        let _ = UserContext(
            timeOfDay: timeOfDay,
            dayOfWeek: dayOfWeek,
            weatherCondition: .unknown,
            locationFamiliarity: Float(getLocationFamiliarityScore(coordinate: userLocation)),
            currentActivity: .leisure
        )
        
        // Use our simple ranking model
        let scoredPlaces = places.map { place -> PlaceRecommendation in
            var score: Float = 50.0  // Base score
            var factors: [String] = []
            
            // Factor 1: User preference for this category
            if let preference = preferences[place.category] {
                let preferencePoints = Float(preference.score * 30.0)
                score += preferencePoints
                if preferencePoints > 20 {
                    factors.append("You frequently visit \(place.category.rawValue) places")
                }
            }
            
            // Factor 2: Distance (closer is better)
            if let distance = place.distance {
                // Normalize distance score (0-20 points)
                // Lower distances get higher scores
                let distanceScore = Float(max(0, 20 - min(20, Double(distance) / 300.0)))
                score += distanceScore
                
                if distance < 500 {
                    factors.append("Very close to your location (\(Int(distance))m)")
                } else if distance < 1000 {
                    factors.append("Walking distance (\(Int(distance))m)")
                }
            }
            
            // Factor 3: Time appropriateness
            let timeScore = Float(getTimeAppropriatenessScore(for: place.category, hour: timeOfDay))
            score += timeScore
            
            if timeScore > 10 {
                let period: String
                if (6...11).contains(timeOfDay) {
                    period = "morning"
                } else if (12...16).contains(timeOfDay) {
                    period = "afternoon"
                } else if (17...21).contains(timeOfDay) {
                    period = "evening"
                } else {
                    period = "late hours"
                }
                factors.append("Perfect for \(period)")
            }
            
            // Factor 4: Rating
            if let rating = place.rating {
                let ratingScore = Float(rating) * 3.0
                score += ratingScore
                
                if rating >= 4.5 {
                    factors.append("Highly rated (\(rating))")
                } else if rating >= 4.0 {
                    factors.append("Well rated (\(rating))")
                }
            }
            
            // Ensure we have at least one factor
            if factors.isEmpty {
                factors.append("Matches your preferences")
            }
            
            return PlaceRecommendation(place: place, score: score, reasoningFactors: factors)
        }
        
        // Sort by score (highest first)
        return scoredPlaces.sorted { $0.score > $1.score }
    }
}
