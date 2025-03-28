import SwiftUI

struct MembersListView: View {
    @State private var members: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    func fetchMembers() async -> [User]? {
        print("Fetching members from Supabase...")
        let data: [User]? = try? await SupabaseManager.shared.client
            .from("Members")
            .select("*")  // Select all columns to see the data structure
            .execute()
            .value
        
        print("Fetched data:", data ?? "nil")
        return data
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if members.isEmpty {
                        ContentUnavailableView("No Members",
                            systemImage: "person.2.slash",
                            description: Text("No members found")
                        )
                        .foregroundStyle(Color.customText)
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(members) { member in
                                MemberCardView(member: member)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .background(Color.customBackground)
            .navigationTitle("Members")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await loadMembers()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshMembers"))) { _ in
            Task {
                await loadMembers()
            }
        }
    }
    
    private func loadMembers() async {
        isLoading = true
        do {
            print("Loading members...")
            members = (await fetchMembers()) ?? []
            print("Loaded members count:", members.count)
        } catch {
            print("Load error:", error)
            errorMessage = "Failed to load members: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

#Preview {
    MembersListView()
} 
