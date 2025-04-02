/*
// Original User_Dashboard.swift file - functionality moved to DashboardView.swift
import SwiftUI
import Supabase

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

struct UserDashboardView: View {
    @StateObject private var booksManager = BorrowedBooksManager()
    @State private var selectedTab = 0
    @State private var isLoading = true
    @State private var showingBookManagement = false
    @State private var currentIndex = 0
    
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
                VStack(spacing: 16) {
                    // Readers Section
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
                                Text("No books in your reads")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Tap to view your books")
                                    .font(.subheadline)
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
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .onAppear {
                booksManager.fetchBorrowedBooks()
                isLoading = false
            }
            .sheet(isPresented: $showingBookManagement) {
                BookManagementView()
                    .environmentObject(booksManager)
            }
        }
    }
}

struct BookManagementView: View {
    @Environment(\.dismiss) private var dismiss
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
*/ 
