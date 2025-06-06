import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // Set to true during development to use mock data and bypass real location services
    static let isTestMode = true
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Print test mode status
        if AppDelegate.isTestMode {
            print("⚠️ APP RUNNING IN TEST MODE - Using mock data ⚠️")
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
    }
}
