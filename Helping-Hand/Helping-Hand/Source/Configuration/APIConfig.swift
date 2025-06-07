import Foundation

enum APIConfig {
    static var openAIApiKey: String {
        // TODO: Replace with your OpenAI API key
        // In production, you should use a secure key management system
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }
}
