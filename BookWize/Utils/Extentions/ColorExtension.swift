import SwiftUI

extension Color {
    // System adaptive colors that respond to dark/light mode
    static let customBackground = Color(.systemGroupedBackground)
    static let customCardBackground = Color(.secondarySystemGroupedBackground)
    static let customInputBackground = Color(.systemBackground)
    static let customText = Color(.label)
    
    // Bright vibrant colors that work well in both light and dark modes
    static let memberColor = Color(hexString: "0078D7")      // Bright azure blue
    static let librarianColor = Color(hexString: "0091EA")   // Bright sky blue
    static let adminColor = Color(hexString: "005FB8")       // Bright royal blue
    
    // Use the bright blue as the main button color
    static let customButtonColor = Color(hexString: "0078D7")
    
    // For backward compatibility
    static let customButton = customButtonColor
    
    static let iconBackgroundOpacity: Double = 0.15
    static let secondaryIconOpacity: Double = 0.6
    
    // Hex color initializer
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
