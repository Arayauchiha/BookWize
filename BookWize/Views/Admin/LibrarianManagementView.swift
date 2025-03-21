import SwiftUI
import Supabase

struct LibrarianManagementView: View {
    @StateObject private var authService: AuthService
    @State private var librarians: [LibrarianData] = []
    @State private var showingAddLibrarian = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(supabase: SupabaseClient) {
        _authService = StateObject(wrappedValue: AuthService(supabase: supabase))
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(librarians) { librarian in
                    LibrarianRowView(librarian: librarian)
                }
            }
            .navigationTitle("Manage Librarians")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddLibrarian = true
                    }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddLibrarian) {
                NavigationView {
                    AddLibrarianView(authService: authService)
                }
            }
            .onAppear {
                Task {
                    await fetchLibrarians()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func fetchLibrarians() async {
        isLoading = true
        do {
            let query = authService.supabase.database
                .from("Users")
                .select()
                .eq("roleFetched", value: UserRole.librarian.rawValue)
            
            let users: [User] = try await query.execute().value
            
            librarians = users.map { LibrarianData(from: $0) }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct LibrarianRowView: View {
    let librarian: LibrarianData
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(librarian.name)
                .font(.headline)
            Text(librarian.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(librarian.library)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LibrarianManagementView(
        supabase: SupabaseClient(
            supabaseURL: URL(string: "https://example.com")!,
            supabaseKey: ""
        )
    )
} 
