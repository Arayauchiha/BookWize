import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
                VStack(spacing: 20) {
                    // Logo and title - reduced top padding
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(Color.customButton)
                        
                        Text("Welcome to")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(Color.customText)
                        
                        Text("BookWize")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Color.customText)
                    }
                    .padding(.top, 20)
                    
                    // Feature list - more compact
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(
                            icon: "book.circle.fill",
                            title: "Seamless Library Access",
                            description: "Smart card entry & effortless book checkouts."
                        )
                        
                        FeatureRow(
                            icon: "magnifyingglass.circle.fill",
                            title: "Reserve & Track",
                            description: "Hold books in advance & log your reading journey."
                        )
                        
                        FeatureRow(
                            icon: "chart.bar.fill",
                            title: "Paperless & Efficient",
                            description: "Digital records, automated fines, and zero manual hassle."
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 15)
                    
                    // Bottom section with people icon and disclaimer text
                    VStack(spacing: 10) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.customButton)
                        
                        Text("BookWize helps you manage your library experience with quick reservations, hassle-free borrowing, and a smarter way to track your reads.")
                            .font(.caption)
                            .foregroundColor(Color.customText.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 5)
                    
                    // Continue button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            hasSeenOnboarding = true
                            dismiss()
                        }
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.customButton)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
                .padding(.vertical, 20)
            }
            .background(Color.customBackground)
            .navigationBarTitleDisplayMode(.inline)
        
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .presentationBackground(colorScheme == .dark ? .black : .white)
        .interactiveDismissDisabled()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon - slightly smaller for better fit
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(Color.customButton)
                .frame(width: 36, height: 36)
                .background(Color.customButton.opacity(0.1))
                .clipShape(Circle())
            
            // Title and description
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.customText)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color.customText.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingView()
                .previewDisplayName("Light Mode")
            
            OnboardingView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
