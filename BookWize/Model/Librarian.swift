import Foundation
import SwiftUI

struct Librarian: Identifiable {
    let id: UUID
    let name: String
    let age: Int
    let email: String
    let phone: String
    var status: Status
    let dateAdded: Date
    
    enum Status: String {
        case pending = "Pending"
        case working = "Working"
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .working: return .green
            }
        }
    }
    
    init(id: UUID = UUID(), name: String, age: Int, email: String, phone: String, status: Status = .pending) {
        self.id = id
        self.name = name
        self.age = age
        self.email = email
        self.phone = phone
        self.status = status
        self.dateAdded = Date()
    }
}
