import SwiftUI
import Supabase

struct DashboardView: View {
    let supabase: SupabaseClient
    @State private var user: User?
    @State private var issuedBooks: [issueBooks] = []
    @State private var booksData: [Book] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingReadingTracker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Reading Progress Card - Always shown
                ReadingProgressCard(
                    monthlyGoal: user?.monthlyGoal ?? 0,
                    booksRead: completedBooks.count,
                    issuedBooks: issuedBooks.count
                )
                .onTapGesture {
                    showingReadingTracker = true
                }
                
                if isLoading {
                    // Loading indicator below the card
                    ProgressView("Loading your books...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    // Error message below the card
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                    
                    // Show reload button
                    Button(action: {
                        Task {
                            await fetchUserData()
                        }
                    }) {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // More dashboard content can be added here
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .onAppear {
            Task {
                await fetchUserData()
            }
        }
        .sheet(isPresented: $showingReadingTracker) {
            NavigationView {
                ReadingTrackerView(
                    user: user,
                    issuedBooks: issuedBooks,
                    booksData: booksData,
                    supabase: supabase
                )
                .navigationTitle("Reading Tracker")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingReadingTracker = false
                        }
                    }
                }
            }
        }
    }
    
    // Returns books that are considered "complete" (all pages read)
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
    
    // Fetch user data, borrowed books and corresponding book details
    private func fetchUserData() async {
        isLoading = true
        
        do {
            // Get email from UserDefaults
            guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail") else {
                errorMessage = "You need to be logged in to view your dashboard"
                isLoading = false
                return
            }
            
            // Fetch user data
            let userResponse: [User] = try await supabase
                .from("Members")
                .select("*")
                .eq("email", value: userEmail)
                .execute()
                .value
            
            if let fetchedUser = userResponse.first {
                await MainActor.run {
                    self.user = fetchedUser
                }
            } else {
                await MainActor.run {
                    errorMessage = "Could not find your profile"
                }
                return
            }
            
            // Fetch issued books for this user
            let issuedBooksResponse: [issueBooks] = try await supabase
                .from("issuebooks")
                .select("*")
                .eq("member_email", value: userEmail)
                .filter("return_date", operator: "is", value: "null") // Using "null" string instead of nil
                .execute()
                .value
            
            // Get the ISBN numbers from all issued books
            let isbnNumbers = issuedBooksResponse.map { $0.isbn }
            
            // Fetch book details for all borrowed books
            if !isbnNumbers.isEmpty {
                let booksResponse: [Book] = try await supabase
                    .from("Books")
                    .select("*")
                    .in("isbn", values: isbnNumbers)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.booksData = booksResponse
                    self.issuedBooks = issuedBooksResponse
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Error loading dashboard: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

struct ReadingProgressCard: View {
    let monthlyGoal: Int
    let booksRead: Int
    let issuedBooks: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Reading Progress")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .center, spacing: 16) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: progressPercentage)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(booksRead)")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        if monthlyGoal > 0 {
                            Text("of \(monthlyGoal)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(monthlyGoal > 0 ? "\(progressPercentage * 100, specifier: "%.0f")%" : "Set Goal")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(goalStatusText)
                            .font(.callout)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(goalStatusColor.opacity(0.2))
                            .foregroundColor(goalStatusColor)
                            .cornerRadius(4)
                    }
                    
                    Text(issuedBooks > 0 ? "\(issuedBooks) book\(issuedBooks == 1 ? "" : "s") currently borrowed" : "No books currently borrowed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var progressPercentage: Double {
        guard monthlyGoal > 0 else { return 0 }
        return min(Double(booksRead) / Double(monthlyGoal), 1.0)
    }
    
    private var goalStatusText: String {
        guard monthlyGoal > 0 else { return "No Goal" }
        
        if booksRead >= monthlyGoal {
            return "Completed"
        } else if Double(booksRead) / Double(monthlyGoal) >= 0.5 {
            return "On Track"
        } else {
            return "In Progress"
        }
    }
    
    private var goalStatusColor: Color {
        guard monthlyGoal > 0 else { return .gray }
        
        if booksRead >= monthlyGoal {
            return .green
        } else if Double(booksRead) / Double(monthlyGoal) >= 0.5 {
            return .blue
        } else {
            return .orange
        }
    }
} 