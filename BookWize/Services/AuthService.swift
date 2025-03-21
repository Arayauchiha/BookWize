import Foundation
import Supabase

@MainActor
class AuthService: ObservableObject {
    let supabase: SupabaseClient
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authError: String?
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // Function to create a new librarian account
    func createLibrarian(email: String, password: String, name: String, library: String) async throws {
        do {
            // First create the auth user in Supabase
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            let userId = authResponse.user.id
            
            // Create the user record in our users table
            let newLibrarian = User(
                id: UUID(),  // Generate a new UUID since we can't reliably convert Supabase's string ID
                email: email,
                name: name,
                gender: .other,
                password: password,  // Note: In production, you should hash this
                selectedLibrary: library,
                selectedGenres: [],
                role: .librarian
            )
            
            // Insert the librarian into the users table
            try await supabase.database
                .from("Users")
                .insert([
                    "id": newLibrarian.id.uuidString,
                    "email": email,
                    "password": password,
                    "roleFetched": UserRole.librarian.rawValue,
                    "vis": true.description
                ])
                .execute()
            
        } catch {
            self.authError = "Failed to create librarian account: \(error.localizedDescription)"
            throw error
        }
    }
    
    func login(email: String, password: String, role: UserRole) async throws {
        do {
            // For admin, check hardcoded credentials first
            if role == .admin {
                if email == "ss0854850@gmail.com" && password == "admin@12345" {
                    // Create an admin user object
                    let adminUser = User(
                        id: UUID(),  // Generate a new UUID for admin
                        email: email,
                        name: "Admin",
                        gender: .other,
                        password: password,
                        selectedLibrary: Library.centralLibrary.rawValue,
                        selectedGenres: [],
                        role: .admin
                    )
                    self.currentUser = adminUser
                    self.isAuthenticated = true
                    self.authError = nil
                    return
                } else {
                    throw AuthError.invalidCredentials
                }
            }
            
            // For librarians and members, authenticate with Supabase
            let authResponse = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Fetch user details from users table using email
            let query = supabase.database
                .from("Users")
                .select()
                .eq("email", value: email)
                .single()
            
            struct UserResponse: Codable {
                let id: String
                let email: String
                let password: String
                let roleFetched: String
                let vis: Bool
            }
            
            let fetchedUserResponse: UserResponse = try await query.execute().value
            
            // Create User object from response
            let fetchedUser = User(
                id: UUID(uuidString: fetchedUserResponse.id) ?? UUID(),
                email: fetchedUserResponse.email,
                name: "",  // We don't store name in DB
                gender: .other,
                password: fetchedUserResponse.password,
                selectedLibrary: Library.centralLibrary.rawValue,
                selectedGenres: [],
                role: UserRole(rawValue: fetchedUserResponse.roleFetched) ?? .member
            )
            
            // Verify the user's role matches the requested role
            if fetchedUser.role == role {
                self.currentUser = fetchedUser
                self.isAuthenticated = true
                self.authError = nil
            } else {
                throw AuthError.invalidRole
            }
        } catch let error as AuthError {
            self.authError = error.localizedDescription
            self.isAuthenticated = false
            self.currentUser = nil
            throw error
        } catch {
            self.authError = error.localizedDescription
            self.isAuthenticated = false
            self.currentUser = nil
            throw AuthError.invalidCredentials
        }
    }
    
    func isLibrarian() -> Bool {
        return currentUser?.role == .librarian
    }
    
    func signOut() async throws {
        do {
            if currentUser?.role != .admin {
                try await supabase.auth.signOut()
            }
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            self.authError = error.localizedDescription
            throw error
        }
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidRole
    case networkError
    case userCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidRole:
            return "You don't have permission to access this role"
        case .networkError:
            return "Network error occurred. Please try again"
        case .userCreationFailed:
            return "Failed to create user account"
        }
    }
} 
