import Foundation

enum APIConfig {
    private static let openAIKeyKey = "OPENAI_API_KEY"
    private static let googlePlacesKeyKey = "GOOGLE_PLACES_API_KEY"
    
    static var openAIKey: String {
        // First try environment variable
        if let key = ProcessInfo.processInfo.environment[openAIKeyKey], !key.isEmpty {
            return key
        }
        
        // Try loading from local config file (gitignored)
        if let configKey = loadAPIKeyFromFile(key: "OPENAI_API_KEY"), !configKey.isEmpty {
            return configKey
        }
        
        // Return placeholder instead of crashing - app will use fallback responses
        print("⚠️ OpenAI API key not found. App will use fallback responses.")
        return "your-openai-api-key-here"
    }
    
    static var googlePlacesKey: String {
        // First try environment variable
        if let key = ProcessInfo.processInfo.environment[googlePlacesKeyKey], !key.isEmpty {
            return key
        }
        
        // Try loading from local config file (gitignored)
        if let configKey = loadAPIKeyFromFile(key: "GOOGLE_PLACES_API_KEY"), !configKey.isEmpty {
            return configKey
        }
        
        // Return placeholder - app will use fallback to Apple Maps
        print("⚠️ Google Places API key not found. App will use Apple Maps fallback.")
        return "your-google-places-api-key-here"
    }
    
    
    private static func loadAPIKeyFromFile(key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "secrets", ofType: "json", inDirectory: "Config"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let apiKey = json[key] as? String else {
            return nil
        }
        return apiKey
    }
}
