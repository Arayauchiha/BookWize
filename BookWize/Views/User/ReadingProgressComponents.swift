import SwiftUI
import Supabase

// MARK: - Reading Progress Card
struct ReadingProgressCard: View {
    let monthlyGoal: Int
    let completedBooks: Int
    let issuedBooks: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 18) {
                // Progress Ring centered
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
                .padding(.top, 10)
                
                // Statistics in 2x2 grid below the ring with more prominence
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    // Completed books
                    VStack(alignment: .center, spacing: 6) {
                        Text("\(completedBooks)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        HStack(alignment: .center, spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.subheadline)
                            Text("Completed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(8)
                    
                    // Borrowed books
                    VStack(alignment: .center, spacing: 6) {
                        Text("\(issuedBooks)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        HStack(alignment: .center, spacing: 6) {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                            Text("Borrowed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(8)
                    
                    // Goal books
                    VStack(alignment: .center, spacing: 6) {
                        Text("\(monthlyGoal)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        HStack(alignment: .center, spacing: 6) {
                            Image(systemName: "target")
                                .foregroundColor(.orange)
                                .font(.subheadline)
                            Text("Goal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(8)
                    
                    // Remaining or achieved
                    VStack(alignment: .center, spacing: 6) {
                        if completedBooks >= monthlyGoal {
                            Text("✓")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                        } else {
                            Text("\(monthlyGoal - completedBooks)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                        }
                        
                        HStack(alignment: .center, spacing: 6) {
                            Image(systemName: completedBooks >= monthlyGoal ? "star.fill" : "hourglass")
                                .foregroundColor(completedBooks >= monthlyGoal ? .yellow : .gray)
                                .font(.subheadline)
                            Text(completedBooks >= monthlyGoal ? "Achieved" : "Remaining")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(completedBooks >= monthlyGoal ? Color.yellow.opacity(0.08) : Color.gray.opacity(0.08))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Book Progress Card
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

// MARK: - Reading Progress Detail View
struct ReadingProgressDetailView: View {
    let monthlyGoal: Int
    let issuedBooks: [IssueBookInfo]
    let updatePagesRead: (UUID, Int) async -> Void
    @State private var showingGoalSheet = false
    let updateGoal: (Int) async -> Void
    @State private var completedBooksCount: Int
    
    init(monthlyGoal: Int, issuedBooks: [IssueBookInfo], updatePagesRead: @escaping (UUID, Int) async -> Void, updateGoal: @escaping (Int) async -> Void) {
        self.monthlyGoal = monthlyGoal
        self.issuedBooks = issuedBooks
        self.updatePagesRead = updatePagesRead
        self.updateGoal = updateGoal
        self._completedBooksCount = State(initialValue: issuedBooks.filter { $0.isCompleted }.count)
    }
    
    var body: some View {
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
                            .animation(.linear(duration: 0.3), value: completedBooksCount)
                        
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
                        Text(completedBooksCount > monthlyGoal 
                             ? "Congratulations! You've surpassed your monthly goal by \(completedBooksCount - monthlyGoal) \(completedBooksCount - monthlyGoal == 1 ? "book" : "books")!" 
                             : completedBooksCount >= monthlyGoal 
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
                    Text("Your Borrowed Books")
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
                                    updatePagesRead: { id, pages in
                                        Task {
                                            // Update completed books count immediately based on the new pages
                                            let newProgress = Double(pages) / Double(book.pageCount ?? 0)
                                            let wasCompleted = issueInfo.isCompleted
                                            let isNowCompleted = newProgress == 1.0
                                            
                                            if wasCompleted != isNowCompleted {
                                                if isNowCompleted {
                                                    completedBooksCount += 1
                                                } else {
                                                    completedBooksCount -= 1
                                                }
                                            }
                                            
                                            await updatePagesRead(id, pages)
                                        }
                                    }
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

// MARK: - Detailed Book Progress Row
struct DetailedBookProgressRow: View {
    let title: String
    let author: String
    let progress: Double
    let pageCount: Int
    let pagesRead: Int
    let bookId: UUID
    let updatePagesRead: (UUID, Int) async -> Void
    @State private var showingUpdateAlert = false
    @State private var pagesReadInput = ""
    @State private var currentProgress: Double
    @State private var currentPagesRead: Int
    @State private var showingCongrats = false
    @State private var showingResetAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    init(title: String, author: String, progress: Double, pageCount: Int, pagesRead: Int, bookId: UUID, updatePagesRead: @escaping (UUID, Int) async -> Void) {
        self.title = title
        self.author = author
        self.progress = progress
        self.pageCount = pageCount
        self.pagesRead = pagesRead
        self.bookId = bookId
        self.updatePagesRead = updatePagesRead
        self._currentProgress = State(initialValue: progress)
        self._currentPagesRead = State(initialValue: pagesRead)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .opacity(0.3)
                    .foregroundColor(currentProgress == 1.0 ? .green : .blue)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(currentProgress))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .foregroundColor(currentProgress == 1.0 ? .green : .blue)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear(duration: 0.3), value: currentProgress)
                
                VStack(spacing: 2) {
                    Text("\(Int(currentProgress * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(currentProgress == 1.0 ? .green : .primary)
                    
                    Text("\(currentPagesRead)/\(pageCount)")
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
                    if currentProgress == 1.0 {
                        Button("Reset") {
                            showingResetAlert = true
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(8)
                    } else {
                        Button("Update") {
                            pagesReadInput = "\(currentPagesRead)"
                            showingUpdateAlert = true
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .alert("Update Reading Progress", isPresented: $showingUpdateAlert) {
            TextField("Pages read", text: $pagesReadInput)
                .keyboardType(.numberPad)
            
            Button("Cancel", role: .cancel) { }
            
            Button("Update") {
                validateAndUpdatePages()
            }
        } message: {
            Text("Enter the number of pages you've read (out of \(pageCount))")
        }
        .alert("Invalid Input", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Reset Progress", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task {
                    print("🔄 Resetting progress for book: \(title)")
                    currentProgress = 0
                    currentPagesRead = 0
                    await updatePagesRead(bookId, 0)
                }
            }
        } message: {
            Text("Are you sure you want to reset your progress for \(title)?")
        }
        .alert("Congratulations! 🎉", isPresented: $showingCongrats) {
            Button("Thank you!", role: .cancel) { }
        } message: {
            Text("You've completed reading \(title)! Great job!")
        }
    }
    
    private func validateAndUpdatePages() {
        // Check if input is empty
        if pagesReadInput.isEmpty {
            errorMessage = "Please enter a number"
            showingErrorAlert = true
            return
        }
        
        // Check if input contains only numbers
        if !pagesReadInput.allSatisfy({ $0.isNumber }) {
            errorMessage = "Please enter only numbers"
            showingErrorAlert = true
            return
        }
        
        // Convert to integer and validate range
        if let newPagesRead = Int(pagesReadInput) {
            if newPagesRead < 0 {
                errorMessage = "Pages read cannot be negative"
                showingErrorAlert = true
                return
            }
            
            if newPagesRead > pageCount {
                errorMessage = "Pages read cannot exceed total pages (\(pageCount))"
                showingErrorAlert = true
                return
            }
            
            // Valid input, proceed with update
            Task {
                print("📝 Updating pages read from \(currentPagesRead) to \(newPagesRead) for book: \(title)")
                currentProgress = Double(newPagesRead) / Double(pageCount)
                currentPagesRead = newPagesRead
                
                if newPagesRead == pageCount {
                    showingCongrats = true
                }
                
                await updatePagesRead(bookId, newPagesRead)
            }
        } else {
            errorMessage = "Please enter a valid number"
            showingErrorAlert = true
        }
    }
}

// MARK: - Monthly Goal Sheet
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