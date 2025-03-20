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
    // Add other fields as needed
    let role: String
}

struct LibrarianData: Encodable {
    let name: String
    let email: String
    let phone: String
    let age: Int
    let status: String
    let dateAdded: String
    let requiresPasswordReset: Bool
    
    enum CodingKeys: String, CodingKey {
        case name, email, phone, age, status
        case dateAdded = "date_added"
        case requiresPasswordReset = "requires_password_reset"
    }
}

class UserManager {
    static let shared = UserManager()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    func createUser(email: String, password: String, userData: UserData) async throws {
        try await client.auth.signUp(email: email, password: password)
        
        // Add additional user data to a users table
        let _ = try await client
            .from("users")
            .insert(userData)
            .execute()
    }
    
    func storeLibrarianCredentials(librarian: Librarian, password: String) async throws {
        let librarianData = LibrarianData(
            name: librarian.name,
            email: librarian.email,
            phone: librarian.phone,
            age: librarian.age,
            status: librarian.status.rawValue,
            dateAdded: ISO8601DateFormatter().string(from: librarian.dateAdded),
            requiresPasswordReset: true
        )
        
        let _ = try await client
            .from("librarians")
            .insert(librarianData)
            .execute()
    }
}