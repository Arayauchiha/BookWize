import SwiftUI

enum AppTheme {
    static let primaryColor = Color("2C3E50")
    static let secondaryColor = Color("3498DB")
    static let accentColor = Color("E74C3C")
    static let backgroundColor = Color("FCFCFC")
    static let textColor = Color("2C3E50")
    static let secondaryTextColor = Color("7F8C8D")
    
    static let cornerRadius: CGFloat = 12
    static let padding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    
    static let shadowColor = Color.black.opacity(0.1)
    static let shadowRadius: CGFloat = 10
    static let shadowY: CGFloat = 5
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isEnabled ? AppTheme.primaryColor : AppTheme.secondaryTextColor)
                .cornerRadius(AppTheme.cornerRadius)
        }
        .disabled(!isEnabled)
    }
}

struct CardView: View {
    let content: AnyView
    
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .padding(AppTheme.padding)
            .background(Color.white)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: AppTheme.shadowColor,
                   radius: AppTheme.shadowRadius,
                   y: AppTheme.shadowY)
    }
} 
