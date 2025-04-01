import Foundation
import SwiftUI

struct LibrarianData: Codable {
    var lib_Id = UUID()
    var name: String = ""
    var age: Int? = 0
    var email: String = ""
    var phone: String?
    var password: String = ""
    var status: Status = .pending
    var dateAdded: Date = Date()
    var requiresPasswordReset: Bool = true
    var roleFetched: UserRole?
    
    enum CodingKeys: String, CodingKey {
        case name, email, phone, age, status, password, roleFetched
        case dateAdded = "date_added"
        case requiresPasswordReset = "requires_password_reset"
    }
}

enum Status: String, CaseIterable, Codable {
    case pending = "pending"
    case working = "working"
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .working: return .green
        }
    }
}

