import Foundation

struct Reservation: Codable {
    let bookId: UUID
    let memberId: UUID
    let reservationDate: String
    let status: ReservationStatus
    
    enum CodingKeys: String, CodingKey {
        case bookId = "book_id"
        case memberId = "member_id"
        case reservationDate = "reservation_date"
        case status
    }
}

enum ReservationStatus: String, Codable {
    case pending
    case completed
    case cancelled
} 