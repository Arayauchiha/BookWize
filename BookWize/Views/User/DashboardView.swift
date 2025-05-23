import SwiftUI
import Supabase

// Add this before extension issueBooks
class FinePolicyManager {
    static let shared = FinePolicyManager()
    
    // Default fine rate until we fetch from database
    private(set) var perDayFine: Double = 0.50
    private var isFetching = false
    
    func loadFinePolicy() {
        if !isFetching {
            isFetching = true
            Task {
                do {
                    // Fetch the PerDayFine value from FineAndMembershipSet table
                    let response = try await SupabaseManager.shared.client
                        .from("FineAndMembershipSet")
                        .select("*")
                        .execute()
                    
                    if let jsonString = String(data: response.data, encoding: .utf8),
                       let jsonData = jsonString.data(using: .utf8) {
                        do {
                            if let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                               let firstRecord = jsonArray.first {
                                // Try different possible case variations of the column name
                                if let fetchedFine = firstRecord["perdayfine"] as? Double {
                                    await MainActor.run {
                                        self.perDayFine = fetchedFine
                                        print("Fetched perDayFine from database: \(fetchedFine)")
                                    }
                                } else if let fetchedFine = firstRecord["per_day_fine"] as? Double {
                                    await MainActor.run {
                                        self.perDayFine = fetchedFine
                                        print("Fetched per_day_fine from database: \(fetchedFine)")
                                    }
                                } else if let fetchedFine = firstRecord["PerDayFine"] as? Double {
                                    await MainActor.run {
                                        self.perDayFine = fetchedFine
                                        print("Fetched PerDayFine from database: \(fetchedFine)")
                                    }
                                } else {
                                    print("Could not find PerDayFine column in: \(firstRecord.keys)")
                                }
                            }
                        } catch {
                            print("Error parsing PerDayFine JSON: \(error)")
                        }
                    }
                } catch {
                    print("Error fetching PerDayFine: \(error)")
                }
                self.isFetching = false
            }
        }
    }
}

// Extension to add fineAmount property to issueBooks
extension issueBooks {
    var fineAmount: Double {
        var daysLate = 0
        
        if let returnDate = actualReturnedDate, let dueDate = self.returnDate {
            // Book was returned, check if it was late
            if returnDate > dueDate {
                // If returned late by any amount, count as at least 1 day late
                let calendar = Calendar.current
                let components = calendar.dateComponents([.day], from: dueDate, to: returnDate)
                daysLate = max(1, components.day ?? 0)
            }
        } else if let dueDate = returnDate {
            // Book is still checked out, check if overdue
            let now = Date()
            if now > dueDate {
                // If overdue by any amount, count as at least 1 day overdue
                let calendar = Calendar.current
                let components = calendar.dateComponents([.day], from: dueDate, to: now)
                daysLate = max(1, components.day ?? 0)
            }
        }
        
        // Calculate fine based on days late and per day fine rate
        if daysLate > 0 {
            return Double(daysLate) * FinePolicyManager.shared.perDayFine
        }
        
        return 0.0 // No fine
    }
}

// MARK: - Models (specific to DashboardView)
enum BookStatus: String {
    case borrowed = "Borrowed"
    case reserved = "Reserved"
    case returned = "Returned"
    
    var color: Color {
        switch self {
        case .borrowed: return .blue
        case .reserved: return .purple
        case .returned: return .green
        }
    }
}
struct Member: Identifiable , Codable {
    let id: String
    let email: String
    let name: String
}

struct BorrowedBook: Identifiable {
    let id: String
    let title: String
    let author: String
    let coverImage: String
    let issueDate: Date
    let dueDate: Date
    let progress: Double
    let status: BookStatus
}

// Definition of IssueBookInfo (moved from ReadingProgressComponents.swift)
struct IssueBookInfo: Identifiable, Hashable {
    let id: UUID
    let issueBook: issueBooks
    var book: BookData?
    var progress: Double {
        guard let pagesRead = issueBook.pagesRead, 
              let totalPages = book?.pageCount,
              totalPages > 0 else {
            return 0.0
        }
        return min(Double(pagesRead) / Double(totalPages), 1.0)
    }
    var isCompleted: Bool {
        guard let pagesRead = issueBook.pagesRead,
              let totalPages = book?.pageCount else {
            return false
        }
        // Only count as completed if 100% of pages are read
        return pagesRead >= totalPages
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: IssueBookInfo, rhs: IssueBookInfo) -> Bool {
        lhs.id == rhs.id
    }
}

struct BookData: Identifiable, Codable {
    let id: UUID
    let title: String
    let author: String
    let pageCount: Int?
}

// MARK: - View Models
class BorrowedBooksManager: ObservableObject {
    @Published var borrowedBooks: [BorrowedBook] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var timer: Timer?
    
    
    
    deinit {
        timer?.invalidate()
    }
    
    
    func refreshBorrowedBooks() async {
        await fetchBorrowedBooks()
    }
    
    @MainActor
    func fetchBorrowedBooks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get the current user's email from UserDefaults
            guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail") else {
                print("No email found in UserDefaults")
                errorMessage = "User email not found"
                isLoading = false
                return
            }
            
            print("Fetching borrowed books for user: \(userEmail)")
            
            // First, fetch the issued books
            let issueBooksResponse: [issueBooks] = try await SupabaseManager.shared.client
                .from("issuebooks")
                .select("*")
                .eq("member_email", value: userEmail)
                .is("actual_returned_date", value: nil)
                .execute()
                .value
            
            print("Fetched \(issueBooksResponse.count) issued books")
            
            // Convert to BorrowedBook objects
            var books: [BorrowedBook] = []
            
            // Fetch book details for each issued book
            for issue in issueBooksResponse {
                do {
                    // Fetch book details using ISBN
                    let bookResponse: [Book] = try await SupabaseManager.shared.client
                        .from("Books")
                        .select("*")
                        .eq("isbn", value: issue.isbn)
                        .execute()
                        .value
                    
                    if let book = bookResponse.first {
                        let borrowedBook = BorrowedBook(
                            id: issue.id.uuidString,
                            title: book.title,
                            author: book.author,
                            coverImage: book.imageURL ?? "book.fill",
                            issueDate: issue.issueDate,
                            dueDate: issue.returnDate!,
                            progress: Double(issue.pagesRead ?? 0) / Double(book.pageCount ?? 1),
                            status: .borrowed
                        )
                        books.append(borrowedBook)
                    } else {
                        print("Book not found for ISBN: \(issue.isbn)")
                    }
                } catch {
                    print("Error fetching book details for ISBN \(issue.isbn): \(error)")
                }
            }
            
            let captureBooks = books
            await MainActor.run {
                self.borrowedBooks = captureBooks
                self.isLoading = false
                print("Updated borrowed books: \(captureBooks.count)")
            }
            
        } catch {
            print("Error fetching borrowed books: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load borrowed books: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

// Add this after BorrowedBooksManager class
class ReturnedBooksManager: ObservableObject {
    @Published var returnedBooks: [ReturnedBook] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func refreshReturnedBooks() async {
        await fetchReturnedBooks()
    }
    
    func fetchReturnedBooks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get the current user's email from UserDefaults
            guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail") else {
                print("No email found in UserDefaults")
                errorMessage = "User email not found"
                isLoading = false
                return
            }
            
            print("Fetching returned books for user: \(userEmail)")
            
            // Fetch returned books
            let issueBooksResponse: [issueBooks] = try await SupabaseManager.shared.client
                .from("issuebooks")
                .select("*")
                .eq("member_email", value: userEmail)
                .execute()
                .value
            
            print("Fetched \(issueBooksResponse.count) books")
            
            // Filter returned books in Swift code
            let returnedBooks = issueBooksResponse.filter { $0.actualReturnedDate != nil }
            print("Found \(returnedBooks.count) returned books")
            
            // Convert to ReturnedBook objects
            var books: [ReturnedBook] = []
            
            // Fetch book details for each returned book
            for issue in returnedBooks {
                do {
                    // Fetch book details using ISBN
                    let bookResponse: [Book] = try await SupabaseManager.shared.client
                        .from("Books")
                        .select("*")
                        .eq("isbn", value: issue.isbn)
                        .execute()
                        .value
                    
                    if let book = bookResponse.first {
                        let returnedBook = ReturnedBook(
                            id: issue.id.uuidString,
                            title: book.title,
                            author: book.author,
                            coverImage: book.imageURL ?? "book.fill",
                            issueDate: issue.issueDate,
                            dueDate: issue.returnDate!,
                            returnDate: issue.actualReturnedDate!,
                            progress: Double(issue.pagesRead ?? 0) / Double(book.pageCount ?? 1)
                        )
                        books.append(returnedBook)
                    } else {
                        print("Book not found for ISBN: \(issue.isbn)")
                    }
                } catch {
                    print("Error fetching book details for ISBN \(issue.isbn): \(error)")
                }
            }
            
            let capturedBooks = books
            await MainActor.run {
                self.returnedBooks = capturedBooks
                self.isLoading = false
                print("Updated returned books: \(capturedBooks.count)")
            }
            
        } catch {
            print("Error fetching returned books: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load returned books: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

// Add this after BorrowedBook struct
struct ReturnedBook: Identifiable {
    let id: String
    let title: String
    let author: String
    let coverImage: String
    let issueDate: Date
    let dueDate: Date
    let returnDate: Date
    let progress: Double
}

// MARK: - Overdue Fines Models and Manager
struct OverdueFine: Identifiable {
    let id: UUID
    let bookTitle: String
    let bookAuthor: String
    let coverImage: String
    let dueDate: Date
    let returnDate: Date?
    let fineAmount: Double
    let isbn: String
}

class OverdueFinesManager: ObservableObject {
    @Published var overdueFines: [OverdueFine] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var totalFineAmount: Double {
        overdueFines.filter { $0.returnDate == nil }.reduce(0) { $0 + $1.fineAmount }
    }
    
    var fineCount: Int {
        overdueFines.count
    }
    
    func refreshFines() async {
        // Make sure fine policy is up to date
        FinePolicyManager.shared.loadFinePolicy()
        await fetchOverdueFines()
    }
    @MainActor
    func fetchOverdueFines() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get the current user's email from UserDefaults
            guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail") else {
                print("No email found in UserDefaults")
                errorMessage = "User email not found"
                isLoading = false
                return
            }
            
            print("Fetching overdue fines for user: \(userEmail)")
            
            // Fetch books with potential fines from issuebooks table
            let issueBooksResponse: [issueBooks] = try await SupabaseManager.shared.client
                .from("issuebooks")
                .select("*")
                .eq("member_email", value: userEmail)
                .execute()
                .value
            
            // Filter to only include books with fines (overdue or returned late)
            let booksWithFines = issueBooksResponse.filter { issuedBook in
                // Only include books with a fine amount > 0
                return issuedBook.fineAmount > 0
            }
            
            print("Fetched \(booksWithFines.count) books with fines")
            
            // Convert to OverdueFine objects
            var fines: [OverdueFine] = []
            
            // Fetch book details for each issued book with a fine
            for issue in booksWithFines {
                do {
                    // Fetch book details using ISBN
                    let bookResponse: [Book] = try await SupabaseManager.shared.client
                        .from("Books")
                        .select("*")
                        .eq("isbn", value: issue.isbn)
                        .execute()
                        .value
                    
                    if let book = bookResponse.first {
                        let fine = OverdueFine(
                            id: issue.id,
                            bookTitle: book.title,
                            bookAuthor: book.author,
                            coverImage: book.imageURL ?? "book.fill",
                            dueDate: issue.returnDate ?? Date(),
                            returnDate: issue.actualReturnedDate,
                            fineAmount: issue.fineAmount,
                            isbn: issue.isbn
                        )
                        fines.append(fine)
                    } else {
                        print("Book not found for ISBN: \(issue.isbn)")
                    }
                } catch {
                    print("Error fetching book details for ISBN \(issue.isbn): \(error)")
                }
            }
            
            let capturedFines = fines
            await MainActor.run {
                self.overdueFines = capturedFines
                self.isLoading = false
                print("Updated overdue fines: \(capturedFines.count)")
            }
            
        } catch {
            print("Error fetching overdue fines: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load overdue fines: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

// Add this after the ReturnedBooksManager class
class ReservedBooksManager: ObservableObject {
    @Published var reservedBooks: [ReservationRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var timer: Timer?
    
    deinit {
        timer?.invalidate()
    }
    
    func refreshReservedBooks() async {
        await fetchReservedBooks()
    }
    
    func fetchReservedBooks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get the current user's email from UserDefaults
            guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail") else {
                print("No email found in UserDefaults")
                errorMessage = "User email not found"
                isLoading = false
                return
            }
            
            print("Fetching reserved books for user: \(userEmail)")
            
            // First, get the user's ID from their email
            let memberResponseResult = try await SupabaseManager.shared.client
                .from("Members")
                .select("*")
                .eq("email", value: userEmail)
                .execute()
            
            // Manual parsing of the memberResponse to get the member ID
            let memberData = memberResponseResult.data
            var memberId: String? = nil
            
            if let jsonString = String(data: memberData, encoding: .utf8),
               let jsonData = jsonString.data(using: .utf8) {
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                       let firstMember = jsonArray.first {
                        memberId = firstMember["id"] as? String
                    }
                } catch {
                    print("Error parsing member response JSON: \(error)")
                }
            }
            
            guard let memberIdValue = memberId else {
                print("Member not found for email: \(userEmail)")
                errorMessage = "Member not found"
                isLoading = false
                return
            }
            
            // Fetch reservations with joined book data
            let reservationsResponse: [ReservationRecord] = try await SupabaseManager.shared.client
                .from("BookReservation")
                .select("""
                    *,
                    member:Members(*),
                    book:Books(*)
                    """)
                .eq("member_id", value: memberIdValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("Fetched \(reservationsResponse.count) reservations")
            
            await MainActor.run {
                self.reservedBooks = reservationsResponse
                self.isLoading = false
                print("Updated reserved books: \(reservationsResponse.count)")
            }
            
        } catch {
            print("Error fetching reserved books: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load reserved books: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

// MARK: - Main Dashboard View
struct DashboardView: View {
    @StateObject private var booksManager = BorrowedBooksManager()
    @State private var user: User?
    @State private var issuedBooks: [IssueBookInfo] = []
    @State private var booksData: [BookData] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showReadingTracker = false
    @State private var goalSliderValue: Double = 1
    @State private var showingGoalSheet = false
    @State private var showingBookManagement = false
    @State private var currentIndex = 0
    @StateObject private var finesManager = OverdueFinesManager()
    @State private var showingHistory = false
    
    var mostUrgentBook: BorrowedBook? {
        // First, check for overdue books
        let overdueBooks = booksManager.borrowedBooks.filter { book in
            let calendar = Calendar.current
            let now = Date()
            let components = calendar.dateComponents([.day], from: now, to: book.dueDate)
            return (components.day ?? 0) < 0
        }
        
        if !overdueBooks.isEmpty {
            // Return the most overdue book (largest negative days)
            return overdueBooks.max { book1, book2 in
                let calendar = Calendar.current
                let now = Date()
                let days1 = calendar.dateComponents([.day], from: now, to: book1.dueDate).day ?? 0
                let days2 = calendar.dateComponents([.day], from: now, to: book2.dueDate).day ?? 0
                return days1 > days2
            }
        }
        
        // If no overdue books, return the book with least time remaining
        return booksManager.borrowedBooks.min { book1, book2 in
            let calendar = Calendar.current
            let now = Date()
            let days1 = calendar.dateComponents([.day], from: now, to: book1.dueDate).day ?? 0
            let days2 = calendar.dateComponents([.day], from: now, to: book2.dueDate).day ?? 0
            return days1 < days2
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading your dashboard...")
                        .padding()
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("Error loading dashboard")
                            .font(.headline)
                        
                        Text(error)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding()
                        
                        Button(action: {
                            isLoading = true
                            Task {
                                await fetchUserData()
                            }
                        }) {
                            Text("Try Again")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    // Monthly Reading Goal Section
                    VStack(alignment: .leading, spacing: 8) {
                        NavigationLink(destination: ReadingProgressDetailView(
                            monthlyGoal: user?.monthlyGoal ?? 0,
                            issuedBooks: issuedBooks,
                            updatePagesRead: updatePagesRead,
                            updateGoal: updateMonthlyGoal
                        )) {
                            HStack {
                                Text("Reading Progress")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Reading Progress Card
                        ReadingProgressCard(
                            monthlyGoal: user?.monthlyGoal ?? 0,
                            completedBooks: completedBooksCount,
                            issuedBooks: issuedBooks.count,
                            onTap: {}
                        )
                        .padding(.horizontal)
                    }
                    
                    // Your Reads Section (moved down)
                    VStack(alignment: .leading, spacing: 8) {
                        NavigationLink(destination: BookManagementView()
                            .environmentObject(booksManager)) {
                            HStack {
                                Text("Book Log")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        
                        if let urgentBook = mostUrgentBook {
                            TabView(selection: $currentIndex) {
                                BorrowedBookRow(book: urgentBook)
                                    .tag(0)
                                    .padding(.horizontal)
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .frame(height: 200)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Tap to view your books")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Overdue Fines Section
                    VStack(alignment: .leading, spacing: 8) {
                        NavigationLink(destination: OverdueFinesView()) {
                            HStack {
                                Text("Overdue Books")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Display the card without NavigationLink - make it non-clickable
                        OverdueFinesCard(
                            totalAmount: finesManager.totalFineAmount,
                            fineCount: finesManager.fineCount
                        )
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            // Load the fine policy when the view appears
            FinePolicyManager.shared.loadFinePolicy()
            
            Task {
                await fetchUserData()
                await booksManager.fetchBorrowedBooks()
                await finesManager.fetchOverdueFines()
            }
        }

        .sheet(isPresented: $showReadingTracker) {
            ReadingProgressDetailView(
                monthlyGoal: user?.monthlyGoal ?? 0,
                issuedBooks: issuedBooks,
                updatePagesRead: updatePagesRead,
                updateGoal: updateMonthlyGoal
            )

        }
        .sheet(isPresented: $showingGoalSheet) {
            MonthlyGoalSheet(
                currentGoal: user?.monthlyGoal ?? 0,
                updateGoal: updateMonthlyGoal
            )
        }
    }
    
    // Calculated completed books count
    var completedBooksCount: Int {
        issuedBooks.filter { $0.isCompleted }.count
    }
    
    // Update monthly reading goal
    private func updateMonthlyGoal(_ goal: Int) async {
        do {
            guard let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            }
            
            print("📊 Updating monthly goal to: \(goal) for user: \(userId)")
            
            // Update in Supabase
            let updateResponse = try await SupabaseManager.shared.client
                .from("Members")
                .update(["monthly_goal": goal])
                .eq("id", value: userId)
                .execute()
            
            if let jsonString = String(data: updateResponse.data, encoding: .utf8) {
                print("✅ Goal update response: \(jsonString)")
            }
            
            // Immediately update the UI
            await MainActor.run {
                if var updatedUser = self.user {
                    updatedUser.monthlyGoal = goal
                    self.user = updatedUser
                }
                self.goalSliderValue = Double(goal)
            }
            
            // Force refresh data to ensure consistency
            await fetchUserData()
            
        } catch {
            print("❌ Error updating monthly goal: \(error)")
        }
    }
    
    // Add a debugging function to help diagnose the User decoding issue
    private func printDecodingError<T>(_ data: Data, type: T.Type) where T: Decodable {
        do {
            _ = try JSONDecoder().decode(type, from: data)
            print("✅ Successfully decoded \(type)")
        } catch let DecodingError.keyNotFound(key, context) {
            print("❌ Key '\(key.stringValue)' not found: \(context.debugDescription)")
            print("📍 codingPath: \(context.codingPath)")
        } catch let DecodingError.valueNotFound(type, context) {
            print("❌ Value '\(type)' not found: \(context.debugDescription)")
            print("📍 codingPath: \(context.codingPath)")
        } catch let DecodingError.typeMismatch(type, context) {
            print("❌ Type '\(type)' mismatch: \(context.debugDescription)")
            print("📍 codingPath: \(context.codingPath)")
        } catch let DecodingError.dataCorrupted(context) {
            print("❌ Data corrupted: \(context.debugDescription)")
            print("📍 codingPath: \(context.codingPath)")
        } catch {
            print("❌ Other decoding error: \(error.localizedDescription)")
        }
    }
    
    // Fix the User struct or its decoding in fetchUserData
    private func fetchUserData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First fetch the current member
            guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail"),
                  let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            }
            
            print("🔍 Fetching user data for ID: \(userId), Email: \(userEmail)")
            
            // Explicit query to ensure monthly_goal is fetched properly
            let memberResponse = try await SupabaseManager.shared.client
                .from("Members")
                .select("id, email, name, monthly_goal")
                .eq("id", value: userId)
                .execute()
            
            // Debug the raw response
            if let jsonString = String(data: memberResponse.data, encoding: .utf8) {
                print("📋 Raw member data: \(jsonString)")
            }
            
            // Since we can't modify the User struct directly, use a simpler approach
            // Parse the JSON manually to extract the monthly_goal
            if let jsonString = String(data: memberResponse.data, encoding: .utf8),
               let jsonData = jsonString.data(using: .utf8) {
                
                // Print any decoding errors to debug
                printDecodingError(jsonData, type: [User].self)
                
                // Try to manually extract the monthly_goal using JSONSerialization
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                       let firstUser = jsonArray.first {
                        
                        let userId = UUID(uuidString: firstUser["id"] as? String ?? "") ?? UUID()
                        let email = firstUser["email"] as? String ?? ""
                        let name = firstUser["name"] as? String ?? ""
                        let monthlyGoal = firstUser["monthly_goal"] as? Int ?? 0
                        
                        print("✅ Manually parsed user - name: \(name), email: \(email), monthly_goal: \(monthlyGoal)")
                        
                        // Create a User instance manually with the parsed values
                        let user = User(
                            id: userId,
                            email: email,
                            name: name,
                            gender: .other, // Default value since we don't have this
                            password: "",  // Default value since we don't have this
                            selectedLibrary: "", // Default value since we don't have this
                            monthlyGoal: monthlyGoal
                        )
                        
                        // Update UI with user info
                        await MainActor.run {
                            self.user = user
                            self.goalSliderValue = Double(monthlyGoal)
                        }
                    }
                } catch {
                    print("❌ Error parsing JSON manually: \(error.localizedDescription)")
                }
            }
            
            // Now fetch issued books for this member
            let issueBooksResponse = try await SupabaseManager.shared.client
                .from("issuebooks")
                .select("*")
                .eq("member_email", value: userEmail)
                .execute()
            
            // Parse the response to get issued books
            let issueBooksData = issueBooksResponse.data
            var issueInfoArray: [IssueBookInfo] = []
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let jsonString = String(data: issueBooksData, encoding: .utf8),
               let jsonData = jsonString.data(using: .utf8) {
                
                if jsonString != "[]" {
                    do {
                        let issuedBooksArray = try decoder.decode([issueBooks].self, from: jsonData)
                        
                        // Fetch book details for each issued book
                        for issuedBook in issuedBooksArray {
                            let bookResponse = try await SupabaseManager.shared.client
                                .from("Books")
                                .select("id, title, author, pageCount")
                                .eq("isbn", value: issuedBook.isbn)
                                .execute()
                            
                            let bookData = bookResponse.data
                            if let bookJsonString = String(data: bookData, encoding: .utf8),
                               let bookJsonData = bookJsonString.data(using: .utf8),
                               bookJsonString != "[]" {
                                
                                let books = try decoder.decode([BookData].self, from: bookJsonData)
                                if let firstBook = books.first {
                                    issueInfoArray.append(IssueBookInfo(
                                        id: issuedBook.id,
                                        issueBook: issuedBook,
                                        book: firstBook
                                    ))
                                } else {
                                    issueInfoArray.append(IssueBookInfo(
                                        id: issuedBook.id,
                                        issueBook: issuedBook,
                                        book: nil
                                    ))
                                }
                            } else {
                                // Book not found but still add the issue record
                                issueInfoArray.append(IssueBookInfo(
                                    id: issuedBook.id,
                                    issueBook: issuedBook,
                                    book: nil
                                ))
                            }
                        }
                    } catch {
                        print("❌ Error decoding issued books: \(error.localizedDescription)")
                    }
                } else {
                    print("📚 No issued books found for user")
                }
            }
            
            await MainActor.run {
                self.issuedBooks = issueInfoArray
                self.isLoading = false
                
                print("🎯 Monthly goal set to: \(self.user?.monthlyGoal ?? 0)")
                print("📚 Completed books: \(self.completedBooksCount) of \(self.issuedBooks.count)")
            }
            
        } catch {
            print("❌ Error fetching data: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // Update pages read for a book
    private func updatePagesRead(for bookId: UUID, pagesRead: Int) async {
        do {
            print("📝 Sending update to Supabase for book ID: \(bookId), pages read: \(pagesRead)")
            
            // Update in Supabase
            let updateResponse = try await SupabaseManager.shared.client
                .from("issuebooks")
                .update(["pages_read": pagesRead])
                .eq("id", value: bookId)
                .execute()
            
            if let jsonString = String(data: updateResponse.data, encoding: .utf8) {
                print("✅ Pages update response: \(jsonString)")
            }
            
            // Update locally without forcing a refresh
            await MainActor.run {
                if let index = issuedBooks.firstIndex(where: { $0.issueBook.id == bookId }) {
                    var updatedIssueBook = issuedBooks[index].issueBook
                    updatedIssueBook.pagesRead = pagesRead
                    issuedBooks[index] = IssueBookInfo(
                        id: updatedIssueBook.id,
                        issueBook: updatedIssueBook,
                        book: issuedBooks[index].book
                    )
                }
            }
            
            // Don't refresh data to maintain card positions
            // await fetchUserData()
        } catch {
            print("❌ Error updating pages read: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct BookManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var booksManager: BorrowedBooksManager
    @State private var selectedSegment = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Segmented Control
            HStack(spacing: 0) {
                ForEach(0..<3) { index in
                    Button(action: {
                        withAnimation {
                            selectedSegment = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(segmentTitle(for: index))
                                .font(.subheadline)
                                .fontWeight(selectedSegment == index ? .semibold : .regular)
                            
                            Rectangle()
                                .fill(selectedSegment == index ? Color.blue : Color.clear)
                                .frame(height: 3)
                        }
                        .foregroundColor(selectedSegment == index ? .blue : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1),
                alignment: .bottom
            )
            
            // Content based on selected segment
            TabView(selection: $selectedSegment) {
                BorrowedBooksView()
                    .tag(0)
                
                ReservedBooksView()
                    .tag(1)
                
                ReturnedBooksView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Book Log")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func segmentTitle(for index: Int) -> String {
        switch index {
        case 0: return "Borrowed"
        case 1: return "Reserved"
        case 2: return "Returned"
        default: return ""
        }
    }
}

struct BorrowedBooksView: View {
    @EnvironmentObject var booksManager: BorrowedBooksManager
    
    var sortedBooks: [BorrowedBook] {
        booksManager.borrowedBooks.sorted { book1, book2 in
            let calendar = Calendar.current
            let now = Date()
            let days1 = calendar.dateComponents([.day], from: now, to: book1.dueDate).day ?? 0
            let days2 = calendar.dateComponents([.day], from: now, to: book2.dueDate).day ?? 0
            
            // If both books are overdue, sort by most overdue first
            if days1 < 0 && days2 < 0 {
                return days1 < days2
            }
            // If only one book is overdue, it should come first
            if days1 < 0 {
                return true
            }
            if days2 < 0 {
                return false
            }
            // For non-overdue books, sort by least time remaining
            return days1 < days2
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if booksManager.isLoading {
                    ProgressView("Loading books...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if booksManager.borrowedBooks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No borrowed books")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Button(action: {
                            Task {
                                await booksManager.refreshBorrowedBooks()
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(sortedBooks) { book in
                        BorrowedBookRow(book: book)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await booksManager.refreshBorrowedBooks()
        }
        .task {
            await booksManager.refreshBorrowedBooks()
        }
    }
}

struct BorrowedBookRow: View {
    let book: BorrowedBook
    
    var timeRemaining: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: book.dueDate)
        
        if let days = components.day {
            if days < 0 || book.dueDate < now {
                // If due date has passed by any amount, count as at least 1 day overdue
                let overdueDays = max(1, abs(days))
                return "Overdue by \(overdueDays) day\(overdueDays == 1 ? "" : "s")"
            } else if days == 0 {
                // Due today
                return "Due today"
            } else {
                return "\(days) day\(days == 1 ? "" : "s") left"
            }
        }
        return ""
    }
    
    var timeRemainingColor: Color {
        let now = Date()
        
        // If book is overdue by any amount, show red
        if book.dueDate < now {
            return .red
        } else {
            // Calculate days until due
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: now, to: book.dueDate)
            
            if let days = components.day {
                if days == 0 {
                    return .orange // Due today
                } else if days <= 1 {
                    return .orange // Due tomorrow
                } else {
                    return .blue // More than a day left
                }
            }
        }
        return .gray
    }
    
    var isOverdue: Bool {
        // Book is overdue if due date is in the past
        return book.dueDate < Date()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Book Cover with AsyncImage
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 100)
                        .shadow(color: Color.blue.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    if book.coverImage != "book.fill" {
                        AsyncImage(url: URL(string: book.coverImage)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 50, height: 50)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 70, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Image(systemName: "book.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                            @unknown default:
                                Image(systemName: "book.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        Image(systemName: "book.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(book.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Status Badge - Always blue for borrowed status
                        Text(book.status.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Time Remaining Section with Label
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isOverdue ? "Overdue Status" : "Time Remaining")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "clock.fill")
                                .font(.caption)
                                .foregroundColor(timeRemainingColor)
                            Text(timeRemaining)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(timeRemainingColor)
                        }
                    }
                }
            }
            
            // Dates
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Issue Date")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text(book.issueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Due Date")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text(book.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ReservedBooksView: View {
    @StateObject private var booksManager = ReservedBooksManager()
    
    var sortedBooks: [ReservationRecord] {
        booksManager.reservedBooks.sorted { book1, book2 in
            let expirationDate1 = Calendar.current.date(byAdding: .hour, value: 24, to: book1.created_at) ?? Date()
            let expirationDate2 = Calendar.current.date(byAdding: .hour, value: 24, to: book2.created_at) ?? Date()
            return expirationDate1 < expirationDate2 // Sort by earliest expiration first
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if booksManager.isLoading {
                    ProgressView("Loading books...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if booksManager.reservedBooks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No reserved books")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Button(action: {
                            Task {
                                await booksManager.refreshReservedBooks()
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(sortedBooks) { reservation in
                        ReservedBookRow(reservation: reservation)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await booksManager.refreshReservedBooks()
        }
        .task {
            await booksManager.refreshReservedBooks()
        }
    }
}

struct ReservedBookRow: View {
    let reservation: ReservationRecord
    
    var remainingHours: Int {
        let expirationDate = Calendar.current.date(byAdding: .hour, value: 24, to: reservation.created_at) ?? Date()
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour], from: now, to: expirationDate)
        return components.hour ?? 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Book Cover with AsyncImage
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 100)
                        .shadow(color: Color.blue.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    if let imageURL = reservation.book?.imageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 50, height: 50)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 70, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Image(systemName: "book.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                            @unknown default:
                                Image(systemName: "book.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        Image(systemName: "book.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(reservation.book?.title ?? "Unknown Book")
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Status Badge
                        Text("Reserved")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                    }
                    
                    Text(reservation.book?.author ?? "Unknown Author")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Availability Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reservation Time")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(remainingHours) hour\(remainingHours == 1 ? "" : "s") remaining")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            // Reservation Details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Reserved On")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text(reservation.created_at.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Hold Until")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text(Calendar.current.date(byAdding: .hour, value: 24, to: reservation.created_at)?.formatted(date: .abbreviated, time: .omitted) ?? "")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ReturnedBooksView: View {
    @StateObject private var booksManager = ReturnedBooksManager()
    
    var sortedBooks: [ReturnedBook] {
        booksManager.returnedBooks.sorted { book1, book2 in
            book1.returnDate > book2.returnDate // Most recently returned first
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if booksManager.isLoading {
                    ProgressView("Loading books...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if booksManager.returnedBooks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No returned books")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Button(action: {
                            Task {
                                await booksManager.refreshReturnedBooks()
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(sortedBooks) { book in
                        ReturnedBookRow(book: book)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await booksManager.refreshReturnedBooks()
        }
        .task {
            await booksManager.refreshReturnedBooks()
        }
    }
}

struct ReturnedBookRow: View {
    let book: ReturnedBook
    
    var daysSinceReturn: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: book.returnDate, to: now)
        return components.day ?? 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Book Cover with AsyncImage
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 100)
                        .shadow(color: Color.blue.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    if book.coverImage != "book.fill" {
                        AsyncImage(url: URL(string: book.coverImage)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 50, height: 50)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 70, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Image(systemName: "book.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                            @unknown default:
                                Image(systemName: "book.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        Image(systemName: "book.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(book.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Status Badge
                        Text("Returned")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.2))
                            )
                            .foregroundColor(.green)
                    }
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Return Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Return Status")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(daysSinceReturn == 0 ? "Returned today" : "Returned \(daysSinceReturn) day\(daysSinceReturn == 1 ? "" : "s") ago")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            // Return Details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Returned On")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text(book.returnDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Due Date")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text(book.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

struct OverdueFinesView: View {
    @StateObject private var finesManager = OverdueFinesManager()
    @State private var showingHistory = false
    
    var nonReturnedOverdueFines: [OverdueFine] {
        finesManager.overdueFines.filter { $0.returnDate == nil }
    }
    
    var returnedOverdueFines: [OverdueFine] {
        finesManager.overdueFines.filter { $0.returnDate != nil }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if finesManager.isLoading {
                    ProgressView("Loading fines...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if finesManager.overdueFines.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.12))
                                .frame(width: 90, height: 90)
                            
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 8) {
                            Text("No overdue books")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("You don't have any overdue books at the moment.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            Task {
                                await finesManager.refreshFines()
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(20)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        Color(.systemBackground),
                                        Color.green.opacity(0.03)
                                    ]
                                ),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.green.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal)
                } else if nonReturnedOverdueFines.isEmpty && !returnedOverdueFines.isEmpty {
                    // When there are only returned books
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.12))
                                .frame(width: 90, height: 90)
                            
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 8) {
                            Text("No current overdue books")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("You don't have any overdue books at the moment, but you can check your history.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            showingHistory = true
                        }) {
                            Label("View History", systemImage: "clock.arrow.circlepath")
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(20)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        Color(.systemBackground),
                                        Color.green.opacity(0.03)
                                    ]
                                ),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.green.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal)
                } else {
                    // List of books with fines (not returned only)
                    ForEach(nonReturnedOverdueFines) { fine in
                        FineDetailRow(fine: fine)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarItems(trailing: 
            Button(action: {
                showingHistory = true
            }) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.blue)
            }
        )
        .refreshable {
            await finesManager.refreshFines()
        }
        .task {
            // Load the fine policy when the view appears
            FinePolicyManager.shared.loadFinePolicy()
            await finesManager.fetchOverdueFines()
        }
        .sheet(isPresented: $showingHistory) {
            ReturnedBooksHistoryView(returnedBooks: returnedOverdueFines)
        }
    }
}

// New view for returned books history
struct ReturnedBooksHistoryView: View {
    let returnedBooks: [OverdueFine]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if returnedBooks.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                                .padding(.top, 40)
                            
                            Text("No history yet")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("You don't have any books that were returned late.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.bottom, 40)
                        }
                    } else {
                        ForEach(returnedBooks) { fine in
                            ReturnedBookHistoryRow(fine: fine)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitle("Return History", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .background(Color(.systemGroupedBackground))
        }
    }
}

// Row for returned books history
struct ReturnedBookHistoryRow: View {
    let fine: OverdueFine
    
    var daysOverdue: Int {
        if let returnDate = fine.returnDate {
            // If returned late, calculate exact days
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: fine.dueDate, to: returnDate)
            // Count at least 1 day if it was returned late at all
            return max(1, components.day ?? 0)
        }
        return 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Book title and author
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fine.bookTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(fine.bookAuthor)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Fine Amount
                Text("$\(fine.fineAmount, specifier: "%.2f")")
                    .font(.headline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.secondary)
                    .cornerRadius(8)
            }
            
            Divider()
            
            // Dates and status
            HStack {
                // Due date
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Due Date")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(fine.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                }
                
                Spacer()
                
                // Return date
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.square")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Returned On")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(fine.returnDate?.formatted(date: .abbreviated, time: .omitted) ?? "")
                        .font(.subheadline)
                }
            }
            
            // Status - always returned late
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("Returned \(daysOverdue) day\(daysOverdue == 1 ? "" : "s") late")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("Paid")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.gray)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
    }
}

struct FineDetailRow: View {
    let fine: OverdueFine
    
    var daysOverdue: Int {
        if let returnDate = fine.returnDate {
            // If the book has been returned, check if it was late
            if returnDate > fine.dueDate {
                // If returned late by any amount, count as at least 1 day late
                let calendar = Calendar.current
                let components = calendar.dateComponents([.day], from: fine.dueDate, to: returnDate)
                return max(1, components.day ?? 0)
            }
            return 0
        } else {
            // Book not returned yet, check if overdue
            let now = Date()
            if now > fine.dueDate {
                // If overdue by any amount, count as at least 1 day overdue
                let calendar = Calendar.current
                let components = calendar.dateComponents([.day], from: fine.dueDate, to: now)
                return max(1, components.day ?? 0)
            }
            return 0
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Book Cover with AsyncImage
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color.red.opacity(0.2), Color.red.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 100)
                        .shadow(color: Color.red.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    if fine.coverImage != "book.fill" {
                        AsyncImage(url: URL(string: fine.coverImage)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 50, height: 50)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 70, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Image(systemName: "book.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.red)
                            @unknown default:
                                Image(systemName: "book.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        Image(systemName: "book.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.red)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(fine.bookTitle)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Fine Badge
                        Text("$\(fine.fineAmount, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                    
                    Text(fine.bookAuthor)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Overdue Status
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fine.returnDate != nil ? "Return Status" : "Current Status")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Image(systemName: fine.returnDate != nil ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(fine.returnDate != nil ? .orange : .red)
                            if fine.returnDate != nil {
                                Text("Returned \(daysOverdue) day\(daysOverdue == 1 ? "" : "s") late")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            } else {
                                Text("Overdue by \(daysOverdue) day\(daysOverdue == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            
            // Return Dates
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Due Date")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text(fine.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if let returnDate = fine.returnDate {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("Returned On")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text(returnDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("Not Returned")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text("Still overdue")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct OverdueFinesCard: View {
    let totalAmount: Double
    let fineCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row with amount and status
            HStack(alignment: .center) {
                // Label "Total Fine Amount"
                Text("Total Fine Amount")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Amount displayed prominently
                Text("$\(totalAmount, specifier: "%.2f")")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(totalAmount > 0 ? .red : .green)
            }
            
            Divider()
            
            // Status information
            HStack {
                // Icon based on status
                Image(systemName: totalAmount > 0 ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(totalAmount > 0 ? .red : .green)
                    .frame(width: 24)
                
                // Status text
                if totalAmount > 0 {
                    Text("Due on \(fineCount) book\(fineCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("You have no overdue books!")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
} 

