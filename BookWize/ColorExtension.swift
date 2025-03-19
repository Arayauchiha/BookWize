import SwiftUI

extension Color {
    static let customBackground = Color(hex: "F5EBE0")  // Light beige
    static let customCardBackground = Color(hex: "F8F1E9")  // Card background
    static let customInputBackground = Color(hex: "FFFFFF")  // Input background (White)
    static let customText = Color(hex: "463F3A")  // Text color
    static let customButton = Color(hex: "2C1810")  // Button color (Dark brown)
    
    static let memberColor = Color(hex: "007AFF")  // Blue
    static let librarianColor = Color(hex: "34C759")  // Green
    static let adminColor = Color(hex: "AF52DE")  // Purple
    
    static let iconBackgroundOpacity: Double = 0.15
    static let secondaryIconOpacity: Double = 0.6
    
}

private extension Color {
    init(hex: String) {
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
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// End of file
