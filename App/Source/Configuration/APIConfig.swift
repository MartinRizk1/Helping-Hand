import Foundation

public enum APIConfig {
    private static let errorMessage = """
        ⚠️ OpenAI API key not configured!
        📝 Please set your API key using one of these methods:
           1. Environment variable: export OPENAI_API_KEY='your-key-here'
           2. Create Config/secrets.json with your API key
           3. Get your API key from: https://platform.openai.com/api-keys
        
        🔒 For security, AI features will be disabled until a valid API key is provided.
        """
    
    private static var hasLoggedError = false
    
    public static var openAIApiKey: String {
        // First try environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Try loading from local config file (not committed to git)
        if let configKey = loadAPIKeyFromFile() {
            return configKey
        }
        
        // Only log this error once
        if !hasLoggedError {
            Logger.error(errorMessage)
            hasLoggedError = true
        }
        
        // Return empty string to fail securely rather than a placeholder
        return ""
    }
    
    private static func loadAPIKeyFromFile() -> String? {
        guard let path = Bundle.main.path(forResource: "secrets", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let apiKey = json["openai_api_key"] as? String,
              !apiKey.isEmpty else {
            return nil
        }
        return apiKey
    }
}
