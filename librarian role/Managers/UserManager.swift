import Foundation

class UserManager: ObservableObject {
    @Published private(set) var members: [Member] = []
    @Published private(set) var books: [Book] = []
    private let membersSaveKey = "library_members"
    private let booksSaveKey = "library_books"
    
    init() {
        loadMembers()
        loadBooks()
    }
    
    func getMember(_ id: UUID) -> Member? {
        members.first { $0.id == id }
    }
    
    // MARK: - Dashboard Stats
    
    var totalBooks: Int {
        return books.reduce(0) { $0 + $1.quantity }
    }
    
    var issuedBooks: [Book] {
        return books.filter { $0.availableQuantity < $0.quantity }
    }
    
    var totalIssuedCount: Int {
        return books.reduce(0) { $0 + ($1.quantity - $1.availableQuantity) }
    }
    
    func getPopularGenres() -> [(String, Int)] {
        var genreCounts: [String: Int] = [:]
        books.forEach { book in
            if let categories = book.categories, let firstCategory = categories.first {
                genreCounts[firstCategory, default: 0] += (book.quantity - book.availableQuantity)
            }
        }
        return genreCounts.sorted { $0.value > $1.value }
    }
    
    func getGenreWiseIssues() -> [(String, Int)] {
        var genreIssues: [String: Int] = [:]
        issuedBooks.forEach { book in
            if let categories = book.categories, let firstCategory = categories.first {
                genreIssues[firstCategory, default: 0] += (book.quantity - book.availableQuantity)
            }
        }
        return genreIssues.sorted { $0.value > $1.value }
    }
    
    // MARK: - Persistence
    
    private func loadMembers() {
        if let data = UserDefaults.standard.data(forKey: membersSaveKey),
           let decoded = try? JSONDecoder().decode([Member].self, from: data) {
            members = decoded
        }
    }
    
    private func saveMembers() {
        if let encoded = try? JSONEncoder().encode(members) {
            UserDefaults.standard.set(encoded, forKey: membersSaveKey)
        }
    }
    
    private func loadBooks() {
        if let data = UserDefaults.standard.data(forKey: booksSaveKey),
           let decoded = try? JSONDecoder().decode([Book].self, from: data) {
            books = decoded
        }
    }
    
    private func saveBooks() {
        if let encoded = try? JSONEncoder().encode(books) {
            UserDefaults.standard.set(encoded, forKey: booksSaveKey)
        }
    }
}
