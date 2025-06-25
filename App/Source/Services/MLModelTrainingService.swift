import Foundation
import CoreML
#if os(macOS)
import CreateML
import TabularData
#endif
import CoreLocation

/// ML Model Training and Management Service
/// Responsible for training and updating Core ML models based on user behavior
class MLModelTrainingService {
    
    // MARK: - Properties
    
    // Remove direct dependency to avoid circular references
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    // Training data storage
    private var trainingDataQueue: [MLTrainingExample] = []
    private let maxTrainingExamples = 10000
    
    // Model update thresholds
    private let minExamplesForTraining = 100
    private let modelUpdateInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    // MARK: - Training Data Models
    
    struct MLTrainingExample: Codable {
        let features: MLFeatureVector
        let label: Float
        let timestamp: Date
        var context: TrainingContext
    }
    
    struct MLFeatureVector: Codable {
        let timeOfDay: Double
        let dayOfWeek: Double
        let categoryEncoding: [Double]
        let distance: Double
        let rating: Double
        let userPreferenceScore: Double
        let locationFamiliarity: Double
        let weatherCondition: Double
        let activityType: Double
    }
    
    struct TrainingContext: Codable {
        let userId: String
        let sessionId: String
        let queryType: String
        let interactionType: String // view, select, call, navigate
    }
    
    // MARK: - Initialization
    
    init() {
        setupMLTraining()
        loadTrainingData()
    }
    
    private func setupMLTraining() {
        print("🎓 ML Training Service initialized")
        print("📊 Training data will be stored at: \(documentsPath)")
    }
    
    // MARK: - Data Collection
    
    /// Collect training data from user interactions
    func recordUserInteraction(
        place: Place,
        userLocation: CLLocationCoordinate2D,
        interactionType: String,
        userContext: UserContext,
        interactionDuration: TimeInterval
    ) {
        let features = extractMLFeatures(
            place: place,
            userLocation: userLocation,
            userContext: userContext
        )
        
        // Convert interaction quality to training label (0.0 to 1.0)
        let label = calculateInteractionLabel(
            interactionType: interactionType,
            duration: interactionDuration,
            place: place
        )
        
        let trainingExample = MLTrainingExample(
            features: features,
            label: label,
            timestamp: Date(),
            context: TrainingContext(
                userId: getUserId(),
                sessionId: getSessionId(),
                queryType: determineQueryType(place: place),
                interactionType: interactionType
            )
        )
        
        addTrainingExample(trainingExample)
        
        print("📝 Recorded ML training example: \(interactionType) with label \(label)")
    }
    
    private func extractMLFeatures(
        place: Place,
        userLocation: CLLocationCoordinate2D,
        userContext: UserContext
    ) -> MLFeatureVector {
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let placeCLLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        let distance = userCLLocation.distance(from: placeCLLocation)
        
        return MLFeatureVector(
            timeOfDay: Double(userContext.timeOfDay) / 24.0,
            dayOfWeek: Double(userContext.dayOfWeek) / 7.0,
            categoryEncoding: encodePlaceCategory(place.category),
            distance: min(distance / 10000.0, 1.0), // Normalize to 10km
            rating: (place.rating ?? 3.0) / 5.0,
            userPreferenceScore: getUserPreferenceScore(for: place.category),
            locationFamiliarity: userContext.locationFamiliarity,
            weatherCondition: Double(userContext.weatherCondition.rawValue) / Double(WeatherCondition.allCases.count),
            activityType: Double(userContext.currentActivity.rawValue) / Double(UserActivity.allCases.count)
        )
    }
    
    private func calculateInteractionLabel(
        interactionType: String,
        duration: TimeInterval,
        place: Place
    ) -> Float {
        var baseScore: Float = 0.5
        
        // Score based on interaction type
        switch interactionType.lowercased() {
        case "view":
            baseScore = 0.3
        case "select":
            baseScore = 0.6
        case "call":
            baseScore = 0.8
        case "navigate":
            baseScore = 0.9
        case "bookmark":
            baseScore = 0.85
        default:
            baseScore = 0.4
        }
        
        // Adjust based on interaction duration
        let durationScore = min(Float(duration / 60.0), 1.0) // Max 1 minute
        let adjustedScore = (baseScore + durationScore * 0.3) / 1.3
        
        return min(max(adjustedScore, 0.0), 1.0)
    }
    
    // MARK: - Model Training
    
    /// Train a new Core ML model based on collected data
    func trainPreferenceModel() async throws -> MLModel? {
        #if os(macOS)
        guard trainingDataQueue.count >= minExamplesForTraining else {
            throw MLTrainingError.insufficientData(required: minExamplesForTraining, available: trainingDataQueue.count)
        }
        
        print("🎓 Starting ML model training with \(trainingDataQueue.count) examples...")
        
        // Prepare training data
        guard let trainingData = prepareTrainingData() else {
            throw MLTrainingError.trainingFailed("Failed to prepare training data")
        }
        
        // Create and train the model using CreateML
        let regressor = try CreateML.MLRegressor(trainingData: trainingData as! TabularData.MLDataTable, targetColumn: "label")
        
        print("✅ Model training completed successfully")
        
        // Save the trained model
        let modelURL = documentsPath.appendingPathComponent("user_preference_model.mlmodel")
        try regressor.write(to: modelURL)
        
        print("💾 Model saved to: \(modelURL.path)")
        
        return regressor.model
        #else
        // On iOS, training is not supported - would need to be done on server or macOS
        print("⚠️ Model training is only supported on macOS. Use server-side training for iOS.")
        throw MLTrainingError.trainingFailed("Training not supported on iOS platform")
        #endif
    }
    
    /// Check if model should be retrained based on new data
    func shouldRetrainModel() -> Bool {
        let lastTrainingDate = UserDefaults.standard.object(forKey: "lastMLTrainingDate") as? Date ?? Date.distantPast
        let timeSinceLastTraining = Date().timeIntervalSince(lastTrainingDate)
        
        let hasEnoughNewData = trainingDataQueue.count >= minExamplesForTraining
        let hasBeenLongEnough = timeSinceLastTraining > modelUpdateInterval
        
        return hasEnoughNewData && hasBeenLongEnough
    }
    
    /// Automatically retrain model if conditions are met
    func autoRetrainIfNeeded() async {
        guard shouldRetrainModel() else {
            print("🎓 Model retraining not needed yet")
            return
        }
        
        do {
            let newModel = try await trainPreferenceModel()
            
            // Update the last training date
            UserDefaults.standard.set(Date(), forKey: "lastMLTrainingDate")
            
            print("🚀 Model automatically retrained and updated")
            
            // Notify other services about the new model
            NotificationCenter.default.post(
                name: .mlModelUpdated,
                object: newModel
            )
            
        } catch {
            print("❌ Auto-retraining failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Data Management
    
    private func addTrainingExample(_ example: MLTrainingExample) {
        trainingDataQueue.append(example)
        
        // Keep only the most recent examples to prevent memory issues
        if trainingDataQueue.count > maxTrainingExamples {
            trainingDataQueue.removeFirst(trainingDataQueue.count - maxTrainingExamples)
        }
        
        // Periodically save training data
        if trainingDataQueue.count % 50 == 0 {
            saveTrainingData()
        }
    }
    
    #if os(macOS)
    private func prepareTrainingData() -> TabularData.MLDataTable? {
        var features: [[String: MLFeatureValue]] = []
        
        for example in trainingDataQueue {
            var featureDict: [String: MLFeatureValue] = [:]
            
            featureDict["timeOfDay"] = MLFeatureValue(double: example.features.timeOfDay)
            featureDict["dayOfWeek"] = MLFeatureValue(double: example.features.dayOfWeek)
            featureDict["distance"] = MLFeatureValue(double: example.features.distance)
            featureDict["rating"] = MLFeatureValue(double: example.features.rating)
            featureDict["userPreferenceScore"] = MLFeatureValue(double: example.features.userPreferenceScore)
            featureDict["locationFamiliarity"] = MLFeatureValue(double: example.features.locationFamiliarity)
            featureDict["weatherCondition"] = MLFeatureValue(double: example.features.weatherCondition)
            featureDict["activityType"] = MLFeatureValue(double: example.features.activityType)
            featureDict["label"] = MLFeatureValue(double: Double(example.label))
            
            // Add category encoding as separate features
            for (index, value) in example.features.categoryEncoding.enumerated() {
                featureDict["category_\(index)"] = MLFeatureValue(double: value)
            }
            
            features.append(featureDict)
        }
        
        return try! TabularData.MLDataTable(dictionary: Dictionary(uniqueKeysWithValues: 
            features.first?.keys.map { key in
                (key, features.map { $0[key]! })
            } ?? []
        ))
    }
    #else
    private func prepareTrainingData() -> Any? {
        print("⚠️ Training data preparation only available on macOS")
        return nil
    }
    #endif
    
    // MARK: - Helper Methods
    
    private func encodePlaceCategory(_ category: PlaceCategory) -> [Double] {
        var encoding = Array(repeating: 0.0, count: PlaceCategory.allCases.count)
        if let index = PlaceCategory.allCases.firstIndex(of: category) {
            encoding[index] = 1.0
        }
        return encoding
    }
    
    private func getUserPreferenceScore(for category: PlaceCategory) -> Double {
        // Return default neutral preference - in production this would come from UserPreferenceService
        // but we avoid circular dependency by using a default value
        return 0.5
    }
    
    private func getUserId() -> String {
        // Generate or retrieve anonymous user ID
        if let userId = UserDefaults.standard.string(forKey: "anonymousUserId") {
            return userId
        } else {
            let newUserId = UUID().uuidString
            UserDefaults.standard.set(newUserId, forKey: "anonymousUserId")
            return newUserId
        }
    }
    
    private func getSessionId() -> String {
        return UUID().uuidString
    }
    
    private func determineQueryType(place: Place) -> String {
        return place.category.rawValue.lowercased()
    }
    
    // MARK: - Data Persistence
    
    private func saveTrainingData() {
        let trainingDataURL = documentsPath.appendingPathComponent("training_data.json")
        
        do {
            let data = try JSONEncoder().encode(trainingDataQueue)
            try data.write(to: trainingDataURL)
            print("💾 Training data saved (\(trainingDataQueue.count) examples)")
        } catch {
            print("❌ Failed to save training data: \(error.localizedDescription)")
        }
    }
    
    private func loadTrainingData() {
        let trainingDataURL = documentsPath.appendingPathComponent("training_data.json")
        
        guard FileManager.default.fileExists(atPath: trainingDataURL.path) else {
            print("📊 No existing training data found")
            return
        }
        
        do {
            let data = try Data(contentsOf: trainingDataURL)
            trainingDataQueue = try JSONDecoder().decode([MLTrainingExample].self, from: data)
            print("📊 Loaded \(trainingDataQueue.count) training examples")
        } catch {
            print("❌ Failed to load training data: \(error.localizedDescription)")
        }
    }
    
    /// Export anonymized training data for external model training
    func exportTrainingData() -> Data? {
        // Remove personally identifiable information
        let anonymizedData = trainingDataQueue.map { example in
            var anonymized = example
            anonymized.context = TrainingContext(
                userId: "anonymous",
                sessionId: "anonymous",
                queryType: example.context.queryType,
                interactionType: example.context.interactionType
            )
            return anonymized
        }
        
        do {
            return try JSONEncoder().encode(anonymizedData)
        } catch {
            print("❌ Failed to export training data: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Error Types

enum MLTrainingError: Error, LocalizedError {
    case insufficientData(required: Int, available: Int)
    case trainingFailed(String)
    case modelSaveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .insufficientData(let required, let available):
            return "Insufficient training data. Required: \(required), Available: \(available)"
        case .trainingFailed(let message):
            return "Model training failed: \(message)"
        case .modelSaveFailed(let message):
            return "Failed to save model: \(message)"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let mlModelUpdated = Notification.Name("MLModelUpdated")
}
