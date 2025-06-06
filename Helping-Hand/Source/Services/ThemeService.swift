import Foundation
import SwiftUI
import Combine

class ThemeService: ObservableObject {
    // Singleton instance
    static let shared = ThemeService()
    
    // Theme options
    enum ColorTheme: String, CaseIterable, Identifiable {
        case system
        case light
        case dark
        
        var id: String { self.rawValue }
        
        var name: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }
    
    // Published properties
    @Published var currentTheme: ColorTheme
    @Published var accentColor: Color
    
    // Default colors
    private let defaultAccentColor = Color("AccentColor")
    
    // Keys for UserDefaults
    private enum Keys {
        static let theme = "app_theme"
        static let accentColorR = "accent_color_r"
        static let accentColorG = "accent_color_g"
        static let accentColorB = "accent_color_b"
    }
    
    init() {
        // Load saved theme preference
        if let savedTheme = UserDefaults.standard.string(forKey: Keys.theme),
           let theme = ColorTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }
        
        // Load accent color if available
        if UserDefaults.standard.object(forKey: Keys.accentColorR) != nil {
            let r = UserDefaults.standard.double(forKey: Keys.accentColorR)
            let g = UserDefaults.standard.double(forKey: Keys.accentColorG)
            let b = UserDefaults.standard.double(forKey: Keys.accentColorB)
            self.accentColor = Color(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
        } else {
            self.accentColor = defaultAccentColor
        }
    }
    
    // Set and persist theme preference
    func setTheme(_ theme: ColorTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme)
    }
    
    // Set and persist accent color
    func setAccentColor(_ color: Color) {
        accentColor = color
        
        // Convert Color to UIColor to access RGB components
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // Save to UserDefaults
        UserDefaults.standard.set(r, forKey: Keys.accentColorR)
        UserDefaults.standard.set(g, forKey: Keys.accentColorG)
        UserDefaults.standard.set(b, forKey: Keys.accentColorB)
    }
    
    // Reset to default accent color
    func resetToDefaultColor() {
        accentColor = defaultAccentColor
        
        // Remove saved values
        UserDefaults.standard.removeObject(forKey: Keys.accentColorR)
        UserDefaults.standard.removeObject(forKey: Keys.accentColorG)
        UserDefaults.standard.removeObject(forKey: Keys.accentColorB)
    }
}
