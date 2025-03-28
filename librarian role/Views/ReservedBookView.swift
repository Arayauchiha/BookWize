
import SwiftUI
import Supabase

struct ReservedMember: Codable {
    let id: UUID
    let email: String
    let name: String
    let gender: String
    let selectedLibrary: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case gender
        case selectedLibrary = "selectedLibrary"
    }
}

struct ReservedBook: Codable {
    let id: UUID
    let isbn: String?
    let title: String
    let author: String
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let genre: String?
    let imageURL: String?
    let quantity: Int
    let availableQuantity: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case isbn
        case title
        case author
        case publisher
        case publishedDate
        case description
        case pageCount
        case genre
        case imageURL
        case quantity
        case availableQuantity
    }
}

struct ReservationRecord: Identifiable, Codable {
    let id: UUID
    let created_at: Date
    let member_id: UUID
    let book_id: UUID
    var member: ReservedMember?
    var book: ReservedBook?
    
    enum CodingKeys: String, CodingKey {
        case id
        case created_at
        case member_id
        case book_id
        case member
        case book
    }
}

struct ReservedBookView: View {
//    let circulationManager: CirculationManager
    @State private var searchText = ""
    @State private var reservations: [ReservationRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://qjhfnprghpszprfhjzdl.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqaGZucHJnaHBzenByZmhqemRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzNzE5NTAsImV4cCI6MjA1Nzk0Nzk1MH0.Bny2_LBt2fFjohwmzwCclnFNmrC_LZl3s3PVx-SOeNc"
    )
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading reservations...")
            } else if reservations.isEmpty {
                EmptyStateView(
                    icon: "book.closed.circle",
                    title: "No Reserved Books",
                    message: "There are no books currently reserved"
                )
            } else {
                List {
                    ForEach(reservations) { reservation in
                        ReservationRowView(reservation: reservation)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search reservations...")
        .task {
            await fetchReservations()
        }
        .refreshable {
            await fetchReservations()
        }
    }
    
    private func fetchReservations() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: [ReservationRecord] = try await supabase.database
                .from("BookReservation")
                .select("""
                    *, 
                    member:Members(*), 
                    book:Books(*)
                    """)
                .execute()
                .value
            
            reservations = response
        } catch {
            print("Error fetching reservations: \(error)")
            errorMessage = "Failed to load reservations"
        }
    }
}

struct ReservationRowView: View {
    let reservation: ReservationRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let book = reservation.book {
                Text(book.title)
                    .font(.headline)
            }
            
            if let member = reservation.member {
                Text(member.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label(reservation.created_at.formatted(date: .abbreviated, time: .shortened),
                      systemImage: "calendar")
                    .font(.caption)
                Spacer()
                Text("Reserved")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CirculationRowView: View {
    let transaction: CirculationRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Book ID: \(transaction.bookId.uuidString)")
                    .font(.headline)
                Spacer()
                StatusBadge(status: transaction.status)
            }
            
            Text("Member ID: \(transaction.memberId.uuidString)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Label(transaction.issueDate.formatted(date: .abbreviated, time: .omitted),
                      systemImage: "calendar")
                Spacer()
                Label(transaction.dueDate.formatted(date: .abbreviated, time: .omitted),
                      systemImage: "calendar.badge.clock")
                    .foregroundColor(transaction.isOverdue ? .red : .primary)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: CirculationStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .issued:
            return .blue
        case .returned:
            return .green
        case .renewed:
            return .orange
        case .overdue:
            return .red
        }
    }
}
