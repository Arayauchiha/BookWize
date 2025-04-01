import SwiftUI
import Supabase

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
            GridItem(.flexible()),
            GridItem(.flexible())
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
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.customButton.opacity(Color.secondaryIconOpacity))
                        .font(.system(size: 14))
                }
                .padding(.horizontal)
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if bookRequests.isEmpty {
                    Text("No recent requests")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(bookRequests.prefix(5), id: \.id) { request in
                        RequestRow(request: request)
                    }
                }
            }
            .foregroundColor(Color.customText)
        }
    }
}

// Request Row Component
struct RequestRow: View {
    let request: BookRequest
    
    var body: some View {
        HStack {
            Image(systemName: "book.fill")
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(request.title)
                    .font(.headline)
                Text(request.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(request.Request_status.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor)
                .cornerRadius(6)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var statusColor: Color {
        switch request.Request_status {
        case .pending: return .orange
        case .approved: return Color.librarianColor
        case .rejected: return .red
        }
    }
}

struct AdminDashboardView: View {
    @State private var selectedTab = 0
    @State private var showProfile = false
    @State private var bookRequests: [BookRequest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Analytics State
    @State private var totalRevenue = "$0"
    @State private var overdueFines = "$0"
    @State private var activeLibrarians = "0"
    @State private var activeMembers = "0"
    @State private var totalBooks = "0"
    @State private var issuedBooks = "0"
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 16) {
                            AnalyticsGridView(
                                totalRevenue: totalRevenue,
                                overdueFines: overdueFines,
                                activeLibrarians: activeLibrarians,
                                activeMembers: activeMembers,
                                totalBooks: totalBooks,
                                issuedBooks: issuedBooks
                            )
                            
                            RecentRequestsView(
                                bookRequests: bookRequests,
                                isLoading: isLoading,
                                errorMessage: errorMessage
                            )
                        }
                        .padding(.vertical)
                    }
                    .navigationTitle("Dashboard")
                    .refreshable {
                        await fetchBookRequests()
                        await fetchAnalytics()
                    }
                }
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
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
                configureTabBar()
                Task {
                    await fetchBookRequests()
                    await fetchAnalytics()
                }
            }
        }
    }
    
    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.stackedLayoutAppearance.normal.iconColor = .gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.gray]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.black)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(Color.black)]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
        case 0: return "Dashboard"
        case 1: return "Management"
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
                .order("created_at", ascending: false)
                .limit(5)
                .execute()
                .value
            bookRequests = response
        } catch {
            errorMessage = "Failed to load requests: \(error.localizedDescription)"
        }
    }
    
    private func fetchAnalytics() async {
        do {
            let client = SupabaseManager.shared.client
            
            // First, let's print raw JSON for membership fee
            print("Fetching membership fee...")
            let membershipRawResponse = try await client
                .from("FineAndMembershipSet")
                .select("*")
                .execute()
            print("Raw membership response: \(String(describing: membershipRawResponse.data))")
            
            struct MembershipSetting: Codable, Hashable {
                let Membership: Double?
                let PerDayFine: Double?
                let FineSet_id: UUID?
            }
            
            let membershipFeeResponse: [MembershipSetting] = try await client
                .from("FineAndMembershipSet")
                .select("*")
                .execute()
                .value
            
            print("Decoded membership response: \(membershipFeeResponse)")
            let membershipFee = membershipFeeResponse.first?.Membership ?? 0.0
            
            // Print raw JSON for members
            print("Fetching members count...")
            let membersRawResponse = try await client
                .from("Members")
                .select("*")
                .execute()
            print("Raw members response: \(String(describing: membersRawResponse.data))")
            
            let membersCount: Int = try await client
                .from("Members")
                .select("*", head: true)
                .execute()
                .count ?? 0
            
            print("Members count: \(membersCount)")
            let membershipRevenue = Double(membersCount) * membershipFee
            
            // Print raw JSON for fines
            print("Fetching fines...")
            let finesRawResponse = try await client
                .from("issuebooks")
                .select("*")
                .execute()
            print("Raw fines response: \(String(describing: finesRawResponse.data))")
            
            struct Fine: Codable {
                let fineAmount: Double?
                let id: UUID?
            }
            
            let finesResponse: [Fine] = try await client
                .from("issuebooks")
                .select("fineAmount, id")
                .execute()
                .value
            
            print("Decoded fines: \(finesResponse)")
            let totalFines = finesResponse.reduce(0) { $0 + ($1.fineAmount ?? 0) }
            
            // Calculate total revenue
            let totalAmount = membershipRevenue + totalFines
            totalRevenue = String(format: "$%.2f", totalAmount)
            overdueFines = String(format: "$%.2f", totalFines)
            
            // Print raw JSON for librarians
            print("Fetching librarians count...")
            let librariansRawResponse = try await client
                .from("Users")
                .select("*")
                .eq("roleFetched", value: "librarian")
                .execute()
            print("Raw librarians response: \(String(describing: librariansRawResponse.data))")
            
            let librariansCount: Int = try await client
                .from("Users")
                .select("*", head: true)
                .eq("roleFetched", value: "librarian")
                .execute()
                .count ?? 0
            
            activeLibrarians = "\(librariansCount)"
            activeMembers = "\(membersCount)"
            
            // Print raw JSON for books
            print("Fetching books count...")
            let booksRawResponse = try await client
                .from("Books")
                .select("*")
                .execute()
            print("Raw books response: \(String(describing: booksRawResponse.data))")
            
            let booksCount: Int = try await client
                .from("Books")
                .select("*", head: true)
                .execute()
                .count ?? 0
            
            totalBooks = "\(booksCount)"
            
            // Print raw JSON for issued books
            print("Fetching issued books count...")
            let issuedRawResponse = try await client
                .from("issuebooks")
                .select("*")
                .execute()
            print("Raw issued books response: \(String(describing: issuedRawResponse.data))")
            
            let issuedCount: Int = try await client
                .from("issuebooks")
                .select("*", head: true)
                .execute()
                .count ?? 0
            
            issuedBooks = "\(issuedCount)"
            
        } catch {
            print("Analytics error details: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, _):
                    errorMessage = "Column not found: \(key)"
                case .typeMismatch(_, let context):
                    errorMessage = "Type mismatch: \(context.debugDescription)"
                default:
                    errorMessage = "Decoding error: \(decodingError.localizedDescription)"
                }
            } else {
                errorMessage = "Failed to load analytics: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    AdminDashboardView()
        .environment(\.colorScheme, .light)
}
