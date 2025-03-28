
import SwiftUI
import Supabase

struct AdminDashboardView: View {
    @State private var selectedTab = 0
    @State private var showProfile = false
    @State private var bookRequests: [BookRequest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    SummaryView(bookRequests: $bookRequests)
                        .navigationTitle("Summary")
                }
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
                .tag(0)
                
                NavigationStack {
                    LibrarianManagementView().navigationTitle("Librarians")
                }
                .tabItem {
                    Label("Librarians", systemImage: "person.2.fill")
                }
                .tag(1)
                
                NavigationStack {
                    CatalogueView()
                        .navigationTitle("Catalogue")
                }
                .tabItem {
                    Label("Catalogue", systemImage: "books.vertical.fill")
                }
                .tag(2)
                
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
                Task { await fetchBookRequests() }
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
        case 1: return "Managment"
        case 2: return "Catalogue"
        case 3: return "Finance"
        default: return ""
        }
    }

    private func fetchBookRequests() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let client = SupabaseManager.shared.client
            let response: [BookRequest] = try await client
                .from("BookRequest")
                .select()
                .execute()
                .value
            bookRequests = response.sorted { $0.createdAt > $1.createdAt }
        } catch {
            errorMessage = "Failed to load requests: \(error.localizedDescription)"
        }
    }
}

#Preview {
    AdminDashboardView()
        .environment(\.colorScheme, .light)
}
