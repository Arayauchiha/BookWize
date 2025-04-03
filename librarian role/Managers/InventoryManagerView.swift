import SwiftUI

let SHOW_FINES = true // MAKE THIS TRUE - SPRINT - 2: Isko true kiya toh sara maal wapais aa jayega - @rtk-rnjn

struct InventoryManagerView: View {
    @State private var isLoggedIn = true
    @State private var showingLoginSheet = false
    @State private var showingLogoutAlert = false
    @State private var showProfile = false
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().standardAppearance = appearance
    }
    
    var body: some View {
        Group {
            if isLoggedIn {
                TabView {
                    // Dashboard Tab
                    NavigationView {
                        LibrarianDashboard()
                            .navigationBarItems(trailing: profileButton)
                            .navigationTitle("Dashboard")
                            .navigationBarTitleDisplayMode(.large)
                    }
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }
                    .tag(0)
                    
                    // Inventory Tab
                    NavigationView {
                        InventoryView()
                            .navigationBarItems(trailing: profileButton)
                            .navigationTitle("Inventory")
                            .navigationBarTitleDisplayMode(.large)
                    }
                    .tabItem {
                        Label("Inventory", systemImage: "books.vertical.fill")
                    }
                    .tag(1)
                    
                    // Circulation Tab
                    NavigationView {
                        BookCirculationView()
                            .navigationBarItems(trailing: profileButton)
                            .navigationTitle("Circulation")
                            .navigationBarTitleDisplayMode(.large)
                    }
                    .tabItem {
                        Label("Circulation", systemImage: "arrow.left.arrow.right.circle.fill")
                    }
                    .tag(2)
                    
                    // Members Tab
                    NavigationView {
                        MembersListView()
                            .navigationBarItems(trailing: profileButton)
                            .navigationTitle("Members")
                            .navigationBarTitleDisplayMode(.large)
                    }
                    .tabItem {
                        Label("Members", systemImage: "person.2.fill")
                    }
                    .tag(3)
                }
                .tint(.blue)
                .sheet(isPresented: $showProfile) {
                    NavigationView {
                        AccountView(isLoggedIn: $isLoggedIn)
                            .navigationTitle("Profile")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .presentationDragIndicator(.visible)
                }
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
    
    private var profileButton: some View {
        Button(action: { showProfile = true }) {
            Image(systemName: "person.circle")
                .font(.system(size: 22))
                .foregroundColor(Color.customButton)
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
    InventoryManagerView()
}
