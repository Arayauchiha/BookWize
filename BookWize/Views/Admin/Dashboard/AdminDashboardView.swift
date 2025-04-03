import SwiftUI
import Supabase

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon and Title in top row
            HStack(alignment: .top, spacing: 12) {
                // Icon with simpler styling
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                    .frame(width: 28)
                
                // Title - now with text wrapping
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .dynamicTypeSize(.small ... .accessibility2)
                
                Spacer()
            }
            
            Spacer()
            
            // Value in bottom row
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                .dynamicTypeSize(.small ... .accessibility3)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// Recent Requests View Component
struct RecentRequestsView: View {
    let bookRequests: [BookRequest]
    let isLoading: Bool
    let errorMessage: String?
    
    var body: some View {
        NavigationLink {
            AllRequestsView(bookRequests: .constant(bookRequests))
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Requests")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                        .dynamicTypeSize(.small ... .accessibility3)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .padding(.horizontal)
                .padding(.top, 6)
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .dynamicTypeSize(.small ... .accessibility2)
                } else if bookRequests.isEmpty {
                    Text("No recent requests")
                        .foregroundColor(.secondary)
                        .padding()
                        .dynamicTypeSize(.small ... .accessibility2)
                } else {
                    ForEach(bookRequests.prefix(5), id: \.id) { request in
                        RequestRow(request: request)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Request Row Component
struct RequestRow: View {
    let request: BookRequest
    
    var body: some View {
        HStack {
            Image(systemName: "book.fill")
                .foregroundStyle(Color.memberColor)
            VStack(alignment: .leading) {
                Text(request.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .dynamicTypeSize(.small ... .accessibility2)
                Text(request.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .dynamicTypeSize(.small ... .accessibility2)
            }
            Spacer()
            Text(request.Request_status.rawValue.capitalized)
                .font(.caption)
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(6)
                .dynamicTypeSize(.small ... .accessibility1)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var statusColor: Color {
        switch request.Request_status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }
}

// Analytics Grid View Component
struct AnalyticsGridView: View {
    let totalRevenue: String
    let overdueFines: String
    let activeLibrarians: String
    let activeMembers: String
    let totalBooks: String
    let issuedBooks: String
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            StatCard(title: "Total Revenue", value: totalRevenue,
                    icon: "dollarsign.circle.fill", color: .green)
            StatCard(title: "Overdue Fines", value: overdueFines,
                    icon: "clock.badge.exclamationmark.fill", color: .red)
            StatCard(title: "Active Librarians", value: activeLibrarians,
                    icon: "person.2.fill", color: .blue)
            StatCard(title: "Members", value: activeMembers,
                    icon: "person.3.fill", color: .green)
            StatCard(title: "Available Books", value: totalBooks,
                    icon: "books.vertical.fill", color: .blue)
            StatCard(title: "Issued Books", value: issuedBooks,
                    icon: "book.closed.fill", color: .purple)
        }
        .padding(.horizontal)
    }
}

struct AdminDashboardView: View {
    @State private var selectedTab = 0
    @State private var showProfile = false
    @State private var bookRequests: [BookRequest] = []
    @State private var currentTask: Task<Void, Never>?
    @StateObject private var dashboardManager = DashboardManager()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        AnalyticsGridView(
                            totalRevenue: String(format: "$%.2f", dashboardManager.totalRevenue),
                            overdueFines: String(format: "$%.2f", dashboardManager.overdueFines),
                            activeLibrarians: "\(dashboardManager.activeLibrariansCount)",
                            activeMembers: "\(dashboardManager.totalMembersCount)",
                            totalBooks: "\(dashboardManager.totalBooksCount)",
                            issuedBooks: "\(dashboardManager.issuedBooksCount)"
                        )
                        
                        RecentRequestsView(
                            bookRequests: bookRequests,
                            isLoading: false,
                            errorMessage: nil
                        )
                    }
                    .padding(.vertical)
                }
                .background(Color(.systemGroupedBackground))
                .ignoresSafeArea(edges: .bottom)
                .refreshable {
                    currentTask?.cancel()
                    currentTask = Task {
                        async let requests = fetchBookRequests()
                        async let analytics = dashboardManager.fetchDashboardData()
                        try? await (requests, analytics)
                    }
                }
                .navigationTitle("Dashboard")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showProfile = true }) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 22))
                        }
                    }
                }
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }
            .tag(0)
            
            // Librarians Tab
            NavigationStack {
                LibrarianManagementView(onProfileTap: { showProfile = true })
                    .navigationTitle("Management")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Librarians", systemImage: "person.2.fill")
            }
            .tag(1)
            
            // Catalogue Tab
            NavigationStack {
                CatalogueView()
                    .navigationTitle("Catalogue")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showProfile = true }) {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 22))
                            }
                        }
                    }
            }
            .tabItem {
                Label("Catalogue", systemImage: "books.vertical.fill")
            }
            .tag(2)
            
            // Finance Tab
            NavigationStack {
                FinanceView(onProfileTap: { showProfile = true })
                    .navigationTitle("Finance")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Finance", systemImage: "dollarsign.circle.fill")
            }
            .tag(3)
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
            configureTabBar()
            // Initial data load
            currentTask = Task {
                await fetchBookRequests()
            }
        }
        .onDisappear {
            currentTask?.cancel()
            currentTask = nil
        }
    }
    
    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Configure normal state
        appearance.stackedLayoutAppearance.normal.iconColor = .gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.gray
        ]
        
        // Configure selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.customButton)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(Color.customButton)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func fetchBookRequests() async {
        do {
            let client = SupabaseManager.shared.client
            let response: [BookRequest] = try await client
                .from("BookRequest")
                .select()
                .order("created_at", ascending: false)
                .limit(5)
                .execute()
                .value
            
            // Only update if the task hasn't been cancelled
            if !Task.isCancelled {
                await MainActor.run {
                    bookRequests = response
                }
            }
        } catch {
            if !Task.isCancelled {
                print("Book requests error: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    AdminDashboardView()
}
