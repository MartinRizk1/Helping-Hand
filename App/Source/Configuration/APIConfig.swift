import Foundation

enum APIConfig {
    static var openAIApiKey: String {
        // First try environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Try loading from local config file (not committed to git)
        if let configKey = loadAPIKeyFromFile() {
            return configKey
        }
        
        // Fallback - show error and return placeholder
        print("⚠️ OpenAI API key not configured!")
        print("📝 Please set your API key using one of these methods:")
        print("   1. Environment variable: export OPENAI_API_KEY='your-key-here'")
        print("   2. Create Config/secrets.json with your API key")
        print("   3. Get your API key from: https://platform.openai.com/api-keys")
        
        return "your-openai-api-key-here"
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
