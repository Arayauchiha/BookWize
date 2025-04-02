import SwiftUI
import Supabase

// MARK: - Models
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

// MARK: - View Models
class BorrowedBooksManager: ObservableObject {
    @Published var borrowedBooks: [BorrowedBook] = []
    
    func fetchBorrowedBooks() {
        // TODO: Implement API call to fetch borrowed books
        // For now, using sample data with different due dates
        borrowedBooks = [
            BorrowedBook(id: "1", title: "The Great Gatsby", author: "F. Scott Fitzgerald", coverImage: "book.fill", issueDate: Date().addingTimeInterval(-10*24*60*60), dueDate: Date().addingTimeInterval(-2*24*60*60), progress: 0.6, status: .borrowed),
            BorrowedBook(id: "2", title: "1984", author: "George Orwell", coverImage: "book.fill", issueDate: Date(), dueDate: Date().addingTimeInterval(5*24*60*60), progress: 0.3, status: .borrowed),
            BorrowedBook(id: "3", title: "To Kill a Mockingbird", author: "Harper Lee", coverImage: "book.fill", issueDate: Date(), dueDate: Date().addingTimeInterval(7*24*60*60), progress: 0.8, status: .borrowed),
            BorrowedBook(id: "4", title: "The Hobbit", author: "J.R.R. Tolkien", coverImage: "book.fill", issueDate: Date(), dueDate: Date().addingTimeInterval(10*60*60), progress: 0.4, status: .borrowed)
        ]
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
    
    // Reading progress tracking
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
        NavigationView {
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
                        // Your Reads Section
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                showingBookManagement = true
                            }) {
                                HStack {
                                    Text("Your Reads")
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
                        
                        // Monthly Reading Goal Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Monthly Reading Goal")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ReadingProgressCard(
                                monthlyGoal: user?.monthlyGoal ?? 0,
                                completedBooks: completedBooksCount,
                                issuedBooks: issuedBooks.count,
                                onTap: { showReadingTracker = true }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .onAppear {
                Task {
                    await fetchUserData()
                    booksManager.fetchBorrowedBooks()
                }
            }
            .sheet(isPresented: $showingBookManagement) {
                BookManagementView()
                    .environmentObject(booksManager)
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
            
            // Update locally
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
            
            // Refresh data to ensure UI consistency
            await fetchUserData()
        } catch {
            print("❌ Error updating pages read: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct ReadingProgressCard: View {
    let monthlyGoal: Int
    let completedBooks: Int
    let issuedBooks: Int
    let onTap: () -> Void
    @State private var showingGoalSheet = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Monthly Reading Goal")
                        .font(.headline)
                        .foregroundColor(.primary)
                        
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 20) {
                    // Progress Ring
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 10)
                            .opacity(0.3)
                            .foregroundColor(Color.blue)
                        
                        Circle()
                            .trim(from: 0.0, to: monthlyGoal > 0 ? CGFloat(min(Double(completedBooks) / Double(monthlyGoal), 1.0)) : 0)
                            .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                            .foregroundColor(Color.blue)
                            .rotationEffect(Angle(degrees: 270.0))
                            .animation(.linear, value: completedBooks)
                        
                        VStack {
                            Text("\(completedBooks)/\(monthlyGoal)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Books")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 140, height: 140)
                    
                    // Statistics
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("\(completedBooks) completed")
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                            Text("\(issuedBooks) borrowed")
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.orange)
                            Text("Goal: \(monthlyGoal) books")
                                .font(.subheadline)
                        }
                        
                        if monthlyGoal > 0 {
                            HStack {
                                Image(systemName: completedBooks >= monthlyGoal ? "star.fill" : "hourglass")
                                    .foregroundColor(completedBooks >= monthlyGoal ? .yellow : .gray)
                                Text(completedBooks >= monthlyGoal 
                                     ? "Goal achieved! 🎉" 
                                     : "\(monthlyGoal - completedBooks) more to go!")
                                    .font(.subheadline)
                                    .foregroundColor(completedBooks >= monthlyGoal ? .green : .secondary)
                            }
                        }
                    }
                    .padding(.leading, 10)
                }
                .padding(.vertical, 10)
                
                // Status message
                if monthlyGoal > 0 {
                    Text(completedBooks >= monthlyGoal 
                         ? "Amazing! You've reached your monthly goal! Keep reading to surpass it!" 
                         : "Keep reading to reach your monthly goal!")
                        .font(.subheadline)
                        .foregroundColor(completedBooks >= monthlyGoal ? .green : .secondary)
                        .padding(.top, 5)
                } else {
                    Text("Set a monthly reading goal to track your progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BookProgressCard: View {
    let title: String
    let author: String
    let progress: Double
    let pageCount: Int
    let pagesRead: Int
    let onTap: () async -> Void
    
    var body: some View {
        Button(action: {
            Task {
                await onTap()
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Book title and author
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(lineWidth: 6)
                        .opacity(0.3)
                        .foregroundColor(Color.blue)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(progress))
                        .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.blue)
                        .rotationEffect(Angle(degrees: 270.0))
                    
                    VStack {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .bold))
                        
                        Text("\(pagesRead)/\(pageCount)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 80, height: 80)
                .padding(.top, 5)
            }
            .frame(width: 120)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReadingProgressDetailView: View {
    let monthlyGoal: Int
    let issuedBooks: [DashboardView.IssueBookInfo]
    let updatePagesRead: (UUID, Int) async -> Void
    @State private var showingGoalSheet = false
    let updateGoal: (Int) async -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Summary
                    VStack(spacing: 10) {
                        // Large progress ring
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 15)
                                .opacity(0.3)
                                .foregroundColor(Color.blue)
                            
                            Circle()
                                .trim(from: 0.0, to: monthlyGoal > 0 ? CGFloat(min(Double(completedBooksCount) / Double(monthlyGoal), 1.0)) : 0)
                                .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                                .foregroundColor(Color.blue)
                                .rotationEffect(Angle(degrees: 270.0))
                            
                            VStack {
                                Text("\(completedBooksCount)")
                                    .font(.system(size: 40, weight: .bold))
                                
                                Text("of \(monthlyGoal)")
                                    .font(.headline)
                                
                                Text("Books Complete")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 200, height: 200)
                        .padding(.bottom, 10)
                        
                        // Status text
                        if monthlyGoal > 0 {
                            Text(completedBooksCount >= monthlyGoal 
                                 ? "Congratulations! You've reached your monthly goal of \(monthlyGoal) books!" 
                                 : "You're making progress towards your monthly goal of \(monthlyGoal) books!")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(completedBooksCount >= monthlyGoal ? .green : .primary)
                                .padding(.horizontal)
                        } else {
                            Text("Set a monthly reading goal to track your progress")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            showingGoalSheet = true
                        }) {
                            HStack {
                                Image(systemName: "target")
                                Text("Set Reading Goal")
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(20)
                        }
                        .padding(.top, 5)
                    }
                    .padding()
                    
                    // Reading Progress List
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Reading Progress")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if issuedBooks.isEmpty {
                            Text("You don't have any borrowed books")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(issuedBooks) { issueInfo in
                                if let book = issueInfo.book {
                                    DetailedBookProgressRow(
                                        title: book.title,
                                        author: book.author,
                                        progress: issueInfo.progress,
                                        pageCount: book.pageCount ?? 0,
                                        pagesRead: issueInfo.issueBook.pagesRead ?? 0,
                                        bookId: issueInfo.issueBook.id,
                                        updatePagesRead: updatePagesRead
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Reading Progress")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingGoalSheet) {
                MonthlyGoalSheet(
                    currentGoal: monthlyGoal,
                    updateGoal: updateGoal
                )
            }
            .onAppear {
                print("📊 Reading Progress View appeared with monthly goal: \(monthlyGoal)")
                print("📚 Total books completed: \(completedBooksCount) of \(issuedBooks.count) books")
            }
        }
    }
    
    // Calculated completed books count
    var completedBooksCount: Int {
        let completed = issuedBooks.filter { $0.isCompleted }.count
        print("📚 Calculating completed books: \(completed) books are 100% complete")
        return completed
    }
}

struct DetailedBookProgressRow: View {
    let title: String
    let author: String
    let progress: Double
    let pageCount: Int
    let pagesRead: Int
    let bookId: UUID
    let updatePagesRead: (UUID, Int) async -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .opacity(0.3)
                    .foregroundColor(progress == 1.0 ? .green : .blue)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .foregroundColor(progress == 1.0 ? .green : .blue)
                    .rotationEffect(Angle(degrees: 270.0))
                
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(progress == 1.0 ? .green : .primary)
                    
                    Text("\(pagesRead)/\(pageCount)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, height: 80)
            
            // Book Details and Input
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Spacer()
                    Button("Update") {
                        presentUpdateAlert()
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
    
    // Rewritten alert presentation method
    private func presentUpdateAlert() {
        guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
            print("❌ Could not find root view controller")
            return
        }
        
        let alert = UIAlertController(
            title: "Update Reading Progress",
            message: "Enter the number of pages you've read (out of \(pageCount))",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.keyboardType = .numberPad
            textField.text = "\(pagesRead)"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let updateAction = UIAlertAction(title: "Update", style: .default) { _ in
            guard let textField = alert.textFields?.first,
                  let text = textField.text,
                  let newPagesRead = Int(text) else {
                return
            }
            
            // Validate the input
            if newPagesRead > pageCount {
                self.presentErrorAlert(message: "Pages read cannot exceed the total page count.")
                return
            }
            
            if newPagesRead < 0 {
                self.presentErrorAlert(message: "Pages read cannot be negative.")
                return
            }
            
            // Update reading progress
            Task {
                await updatePagesRead(bookId, newPagesRead)
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(updateAction)
        
        DispatchQueue.main.async {
            rootVC.present(alert, animated: true)
        }
    }
    
    private func presentErrorAlert(message: String) {
        guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
            print("❌ Could not find root view controller")
            return
        }
        
        let alert = UIAlertController(
            title: "Invalid Input",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        DispatchQueue.main.async {
            rootVC.present(alert, animated: true)
        }
    }
}

struct MonthlyGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var goalValue: Double
    let currentGoal: Int
    let maxGoal = 5
    let updateGoal: (Int) async -> Void
    
    init(currentGoal: Int, updateGoal: @escaping (Int) async -> Void) {
        self._goalValue = State(initialValue: Double(max(currentGoal, 0)))
        self.currentGoal = max(currentGoal, 0)
        self.updateGoal = updateGoal
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Set Monthly Reading Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 10) {
                    Text("\(Int(goalValue))")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("books per month")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                VStack(spacing: 15) {
                    Slider(value: $goalValue, in: 0...Double(maxGoal), step: 1)
                        .accentColor(.blue)
                        .padding(.horizontal)
                    
                    HStack {
                        Text("0")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(maxGoal)")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Guidelines:")
                        .font(.headline)
                    
                    Text("• Start with a realistic goal")
                        .font(.subheadline)
                    
                    Text("• You can update your goal anytime")
                        .font(.subheadline)
                    
                    Text("• Maximum of \(maxGoal) books per month")
                        .font(.subheadline)
                    
                    Text("• Set to 0 to disable goal tracking")
                        .font(.subheadline)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    Task {
                        print("📊 Saving monthly goal: \(Int(goalValue))")
                        await updateGoal(Int(goalValue))
                        dismiss()
                    }
                }) {
                    Text("Save Goal")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
}

struct BookManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var booksManager: BorrowedBooksManager
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("My Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
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
                if booksManager.borrowedBooks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No borrowed books")
                            .font(.headline)
                            .foregroundColor(.gray)
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
    }
}

struct BorrowedBookRow: View {
    let book: BorrowedBook
    
    var timeRemaining: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: book.dueDate)
        
        if let days = components.day {
            if days < 0 {
                return "Overdue by \(abs(days)) day\(abs(days) == 1 ? "" : "s")"
            } else if days == 0 {
                if let hours = components.hour {
                    if hours > 0 {
                        return "\(hours) hour\(hours == 1 ? "" : "s") left"
                    } else if let minutes = components.minute {
                        return "\(minutes) minute\(minutes == 1 ? "" : "s") left"
                    }
                }
                return "Less than a minute left"
            } else {
                return "\(days) day\(days == 1 ? "" : "s") left"
            }
        }
        return ""
    }
    
    var timeRemainingColor: Color {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour], from: now, to: book.dueDate)
        
        if let days = components.day {
            if days < 0 {
                return .red
            } else if days == 0 {
                if let hours = components.hour {
                    if hours <= 2 {
                        return .red
                    } else if hours <= 6 {
                        return .orange
                    } else {
                        return .orange
                    }
                }
                return .red
            } else if days <= 1 {
                return .orange
            } else {
                return .blue
            }
        }
        return .gray
    }
    
    var isOverdue: Bool {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: book.dueDate)
        return (components.day ?? 0) < 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Book Cover
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 100)
                        .shadow(color: Color.blue.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: book.coverImage)
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
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
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<2) { _ in
                    ReservedBookRow()
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct ReturnedBooksView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<5) { _ in
                    ReturnedBookRow()
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct ReservedBookRow: View {
    // Sample data - in real app, this would come from a model
    let reservationDate = Date().addingTimeInterval(-12*60*60) // 12 hours ago
    let holdUntilDate = Date().addingTimeInterval(12*60*60) // 12 hours remaining
    
    var remainingHours: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour], from: now, to: holdUntilDate)
        return components.hour ?? 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Book Cover
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 100)
                        .shadow(color: Color.blue.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("1984")
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
                    
                    Text("George Orwell")
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
            
            // Reservation Details and Actions
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
                    Text(reservationDate.formatted(date: .abbreviated, time: .omitted))
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
                    Text(holdUntilDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    // Add cancel reservation action
                }) {
                    Text("Cancel")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ReturnedBookRow: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Book Cover with Enhanced Visual
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 100)
                        .shadow(color: Color.blue.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    // Book Icon with Background
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "book.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("To Kill a Mockingbird")
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Enhanced Status Badge
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
                    
                    Text("Harper Lee")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Enhanced Return Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Return Status")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Returned 2 days ago")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            // Enhanced Return Details
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
                    Text("Mar 16, 2024")
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
                    Text("Mar 22, 2024")
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