import SwiftUI

let SHOW_FINES = true // MAKE THIS TRUE - SPRINT - 2: Isko true kiya toh sara maal wapais aa jayega - @rtk-rnjn

struct InventoryManagerView: View {
    @State private var isLoggedIn = true
    @State private var showingLoginSheet = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            if isLoggedIn {
                // Main librarian interface
                TabView {
                    InventoryView()
                        .tabItem {
                            Label("Inventory", systemImage: "books.vertical.fill")
                        }
                    
                    BookCirculationView()
                        .tabItem {
                            Label("Circulation", systemImage: "arrow.left.arrow.right.circle.fill")
                        }
                    
                    MembersListView()
                        .tabItem {
                            Label("Members", systemImage: "person.2.fill")
                        }
                    
                    if SHOW_FINES {
                        LibrarianDashboard()
                            .tabItem {
                                Label("Dashboard", systemImage: "dollarsign.circle.fill")
                            }
                    }
                    
                    AccountView(isLoggedIn: $isLoggedIn)
                        .tabItem {
                            Label("Account", systemImage: "person.circle.fill")
                        }
                }
                .tint(AppTheme.primaryColor)
            } else {
                // Login screen
                ZStack {
                    Color(hex: "FCFCFC").ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        VStack(spacing: 15) {
                            Image(systemName: "books.vertical.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(AppTheme.primaryColor)
                                .padding()
                            
                            Text("Library Management")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppTheme.primaryColor)
                            
                            Text("Librarian Portal")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppTheme.secondaryTextColor)
                        }
                        
                        Button(action: { showingLoginSheet = true }) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                Text("Login as Librarian")
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: 280, maxHeight: 54)
                            .background(AppTheme.primaryColor)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                    }
                }
            }
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                isLoggedIn = false
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

// Color Extension for Hex Colors
extension Color {
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


struct UserManagementView: View {
    var body: some View {
        Text("User Management")
    }
}

#Preview {
    ContentView()
}
