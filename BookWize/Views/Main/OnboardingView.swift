import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    private let totalPages = 4

    var body: some View {
        ZStack {
            Color.customBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                TabView(selection: $currentPage) {
                    OnboardingPage(imageName: "book.circle.fill", title: "Digital Collection Access", description: "Explore an extensive collection of digital and physical resources, right at your fingertips.")
                        .tag(0)
                    OnboardingPage(imageName: "magnifyingglass.circle.fill", title: "Smart Search & Reservation", description: "Effortlessly search, reserve, and borrow items with intelligent search and streamlined reservations.")
                        .tag(1)
                    OnboardingPage(imageName: "chart.bar.fill", title: "Dashboard Insights", description: "Access personalized dashboards for monitoring activity, managing resources, and tracking progress.")
                        .tag(2)
                    OnboardingPage(imageName: "bell.fill", title: "Stay Notified", description: "Receive instant updates on due dates, new arrivals, and important announcements.")
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
            }
            VStack {
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button("Skip") {
                            hasSeenOnboarding = true
                        }
                        .padding()
                        .foregroundColor(Color.customText)
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \..self) { index in
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(index == currentPage ? Color.customButton : Color.customText.opacity(0.3))
                    }
                }
                .padding(.bottom, 16)
                Button(action: {
                    if currentPage < totalPages - 1 {
                        currentPage += 1
                    } else {
                        hasSeenOnboarding = true
                    }
                }) {
                    Text(currentPage == totalPages - 1 ? "Get Started" : "Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.customButton)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage: View {
    var imageName: String
    var title: String
    var description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(Color.customText)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color.customText)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(Color.customText)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
