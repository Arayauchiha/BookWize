import SwiftUI

struct LibrarianDashboardScreen: View {
    @AppStorage("isLibrarianLoggedIn") private var isLoggedIn = false
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
                LoginView(userRole: .librarian)
            }
        }
    }
}
