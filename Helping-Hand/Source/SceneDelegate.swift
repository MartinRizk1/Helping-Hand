import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let persistenceService = PersistenceService()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Initialize services
        CharacterAnimationService.shared.loadAnimations()
        _ = ThemeService.shared // Initialize theme service
        
        // Track app launches
        persistenceService.incrementAppOpenCount()
        
        // Create view models
        let chatViewModel = ChatViewModel()
        let locationViewModel = LocationViewModel()
        
        // Create main view
        let contentView = MainView()
            .environmentObject(chatViewModel)
            .environmentObject(locationViewModel)
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
