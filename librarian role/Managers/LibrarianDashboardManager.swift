//import Foundation
//
//class LibrarianDashboardManager: ObservableObject {
//    @Published private(set) var members: [User] = []
//    @Published private(set) var books: [Book] = []
//    @Published private(set) var totalBooksCount: Int = 0
//    @Published private(set) var issuedBooksCount: Int = 0
//    @Published private(set) var totalMembersCount: Int = 0
//    private let memberSaveKey = "library_members"
//    private let booksSaveKey = "library_books"
//    
//    init() {
//        loadMembers()
//        loadBooks()
//        Task {
//            await fetchTotalBooksCount()
//            await fetchIssuedBooksCount()
//            await fetchTotalMembersCount()
//            await loadBooksFromSupabase()
//        }
//    }
//    
//    func getMember(_ id: UUID) -> User? {
//        members.first { $0.id == id }
//    }
//    
//    // MARK: - Dashboard Stats
//    
//    var totalBooks: Int {
//        return totalBooksCount
//    }
//    
//    var issuedBooks: [Book] {
//        return books.filter { $0.availableQuantity < $0.quantity }
//    }
//    
//    var totalIssuedCount: Int {
//        return issuedBooksCount
//    }
//    
//    var totalMembers: Int {
//        return totalMembersCount
//    }
//    
//    func getPopularGenres() -> [(String, Int)] {
//        var genreCounts: [String: Int] = [:]
//        
//        // Count occurrences of each genre from all books
//        books.forEach { book in
//            if let categories = book.categories {
//                categories.forEach { genre in
//                    genreCounts[genre, default: 0] += 1
//                }
//            }
//        }
//        
//        // Sort by count and get the most frequent genre
//        if let mostPopularGenre = genreCounts.max(by: { $0.value < $1.value }) {
//            print("Most popular genre: \(mostPopularGenre.key)")
//            return [(mostPopularGenre.key, 0)] // Return 0 as count since we don't need it
//        }
//        
//        print("No genres found")
//        return []
//    }
//    
//    func getGenreWiseIssues() -> [(String, Int)] {
//        var genreIssues: [String: Int] = [:]
//        issuedBooks.forEach { book in
//            if let categories = book.categories, let firstCategory = categories.first {
//                genreIssues[firstCategory, default: 0] += (book.quantity - book.availableQuantity)
//            }
//        }
//        return genreIssues.sorted { $0.value > $1.value }
//    }
//    
//    private func fetchTotalBooksCount() async {
//        do {
//            print("Fetching total books count from Supabase...")
//            let books: [Book] = try await SupabaseManager.shared.client
//                .from("Books")
//                .select("*")
//                .execute()
//                .value
//            
//            print("Fetched \(books.count) books")
//            
//            await MainActor.run {
//                self.totalBooksCount = books.count
//                print("Updated totalBooksCount: \(self.totalBooksCount)")
//            }
//        } catch {
//            print("Error fetching total books count: \(error)")
//        }
//    }
//    
//    private func fetchIssuedBooksCount() async {
//        do {
//            print("Fetching issued books count from Supabase...")
//            let issuedBooks: [issueBooks] = try await SupabaseManager.shared.client
//                .from("issuebooks")
//                .select("*")
//                .execute()
//                .value
//            
//            print("Fetched \(issuedBooks.count) issued books")
//            
//            await MainActor.run {
//                self.issuedBooksCount = issuedBooks.count
//                print("Updated issuedBooksCount: \(self.issuedBooksCount)")
//            }
//        } catch {
//            print("Error fetching issued books count: \(error)")
//        }
//    }
//    
//    private func fetchTotalMembersCount() async {
//        do {
//            print("Fetching total members count from Supabase...")
//            let members: [User] = try await SupabaseManager.shared.client
//                .from("Members")
//                .select("*")
//                .execute()
//                .value
//            
//            print("Fetched \(members.count) members")
//            
//            await MainActor.run {
//                self.totalMembersCount = members.count
//                print("Updated totalMembersCount: \(self.totalMembersCount)")
//            }
//        } catch {
//            print("Error fetching total members count: \(error)")
//        }
//    }
//    
//    // MARK: - Persistence
//    
//    private func loadMembers() {
//        if let data = UserDefaults.standard.data(forKey: memberSaveKey),
//           let decoded = try? JSONDecoder().decode([User].self, from: data) {
//            members = decoded
//        }
//    }
//    
//    private func saveMembers() {
//        if let encoded = try? JSONEncoder().encode(members) {
//            UserDefaults.standard.set(encoded, forKey: memberSaveKey)
//        }
//    }
//    
//    private func loadBooks() {
//        if let data = UserDefaults.standard.data(forKey: booksSaveKey),
//           let decoded = try? JSONDecoder().decode([Book].self, from: data) {
//            books = decoded
//        }
//    }
//    
//    private func saveBooks() {
//        if let encoded = try? JSONEncoder().encode(books) {
//            UserDefaults.standard.set(encoded, forKey: booksSaveKey)
//        }
//    }
//    
//    private func loadBooksFromSupabase() async {
//        do {
//            print("Loading books from Supabase...")
//            let books: [Book] = try await SupabaseManager.shared.client
//                .from("Books")
//                .select("*")
//                .execute()
//                .value
//            
//            print("Loaded \(books.count) books from Supabase")
//            print("Books with categories: \(books.filter { $0.categories != nil }.count)")
//            
//            await MainActor.run {
//                self.books = books
//                self.saveBooks()
//            }
//        } catch {
//            print("Error loading books from Supabase: \(error)")
//        }
//    }
//}
