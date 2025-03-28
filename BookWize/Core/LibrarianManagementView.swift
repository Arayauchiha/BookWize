import SwiftUI

struct LibrarianManagementView: View {
    @State private var showAddLibrarian = false
    @State private var librarians: [LibrarianData] = []
    @State private var isLoading = false
    
    func fetchLibrarians() {
        isLoading = true
        Task {
            if let data = await fetchLibrarian() {
                await MainActor.run {
                    librarians = data
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    librarians = []
                    isLoading = false
                }
            }
        }
    }
    
    func fetchLibrarian() async -> [LibrarianData]? {
        let data: [LibrarianData]? = try? await SupabaseManager.shared.client
            .from("Users")
            .select("*")
            .eq("roleFetched", value: "librarian")
            .execute()
            .value
        return data
    }
    
    func deleteLibrarian(at indices: IndexSet) {
        for index in indices {
            let librarian = librarians[index]
            Task {
                do {
                    try await SupabaseManager.shared.client.database
                        .from("Users")
                        .delete()
                        .eq("email", value: librarian.email)
                        .execute()
                    
                    await MainActor.run {
                        fetchLibrarians()
                    }
                } catch {
                    print("Error deleting librarian: \(error.localizedDescription)")
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if librarians.isEmpty {
                        ContentUnavailableView("No Librarians",
                            systemImage: "person.2.slash",
                            description: Text("Add your first librarian to get started")
                        )
                        .foregroundStyle(Color.customText)
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(librarians, id: \.email) { librarian in
                                LibrarianCardView(librarian: librarian, onDelete: {
                                    // This is called when a librarian is deleted from the detail view
                                    fetchLibrarians()
                                })
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Button(action: { showAddLibrarian = true }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Add Librarian")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.librarianColor)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .background(Color.customBackground)
            .refreshable {
                fetchLibrarians()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchLibrarians) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showAddLibrarian) {
                AddLibrarianView { newLibrarian in
                    fetchLibrarians()
                }
            }
            .task {
                fetchLibrarians()
            }
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 80, height: 80)
                    )
            }
        }
        .navigationTitle("Librarians")
    }
}
