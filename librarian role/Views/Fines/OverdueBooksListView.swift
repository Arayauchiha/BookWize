import SwiftUI

struct OverdueBooksListView: View {
    @StateObject private var dashboardManager = DashboardManager()
    @State private var searchText = ""
    @State private var membersWithFines: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var filteredMembers: [User] {
        if searchText.isEmpty {
            return membersWithFines
        }
        return membersWithFines.filter { member in
            member.name.localizedCaseInsensitiveContains(searchText) ||
            member.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBar(text: $searchText, placeholder: "Search by member name or email")
                .padding()
            
            // Summary Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Total Overdue Fines")
                        .font(.headline)
                }
                
                Text("₹\(String(format: "%.2f", dashboardManager.overdueFines))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding()
            
            // List of Members with Fines
            if isLoading {
                ProgressView()
                    .padding()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if filteredMembers.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No results found",
                    message: "No overdue books match your search."
                )
            } else {
                List(filteredMembers) { member in
                    OverdueBookRow(
                        memberName: member.name,
                        memberEmail: member.email,
                        fine: member.fine
                    )
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Overdue Books")
        .refreshable {
            await fetchMembersWithFines()
        }
        .task {
            await fetchMembersWithFines()
        }
    }
    
    private func fetchMembersWithFines() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let client = SupabaseManager.shared.client
            let response: [User] = try await client
                .from("Members")
                .select("*")
                .gt("fine", value: 0)
                .execute()
                .value
            
            await MainActor.run {
                self.membersWithFines = response
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch members with fines: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

struct OverdueBookRow: View {
    let memberName: String
    let memberEmail: String
    let fine: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(memberName)
                .font(.headline)
            Text(memberEmail)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Fine: ₹\(String(format: "%.2f", fine))")
                .font(.headline)
                .foregroundColor(.red)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        OverdueBooksListView()
    }
}
