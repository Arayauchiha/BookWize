import SwiftUI
import Supabase

struct ReadingTrackerView: View {
    let user: User?
    let issuedBooks: [issueBooks]
    let booksData: [Book]
    let supabase: SupabaseClient
    
    @State private var showingGoalPicker = false
    @State private var selectedGoal: Int
    @State private var isUpdatingGoal = false
    @State private var goalError: String?
    
    init(user: User?, issuedBooks: [issueBooks], booksData: [Book], supabase: SupabaseClient) {
        self.user = user
        self.issuedBooks = issuedBooks
        self.booksData = booksData
        self.supabase = supabase
        _selectedGoal = State(initialValue: user?.monthlyGoal ?? 0)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Monthly Reading Goal Section
                monthlyGoalSection
                
                Divider()
                    .padding(.vertical, 8)
                
                // Borrowed Books Progress Section
                if !issuedBooks.isEmpty {
                    borrowedBooksSection
                } else {
                    emptyBorrowedBooksView
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Monthly Goal Section
    private var monthlyGoalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Reading Goal")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: goalProgress)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(completedBooks.count)")
                            .font(.system(size: 28, weight: .bold))
                        
                        if selectedGoal > 0 {
                            Text("of \(selectedGoal)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Goal Setting
                    Button(action: {
                        showingGoalPicker = true
                    }) {
                        HStack {
                            Text("Set Goal")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(selectedGoal > 0 ? "\(selectedGoal) books" : "Not Set")
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    if let error = goalError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    if selectedGoal > 0 {
                        Text("You've completed \(Int(goalProgress * 100))% of your monthly reading goal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        Text("Set a monthly reading goal to track your progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .sheet(isPresented: $showingGoalPicker) {
            monthlyGoalPickerView
        }
    }
    
    // MARK: - Borrowed Books Section
    private var borrowedBooksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Books You're Reading")
                .font(.headline)
            
            ForEach(issuedBooks, id: \.id) { issuedBook in
                if let book = booksData.first(where: { $0.isbn == issuedBook.isbn }) {
                    BookProgressRow(
                        book: book,
                        issuedBook: issuedBook,
                        supabase: supabase,
                        onPagesUpdated: { updatedPages in
                            // Update the pages read in our local copy
                            if let index = self.issuedBooks.firstIndex(where: { $0.id == issuedBook.id }) {
                                var updatedBook = self.issuedBooks[index]
                                updatedBook.pagesRead = updatedPages
                                // Since we can't directly modify the array element, we'd need to use a state variable
                                // This is handled by the parent view that passes in the issuedBooks
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var emptyBorrowedBooksView: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Books Borrowed")
                .font(.headline)
            
            Text("Visit the Explore tab to find and borrow books")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Goal Picker View
    private var monthlyGoalPickerView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Set a monthly reading goal")
                    .font(.headline)
                    .padding(.top)
                
                Text("Choose how many books you want to read this month (maximum 5)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Picker("Monthly Goal", selection: $selectedGoal) {
                    ForEach(0...5, id: \.self) { number in
                        Text(number == 0 ? "No Goal" : "\(number) book\(number == 1 ? "" : "s")")
                            .tag(number)
                    }
                }
                .pickerStyle(.wheel)
                .padding()
                
                Button(action: updateMonthlyGoal) {
                    HStack {
                        if isUpdatingGoal {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.trailing, 8)
                        }
                        
                        Text("Save Goal")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isUpdatingGoal)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingGoalPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private var completedBooks: [issueBooks] {
        return issuedBooks.filter { issuedBook in
            if let pagesRead = issuedBook.pagesRead,
               let book = booksData.first(where: { $0.isbn == issuedBook.isbn }),
               let totalPages = book.pageCount {
                return pagesRead >= totalPages
            }
            return false
        }
    }
    
    private var goalProgress: Double {
        guard selectedGoal > 0 else { return 0 }
        return min(Double(completedBooks.count) / Double(selectedGoal), 1.0)
    }
    
    private func updateMonthlyGoal() {
        isUpdatingGoal = true
        goalError = nil
        
        guard let user = user else {
            goalError = "User profile not found"
            isUpdatingGoal = false
            return
        }
        
        Task {
            do {
                try await supabase
                    .from("Members")
                    .update(["monthly_goal": selectedGoal])
                    .eq("id", value: user.id)
                    .execute()
                
                await MainActor.run {
                    isUpdatingGoal = false
                    showingGoalPicker = false
                }
            } catch {
                await MainActor.run {
                    goalError = "Failed to update goal: \(error.localizedDescription)"
                    isUpdatingGoal = false
                }
            }
        }
    }
} 