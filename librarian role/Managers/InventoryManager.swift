import Foundation
import SwiftUI

class InventoryManager: ObservableObject {
    @Published private(set) var books: [Book] = []
    private let saveKey = "library_inventory"
    
    init() {
        loadBooks()
    }
    
    // MARK: - Book Management
    
    func addBook(_ book: Book) {
        if let index = books.firstIndex(where: { $0.isbn == book.isbn }) {
            // Update existing book
            books[index].quantity += book.quantity
            books[index].availableQuantity += book.quantity
            books[index].lastModified = Date()
        } else {
            // Add new book
            books.append(book)
        }
        saveBooks()
    }
    
    func removeBook(isbn: String) {
        books.removeAll { $0.isbn == isbn }
        saveBooks()
    }
    
    // MARK: - CSV Import
    
    func importCSV(from url: URL) throws {
        let csvString = try String(contentsOf: url, encoding: .utf8)
        let rows = csvString.components(separatedBy: "\n")
        
        // Assuming CSV format: ISBN,Title,Author,Publisher,Quantity
        for row in rows.dropFirst() { // Skip header row
            let columns = row.components(separatedBy: ",")
            guard columns.count >= 5 else { continue }
            
            let book = Book(
                isbn: columns[0].trimmingCharacters(in: .whitespacesAndNewlines),
                title: columns[1].trimmingCharacters(in: .whitespacesAndNewlines),
                author: columns[2].trimmingCharacters(in: .whitespacesAndNewlines),
                publisher: columns[3].trimmingCharacters(in: .whitespacesAndNewlines),
                quantity: Int(columns[4].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 1
            )
            addBook(book)
        }
    }
    
    // MARK: - Persistence
    
    private func saveBooks() {
        if let encoded = try? JSONEncoder().encode(books) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadBooks() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Book].self, from: data) {
            books = decoded
        }
    }
    
    // MARK: - Book Search
    
    func findBook(by isbn: String) -> Book? {
        return books.first { $0.isbn == isbn }
    }
    
    func searchBooks(query: String) -> [Book] {
        guard !query.isEmpty else { return books }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.author.localizedCaseInsensitiveContains(query) ||
            $0.isbn.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getBook(_ id: UUID) -> Book? {
        books.first { $0.id == id }
    }
    
    func updateBookAvailability(_ id: UUID, issuedCopy: Bool) {
        if let index = books.firstIndex(where: { $0.id == id }) {
            var book = books[index]
            if issuedCopy {
                book.availableQuantity -= 1
            } else {
                book.availableQuantity += 1
            }
            books[index] = book
            saveBooks()
        }
    }
}
