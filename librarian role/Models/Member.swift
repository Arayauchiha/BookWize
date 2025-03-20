import Foundation

struct Member: Identifiable, Codable {
    let id: UUID
    var name: String
    var membershipNumber: String
    var email: String
    var phone: String
    var membershipType: MembershipType
    var status: MemberStatus
    var joinDate: Date
    var validUntil: Date
    
    var isActive: Bool {
        status == .active && validUntil > Date()
    }
}

enum MembershipType: String, Codable {
    case student
    case faculty
    case staff
    case external
    
    var borrowingLimit: Int {
        switch self {
        case .student: return 5
        case .faculty: return 10
        case .staff: return 8
        case .external: return 3
        }
    }
    
    var loanPeriod: Int {
        switch self {
        case .student: return 14
        case .faculty: return 30
        case .staff: return 21
        case .external: return 7
        }
    }
}

enum MemberStatus: String, Codable {
    case active
    case blocked
    case expired
} 
