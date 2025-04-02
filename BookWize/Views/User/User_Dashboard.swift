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

// All code below is commented out as it's been migrated to DashboardView and ReadingProgressComponents
*/ 
