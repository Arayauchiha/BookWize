import SwiftUI

extension Color {
    static let customBackground = Color(hex: "F2F2F7")  // iOS system background
    static let customCardBackground = Color(hex: "FFFFFF")  // iOS card background
    static let customInputBackground = Color(hex: "FFFFFF")  // Input background (White)
    static let customText = Color(hex: "1C1C1E")  // iOS dark text
    static let customButton = Color(hex: "003D5B")  // Dark blue
    
    // Role colors - variations of the theme color
    static let memberColor = Color(hex: "003D5B")  // Theme color
    static let librarianColor = Color(hex: "004D6D")  // Slightly lighter
    static let adminColor = Color(hex: "002D4D")  // Slightly darker
    
    static let iconBackgroundOpacity: Double = 0.15
    static let secondaryIconOpacity: Double = 0.6
}

// Proper initializer for hex colors
extension Color {
    func color(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        type(of: self).init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
