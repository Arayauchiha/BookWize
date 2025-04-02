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
            VStack(alignment: .leading, spacing: 15) {
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
                    
                    Spacer() // Add this spacer to stretch content horizontally
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
            .frame(maxWidth: .infinity, alignment: .leading)
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
    
    // Calculated completed books count
    var completedBooksCount: Int {
        let completed = issuedBooks.filter { $0.isCompleted }.count
        print("📚 Calculating completed books: \(completed) books are 100% complete")
        return completed
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
                        pagesReadInput = "\(pagesRead)"
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .alert("Update Reading Progress", isPresented: $showingUpdateAlert) {
            TextField("Pages read", text: $pagesReadInput)
                .keyboardType(.numberPad)
            
            Button("Cancel", role: .cancel) { }
            
            Button("Update") {
                if let newPagesRead = Int(pagesReadInput), newPagesRead >= 0, newPagesRead <= pageCount {
                    Task {
                        print("📝 Updating pages read from \(pagesRead) to \(newPagesRead) for book: \(title)")
                        await updatePagesRead(bookId, newPagesRead)
                    }
                }
            }
        } message: {
            Text("Enter the number of pages you've read (out of \(pageCount))")
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