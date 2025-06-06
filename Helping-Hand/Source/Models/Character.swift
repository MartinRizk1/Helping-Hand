import Foundation
import SwiftUI

struct Character: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let animations: [String: [UIImage]]
    
    enum Mood: String {
        case neutral
        case happy
        case thinking
        case helping
    }
    
    func getAnimation(for mood: Mood) -> [UIImage] {
        return animations[mood.rawValue] ?? []
    }
    
    static let defaultCharacter = Character(
        name: "Helper",
        imageName: "helper_neutral",
        animations: [
            Mood.neutral.rawValue: [], // Will be populated with actual images
            Mood.happy.rawValue: [],
            Mood.thinking.rawValue: [],
            Mood.helping.rawValue: []
        ]
    )
}
