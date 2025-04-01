import Foundation

class CirculationRecord: Identifiable, Codable {
    let id: UUID
    let bookId: UUID
    let memberId: UUID
    let issueDate: Date
    var dueDate: Date
    var returnDate: Date?
    var renewalCount: Int
    var status: CirculationStatus
    
    init(id: UUID = UUID(),
         bookId: UUID,
         memberId: UUID,
         issueDate: Date,
         dueDate: Date,
         returnDate: Date? = nil,
         renewalCount: Int = 0,
         status: CirculationStatus = .issued) {
        self.id = id
        self.bookId = bookId
        self.memberId = memberId
        self.issueDate = issueDate
        self.dueDate = dueDate
        self.returnDate = returnDate
        self.renewalCount = renewalCount
        self.status = status
    }
    
    // Check if the book is overdue
    var isOverdue: Bool {
        guard returnDate == nil else { return false }
        return Date() > dueDate
    }

    // Calculate fine amount based on overdue days
    var fineAmount: Double {
        guard isOverdue else { return 0.0 } // No fine if not overdue
        
        let overdueDays = max(0, Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0)
        let finePerDay = 2.0 // Adjust fine rate as needed
        
        return Double(overdueDays) * finePerDay
    }
}

enum CirculationStatus: String, Codable {
    case issued
    case returned
    case renewed
    case overdue
}
