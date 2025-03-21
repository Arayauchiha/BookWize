import Foundation
import SwiftUI

// MARK: - Enums
enum UserRole: String, Codable {
    case admin = "admin"
    case librarian = "librarian"
    case member = "member"
}

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

enum Library: String, CaseIterable {
    case centralLibrary = "Central Library"
    case cityLibrary = "City Library"
}

enum LibrarianStatus: String, Codable {
    case active = "Active"
    case inactive = "Inactive"
    case pending = "Pending"
    
    var color: Color {
        switch self {
        case .active: return .green
        case .inactive: return .red
        case .pending: return .orange
        }
    }
}

// MARK: - Models
struct User: Codable, Identifiable {
    let id: UUID
    var email: String
    var name: String
    var gender: Gender
    var password: String
    var selectedLibrary: String
    var selectedGenres: [String]
    var role: UserRole
    
    init(id: UUID = UUID(), email: String, name: String, gender: Gender, password: String, selectedLibrary: String, selectedGenres: [String] = [], role: UserRole = .member) {
        self.id = id
        self.email = email
        self.name = name
        self.gender = gender
        self.password = password
        self.selectedLibrary = selectedLibrary
        self.selectedGenres = selectedGenres
        self.role = role
    }
}

// MARK: - View Models
struct LibrarianData: Identifiable {
    let id: UUID
    var name: String
    var email: String
    var library: String
    var phone: String = ""  // Default empty string
    var status: LibrarianStatus = .active  // Default active status
    var dateAdded: Date = Date()  // Default to current date
    
    init(from user: User) {
        self.id = user.id
        self.name = user.name
        self.email = user.email
        self.library = user.selectedLibrary
        self.status = .active  // Default to active for existing users
        self.dateAdded = Date()  // Use current date for existing users
    }
    
    init(id: UUID = UUID(), name: String, email: String, library: String, phone: String = "", status: LibrarianStatus = .active, dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.email = email
        self.library = library
        self.phone = phone
        self.status = status
        self.dateAdded = dateAdded
    }
} 