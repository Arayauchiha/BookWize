import SwiftUI

struct MembersListView: View {
    @State private var members: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    
    var filteredMembers: [User] {
        if searchText.isEmpty {
            return members
        }
        return members.filter { member in
            member.name.localizedCaseInsensitiveContains(searchText) ||
            member.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func fetchMembers() async -> [User]? {
        print("Fetching members from Supabase...")
        do {
            let data: [User]? = try await SupabaseManager.shared.client
                .from("Members")
                .select("*")  // Select all columns to see the data structure
                .execute()
                .value
            
            print("Fetched data:", data ?? "nil")
            if let data = data {
                print("Number of members fetched:", data.count)
                if let firstMember = data.first {
                    print("First member data:", firstMember)
                }
            }
            return data
        } catch {
            print("Error fetching members:", error)
            print("Error details:", error.localizedDescription)
            return nil
        }
    }
    
    var body: some View {
        NavigationView {
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
                            // Members Statistics
//                            VStack(spacing: 8) {
//                                Text("Total Members: \(members.count)")
//                                    .font(.subheadline)
//                                    .foregroundStyle(.secondary)
                                
//                                HStack(spacing: 20) {
//                                    StatisticView(
//                                        title: "Active",
//                                        value: members.filter { $0.fine == 0 }.count,
//                                        color: .green
//                                    )
//                                    
//                                    StatisticView(
//                                        title: " Fines",
//                                        value: members.filter { $0.fine > 0 }.count,
//                                        color: .red
//                                    )
//                                }
//                            }
//                            .padding()
//                            .background(Color(.systemBackground))
//                            .cornerRadius(12)
                            
                            // Members List
                            ForEach(filteredMembers) { member in
                                MemberCardView(member: member)
                                    .transition(.opacity)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
                .refreshable {
                    await loadMembers()
                }
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search by name or email"
                )
                .navigationTitle("Library Members")
                .navigationBarTitleDisplayMode(.large)
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        Menu {
//                            Button {
//                                // Sort by name
//                            } label: {
//                                Label("Sort by Name", systemImage: "textformat")
//                            }
//                            
//                            Button {
//                                // Sort by date
//                            } label: {
//                                Label("Sort by Join Date", systemImage: "calendar")
//                            }
//                            
//                            Button {
//                                // Filter with fines
//                            } label: {
//                                Label("Show Members with Fines", systemImage: "dollarsign.circle")
//                            }
//                        } label: {
//                            Image(systemName: "line.3.horizontal.decrease.circle")
//                                .foregroundStyle(.blue)
//                        }
//                    }
//                }
            }
        }
        .task {
            await loadMembers()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshMembers"))) { _ in
            Task {
                await loadMembers()
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func loadMembers() async {
        isLoading = true
        do {
            await FineCalculator.shared.calculateAndUpdateFines()
            members = (await fetchMembers()) ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

//struct StatisticView: View {
//    let title: String
//    let value: Int
//    let color: Color
//    
//    var body: some View {
//        VStack(spacing: 4) {
//            Text(title)
//                .font(.caption)
//                .foregroundStyle(.secondary)
//            
//            Text("\(value)")
//                .font(.title2)
//                .fontWeight(.semibold)
//                .foregroundStyle(color)
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.vertical, 8)
//        .background(color.opacity(0.1))
//        .cornerRadius(8)
//    }
//}

#Preview {
    MembersListView()
}
