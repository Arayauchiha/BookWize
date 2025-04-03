import SwiftUI

struct MembersListView: View {
    @State private var members: [User] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var errorMessage: String?
    @State private var showError = false
    
    var filteredMembers: [User] {
        if searchText.isEmpty {
            return members
        }
        return members.filter { member in
            member.name.localizedCaseInsensitiveContains(searchText) ||
            member.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                if isLoading {
                    ProgressView("Loading members...")
                        .padding(.top, 40)
                } else if members.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        
                        Text("No Members Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Members will appear here once they join the library")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredMembers) { member in
                            MemberCardView(member: member)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search by name or email")
        .refreshable {
            await fetchMembers()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .task {
            await fetchMembers()
        }
    }
    
    private func fetchMembers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedMembers: [User] = try await SupabaseManager.shared.client
                .from("Members")
                .select()
                .order("name")
                .execute()
                .value
            
            await MainActor.run {
                self.members = fetchedMembers
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
}

#Preview {
    MembersListView()
}
