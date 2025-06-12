import Foundation

enum APIConfig {
    private static let apiKeyKey = "OPENAI_API_KEY"
    
    static var openAIKey: String {
        // First try environment variable
        if let key = ProcessInfo.processInfo.environment[apiKeyKey], !key.isEmpty {
            return key
        }
        
        // Try loading from local config file (gitignored)
        if let configKey = loadAPIKeyFromFile(), !configKey.isEmpty {
            return configKey
        }
        
        // Return placeholder instead of crashing - app will use fallback responses
        print("⚠️ OpenAI API key not found. App will use fallback responses.")
        return "your-openai-api-key-here"
    }
    
    private static func loadAPIKeyFromFile() -> String? {
        guard let path = Bundle.main.path(forResource: "secrets", ofType: "json", inDirectory: "Config"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let apiKey = json["OPENAI_API_KEY"] as? String else {
            return nil
        }
        return apiKey
    }
}
