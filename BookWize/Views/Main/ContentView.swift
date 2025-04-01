import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("isAdminLoggedIn") private var isAdminLoggedIn = false
    @AppStorage("isLibrarianLoggedIn") private var isLibrarianLoggedIn = false
    @AppStorage("isMemberLoggedIn") private var isMemberLoggedIn = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            }
            else if isAdminLoggedIn {
                AdminDashboardView()
            } else if isLibrarianLoggedIn {
                //LibrarianDashboardScreen()
                InventoryManagerView()
            } else if isMemberLoggedIn {
                Search_BrowseApp()
            } else {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 32) {
                            // Header
                            VStack(spacing: 8) {
                                Text("Welcome to BookWize")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(Color.customText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Select your role to continue")
                                    .font(.system(size: 17))
                                    .foregroundStyle(Color.customText.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 50)
                            
                            // Role Cards
                            VStack(spacing: 12) {
                                NavigationLink {
                                    MemberLoginView()
                                } label: {
                                    RoleCard(
                                        title: "Member",
                                        icon: "person.fill",
                                        iconColor: Color.memberColor,
                                        cardColor: Color.customCardBackground
                                    )
                                }
                                
                                NavigationLink {
                                    LoginView(userRole: .librarian)
                                } label: {
                                    RoleCard(
                                        title: "Librarian",
                                        icon: "books.vertical.fill",
                                        iconColor: Color.librarianColor,
                                        cardColor: Color.customCardBackground
                                    )
                                }
                                
                                NavigationLink {
                                    AdminLoginView()
                                } label: {
                                    RoleCard(
                                        title: "Admin",
                                        icon: "gear",
                                        iconColor: Color.adminColor,
                                        cardColor: Color.customCardBackground
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer(minLength: 50)
                        }
                    }
                    .navigationBarHidden(true)
                    .background(Color.customBackground)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.colorScheme, .light)
}
