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
                    LibrarianManagementView()
                        .navigationTitle("Librarians")
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
            .toolbarBackground(Color.customBackground, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .frame(height: 0.5)
                    .ignoresSafeArea(edges: .bottom)
            }
            .tint(Color.customButton)
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 0)
                    .background(.ultraThinMaterial)
            }
            // Present profile as a sheet
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    AdminProfileView()
                        .navigationTitle("Profile")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDragIndicator(.visible)
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
    
    // Add computed property for dynamic navigation title
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
