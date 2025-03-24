import SwiftUI

struct AdminDashboardView: View {
    @State private var selectedTab = 0
    @State private var showProfile = false
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Summary Tab
                NavigationStack {
                    SummaryView()
                        .navigationTitle("Summary")
                }
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
                .tag(0)
                
                // Librarians Tab
                NavigationStack {
                   LibrarianManagementView().navigationTitle("Librarians")
                }
                .tabItem {
                    Label("Librarians", systemImage: "person.2.fill")
                }
                .tag(1)
                
                // Catalogue Tab
                NavigationStack {
                    CatalogueView()
                        .navigationTitle("Catalogue")
                }
                .tabItem {
                    Label("Catalogue", systemImage: "books.vertical.fill")
                }
                .tag(2)
                
                // Finance Tab
                NavigationStack {
                    FinanceView()
                        .navigationTitle("Finance")
                }
                .tabItem {
                    Label("Finance", systemImage: "dollarsign.circle.fill")
                }
                .tag(3)
            }
            .navigationTitle(tabTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    profileButton
                }
            }
            .tint(Color.customButton)

            // Present profile as a sheet
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    AdminProfileView()
                        .navigationTitle("Profile")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.stackedLayoutAppearance.normal.iconColor = .gray
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.gray]
                
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.black)
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(Color.black)]
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
    
    private var profileButton: some View {
        Button {
            showProfile = true
        } label: {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.customButton)
                .padding(.trailing, 4)
        }
    }
    private var tabTitle: String {
        switch selectedTab {
        case 0: return "Summary"
        case 1: return "Librarians"
        case 2: return "Catalogue"
        case 3: return "Finance"
        default: return ""
        }
    }
}

#Preview {
    AdminDashboardView()
        .environment(\.colorScheme, .light)
}
