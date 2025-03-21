//
//  UserManager.swift
//  BookWize
//
//  Created by GitHub Copilot on 20/03/25.
//

import Foundation
import Supabase

// Define proper Encodable types instead of using [String: Any]
struct UserData: Encodable {
    let name: String
    let email: String
    let role: String
    let selectedLibrary: String
    let gender: String
}

//struct LibrarianData: Encodable {
//    let name: String
//    let email: String
//    let phone: String
//    let age: Int
//    let status: String
//    let dateAdded: String
//    let requiresPasswordReset: Bool
//    
//    enum CodingKeys: String, CodingKey {
//        case name, email, phone, age, status
//        case dateAdded = "date_added"
//        case requiresPasswordReset = "requires_password_reset"
//    }
//}

class UserManagerSupabase {
    static let shared = UserManagerSupabase()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    func createUser(email: String, password: String, userData: UserData) async throws {
        try await client.auth.signUp(email: email, password: password)
        
        // Add additional user data to a users table
        let _ = try await client
            .from("Users")
            .insert(userData)
            .execute()
    }
    
    func storeLibrarianCredentials(librarian: LibrarianData) async throws {
        let librarianData = UserData(
            name: librarian.name,
            email: librarian.email,
            role: UserRole.librarian.rawValue,
            selectedLibrary: librarian.library,
            gender: Gender.other.rawValue
        )
        
        // Store in users table
        let _ = try await client
            .from("Users")
            .insert(librarianData)
            .execute()
    }
    
    func getLibrarians() async throws -> [LibrarianData] {
        let response = try await client
            .from("Users")
            .select()
            .eq("roleFetched", value: UserRole.librarian.rawValue)
            .execute()
        
        let users = try JSONDecoder().decode([User].self, from: response.data)
        return users.map { LibrarianData(from: $0) }
    }
}
