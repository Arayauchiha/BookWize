import SwiftUICore

struct MainContentView: View {
    @State private var showLogin = false
    
    var body: some View {
        // Your main content view
        ContentView()
            .sheet(isPresented: $showLogin) {
                LoginView(userRole: .member)
            }
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("ShowLogin"),
                    object: nil,
                    queue: .main
                ) { _ in
                    showLogin = true
                }
            }
    }
} 
