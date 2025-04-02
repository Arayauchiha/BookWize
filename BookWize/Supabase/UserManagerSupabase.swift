//import Foundation
//import Supabase
//
//struct UserData: Encodable {
//    let name: String
//    let email: String
//    let role: String
//}
//
//class UserManagerSupabase {
//    static let shared = LibrarianDashboardManager()
//    private let client = SupabaseManager.shared.client
//    
//    private init() {}
//    
//    func createUser(email: String, password: String, userData: UserData) async throws {
//        try await client.auth.signUp(email: email, password: password)
//        let _ = try await client
//            .from("users")
//            .insert(userData)
//            .execute()
//    }
//    
//    func storeLibrarianCredentials(librarian: LibrarianData, password: String) async throws {
//        let librarianData = LibrarianData(
//            name: librarian.name,
//            age: librarian.age,
//            email: librarian.email,
//            phone: librarian.phone,
//            password: "",
//            status: librarian.status,
//            dateAdded:librarian.dateAdded,
//            requiresPasswordReset: true
//        )
//        
//        let _ = try await client
//            .from("Users")
//            .insert(librarianData)
//            .execute()
//    }
//}
