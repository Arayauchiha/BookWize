import Foundation

struct Fine: Identifiable, Codable {
    let id: UUID
    let memberId: UUID
    let amount: Double
    let reason: FineReason
    let date: Date
    var status: FineStatus
}

enum FineReason: String, Codable {
    case overdue
    case damaged
    case lost
}

enum FineStatus: String, Codable {
    case pending
    case paid
    case waived
} 