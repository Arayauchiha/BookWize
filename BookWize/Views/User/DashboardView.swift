import SwiftUI
import Supabase

struct DashboardView: View {
    @State private var user: User?
    @State private var issuedBooks: [IssueBookInfo] = []
    @State private var booksData: [BookData] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showReadingTracker = false
    @State private var goalSliderValue: Double = 1
    @State private var showingGoalSheet = false
    
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
                        // Reading Progress Card
                        ReadingProgressCard(
                            monthlyGoal: user?.monthlyGoal ?? 0,
                            completedBooks: completedBooksCount,
                            issuedBooks: issuedBooks.count,
                            onTap: { showReadingTracker = true }
                        )
                        .padding(.horizontal)
                        
                        // Borrowed Books section - only show if there are books
                        if !issuedBooks.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Your Borrowed Books")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top, 5)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 15) {
                                        ForEach(issuedBooks) { issueInfo in
                                            if let book = issueInfo.book {
                                                BookProgressCard(
                                                    title: book.title,
                                                    author: book.author,
                                                    progress: issueInfo.progress,
                                                    pageCount: book.pageCount ?? 0,
                                                    pagesRead: issueInfo.issueBook.pagesRead ?? 0
                                                ) {
                                                    // Update pages read action
                                                    await updatePagesRead(for: issueInfo.issueBook.id)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        } else {
                            // Empty state for no borrowed books
                            VStack(spacing: 10) {
                                Image(systemName: "books.vertical")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                
                                Text("No Books Borrowed")
                                    .font(.headline)
                                
                                Text("Explore our collection and borrow books to track your reading progress.")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingGoalSheet = true
                    }) {
                        Image(systemName: "target")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showReadingTracker) {
                ReadingProgressDetailView(
                    monthlyGoal: user?.monthlyGoal ?? 0, 
                    issuedBooks: issuedBooks,
                    updatePagesRead: updatePagesRead
                )
            }
            .sheet(isPresented: $showingGoalSheet) {
                MonthlyGoalSheet(
                    currentGoal: user?.monthlyGoal ?? 0,
                    updateGoal: updateMonthlyGoal
                )
            }
        }
        .onAppear {
            Task {
                await fetchUserData()
            }
        }
    }
    
    // Calculated completed books count
    var completedBooksCount: Int {
        issuedBooks.filter { $0.isCompleted }.count
    }
    
    // Fetch user data and borrowed books
    private func fetchUserData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First fetch the current member
            guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail"),
                  let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            }
            
            // Fetch user data
            let response: [User] = try await SupabaseManager.shared.client
                .from("Members")
                .select("*")
                .eq("email", value: userEmail)
                .execute()
                .value
            
            guard let fetchedUser = response.first else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
            }
            
            // Fetch issued books for this member
            let issueBooksResponse = try await SupabaseManager.shared.client
                .from("issuebooks")
                .select("*")
                .eq("member_email", value: userEmail)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Parse the response to get issued books
            let data = issueBooksResponse.data
            if let jsonString = String(data: data, encoding: .utf8),
               let jsonData = jsonString.data(using: .utf8) {
                
                let issuedBooksArray = try decoder.decode([issueBooks].self, from: jsonData)
                var issueInfoArray: [IssueBookInfo] = []
                
                // Fetch book details for each issued book
                for issuedBook in issuedBooksArray {
                    let bookResponse = try await SupabaseManager.shared.client
                        .from("Books")
                        .select("id, title, author, pageCount")
                        .eq("isbn", value: issuedBook.isbn)
                        .execute()
                    
                    let bookData = bookResponse.data
                    if let bookJsonString = String(data: bookData, encoding: .utf8),
                       let bookJsonData = bookJsonString.data(using: .utf8) {
                        
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
                    }
                }
                
                await MainActor.run {
                    self.user = fetchedUser
                    self.issuedBooks = issueInfoArray
                    self.goalSliderValue = Double(fetchedUser.monthlyGoal ?? 1)
                    self.isLoading = false
                }
            }
        } catch {
            print("Error fetching data: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // Update pages read for a book
    private func updatePagesRead(for bookId: UUID) async {
        // Find the book in our local array
        guard let index = issuedBooks.firstIndex(where: { $0.issueBook.id == bookId }) else {
            return
        }
        
        let currentPages = issuedBooks[index].issueBook.pagesRead ?? 0
        let totalPages = issuedBooks[index].book?.pageCount ?? 100
        
        // Show an input dialog to update pages
        let updateSheet = UIAlertController(
            title: "Update Reading Progress",
            message: "Enter the number of pages you've read (out of \(totalPages))",
            preferredStyle: .alert
        )
        
        updateSheet.addTextField { textField in
            textField.keyboardType = .numberPad
            textField.text = "\(currentPages)"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let updateAction = UIAlertAction(title: "Update", style: .default) { _ in
            guard let textField = updateSheet.textFields?.first,
                  let pagesText = textField.text,
                  let pagesRead = Int(pagesText) else {
                return
            }
            
            // Ensure pages read doesn't exceed total pages
            let validPagesRead = min(pagesRead, totalPages)
            
            Task {
                do {
                    // Update in Supabase
                    try await SupabaseManager.shared.client
                        .from("issuebooks")
                        .update(["pages_read": validPagesRead])
                        .eq("id", value: bookId)
                        .execute()
                    
                    // Update locally
                    await MainActor.run {
                        var updatedIssueBook = issuedBooks[index].issueBook
                        updatedIssueBook.pagesRead = validPagesRead
                        issuedBooks[index] = IssueBookInfo(
                            id: updatedIssueBook.id,
                            issueBook: updatedIssueBook,
                            book: issuedBooks[index].book
                        )
                    }
                } catch {
                    print("Error updating pages read: \(error)")
                }
            }
        }
        
        updateSheet.addAction(cancelAction)
        updateSheet.addAction(updateAction)
        
        // Present the alert controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(updateSheet, animated: true)
        }
    }
    
    // Update monthly reading goal
    private func updateMonthlyGoal(_ goal: Int) async {
        do {
            guard let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            }
            
            // Update in Supabase
            try await SupabaseManager.shared.client
                .from("Members")
                .update(["monthly_goal": goal])
                .eq("id", value: userId)
                .execute()
            
            // Update locally
            await MainActor.run {
                var updatedUser = self.user
                updatedUser?.monthlyGoal = goal
                self.user = updatedUser
            }
        } catch {
            print("Error updating monthly goal: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct ReadingProgressCard: View {
    let monthlyGoal: Int
    let completedBooks: Int
    let issuedBooks: Int
    let onTap: () -> Void
    
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
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Books")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 120, height: 120)
                    
                    // Statistics
                    VStack(alignment: .leading, spacing: 8) {
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
                    }
                }
                
                // Status message
                if monthlyGoal > 0 {
                    Text(completedBooks >= monthlyGoal 
                         ? "Amazing! You've reached your monthly goal! 🎉" 
                         : "Keep reading to reach your monthly goal!")
                        .font(.caption)
                        .foregroundColor(completedBooks >= monthlyGoal ? .green : .secondary)
                } else {
                    Text("Set a monthly reading goal to track your progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
    let updatePagesRead: (UUID) async -> Void
    
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
                    }
                    .padding()
                    
                    // Borrowed Books List
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
                                        pagesRead: issueInfo.issueBook.pagesRead ?? 0
                                    ) {
                                        await updatePagesRead(issueInfo.issueBook.id)
                                    }
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
        }
    }
    
    // Calculated completed books count
    var completedBooksCount: Int {
        issuedBooks.filter { $0.isCompleted }.count
    }
}

struct DetailedBookProgressRow: View {
    let title: String
    let author: String
    let progress: Double
    let pageCount: Int
    let pagesRead: Int
    let onUpdateTap: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Book details
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("\(pagesRead) of \(pageCount) pages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(progress == 1.0 ? .green : .blue)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 10)
                            .opacity(0.3)
                            .foregroundColor(Color.blue)
                        
                        Rectangle()
                            .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width), height: 10)
                            .foregroundColor(progress == 1.0 ? .green : .blue)
                    }
                    .cornerRadius(5)
                }
                .frame(height: 10)
            }
            
            // Update button
            Button(action: {
                Task {
                    await onUpdateTap()
                }
            }) {
                Text("Update Progress")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

struct MonthlyGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var goalValue: Double
    let currentGoal: Int
    let maxGoal = 5
    let updateGoal: (Int) async -> Void
    
    init(currentGoal: Int, updateGoal: @escaping (Int) async -> Void) {
        self._goalValue = State(initialValue: Double(currentGoal))
        self.currentGoal = currentGoal
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
                    Slider(value: $goalValue, in: 1...Double(maxGoal), step: 1)
                        .accentColor(.blue)
                        .padding(.horizontal)
                    
                    HStack {
                        Text("1")
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
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    Task {
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