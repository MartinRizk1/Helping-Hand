import Foundation
import UIKit
import Combine

class CharacterAnimationService {
    // Singleton instance for easy access
    static let shared = CharacterAnimationService()
    
    // Publisher for character animations
    private let animationsSubject = CurrentValueSubject<[String: [UIImage]], Never>([:])
    var animations: AnyPublisher<[String: [UIImage]], Never> {
        return animationsSubject.eraseToAnyPublisher()
    }
    
    // Set when images are loaded
    private(set) var isLoaded = false
    
    // Load animations (from assets or disk)
    func loadAnimations() {
        // In a real app, we would load animations from disk or assets
        // For now, we just provide the SF Symbol fallbacks
        
        let animations: [String: [UIImage]] = [:]
        
        // Publish the loaded animations
        animationsSubject.send(animations)
        isLoaded = true
        
        print("Character animations loaded (placeholder)")
    }
    
    // Generate SF Symbol fallbacks for each mood
    func getSFSymbolForMood(_ mood: Character.Mood, animated: Bool = false) -> UIImage {
        let symbolName: String
        
        switch mood {
        case .neutral:
            symbolName = "face.smiling"
        case .happy:
            symbolName = "face.smiling.fill"
        case .thinking:
            symbolName = "brain"
        case .helping:
            symbolName = "person.fill.checkmark"
        }
        
        let config = UIImage.SymbolConfiguration(pointSize: 120, weight: .regular)
        
        if animated, #available(iOS 15.0, *) {
            // In iOS 15+, we can use animated SF Symbols
            return UIImage(systemName: symbolName + ".fill", withConfiguration: config) ?? 
                   UIImage(systemName: symbolName, withConfiguration: config)!
        } else {
            return UIImage(systemName: symbolName, withConfiguration: config)!
        }
    }
    
    // Helper to get all symbols for a complete animation sequence
    func getAnimationFramesForMood(_ mood: Character.Mood) -> [UIImage] {
        // For each mood, create a simple 4-frame animation using SF Symbols
        // In a real app, these would be actual image assets
        
        switch mood {
        case .neutral:
            return [
                getSFSymbolForMood(.neutral),
                getSFSymbolForMood(.neutral)
            ]
        case .happy:
            return [
                getSFSymbolForMood(.happy),
                getSFSymbolForMood(.happy)
            ]
        case .thinking:
            if #available(iOS 15.0, *) {
                let config = UIImage.SymbolConfiguration(pointSize: 120, weight: .regular)
                let baseImage = UIImage(systemName: "brain", withConfiguration: config)!
                let activeImage = UIImage(systemName: "brain.head.profile", withConfiguration: config)!
                return [baseImage, activeImage, baseImage, activeImage]
            } else {
                return [getSFSymbolForMood(.thinking)]
            }
        case .helping:
            return [
                getSFSymbolForMood(.helping),
                getSFSymbolForMood(.happy),
                getSFSymbolForMood(.helping),
                getSFSymbolForMood(.neutral)
            ]
        }
    }
}
