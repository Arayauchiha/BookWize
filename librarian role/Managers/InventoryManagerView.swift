import SwiftUI

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
                    
                    UserManagementView()
                        .tabItem {
                            Label("Members", systemImage: "person.2.fill")
                        }
                    
                    FineManagementView()
                        .tabItem {
                            Label("Fines", systemImage: "dollarsign.circle.fill")
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
                .sheet(isPresented: $showingLoginSheet) {
                    LoginViews(isLoggedIn: $isLoggedIn)
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



struct LoginViews: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isLoggedIn: Bool
    @State private var username = ""
    @State private var password = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FCFCFC").ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.primaryColor)
                        .padding(.top, 40)
                    
                    VStack(spacing: 20) {
                        CustomTextField(text: $username,
                                     placeholder: "Username",
                                     systemImage: "person.fill")
                        
                        CustomSecureField(text: $password,
                                        placeholder: "Password",
                                        systemImage: "lock.fill")
                    }
                    .padding(.horizontal, 30)
                    
                    Button(action: {
                        if UserDefaultsManager.shared.validateCredentials(username: username, password: password) {
                            isLoggedIn = true
                            dismiss()
                        } else {
                            showingError = true
                        }
                    }) {
                        Text("Login")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: 54)
                            .background(
                                username.isEmpty || password.isEmpty ?
                                Color(hex: "BDC3C7") :
                                AppTheme.primaryColor
                            )
                            .cornerRadius(12)
                    }
                    .disabled(username.isEmpty || password.isEmpty)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle("Librarian Login")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Invalid Credentials", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please check your username and password")
            }
        }
    }
}


// Custom UI Components
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(Color(hex: "7F8C8D"))
                .frame(width: 24)
            TextField(placeholder, text: $text)
                .autocapitalization(.none)
            
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "E5E5E5"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(Color(hex: "7F8C8D"))
                .frame(width: 24)
            SecureField(placeholder, text: $text)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "E5E5E5"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
