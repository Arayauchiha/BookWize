import Foundation

class DashboardManager: ObservableObject {
    @Published private(set) var totalBooksCount: Int = 0
    @Published private(set) var issuedBooksCount: Int = 0
    @Published private(set) var totalMembersCount: Int = 0
    @Published private(set) var totalRevenue: Double = 0
    @Published private(set) var overdueFines: Double = 0
    @Published private(set) var activeLibrariansCount: Int = 0
    @Published private(set) var books: [Book] = []
    
    init() {
        Task {
            await fetchDashboardData()
        }
    }
    
    func fetchDashboardData() async {
        await fetchTotalBooksCount()
        await fetchIssuedBooksCount()
        await fetchTotalMembersCount()
        await fetchRevenueAndFines()
        await fetchActiveLibrariansCount()
        await loadBooksFromSupabase()
    }
    
    private func fetchTotalBooksCount() async {
        do {
            print("Fetching total books count from Supabase...")
            let books: [Book] = try await SupabaseManager.shared.client
                .from("Books")
                .select("*")
                .execute()
                .value
            
            print("Fetched \(books.count) books")
            
            await MainActor.run {
                self.totalBooksCount = books.count
                print("Updated totalBooksCount: \(self.totalBooksCount)")
            }
        } catch {
            print("Error fetching total books count: \(error)")
        }
    }
    
    private func fetchIssuedBooksCount() async {
        do {
            print("Fetching issued books count from Supabase...")
            let issuedBooks: [issueBooks] = try await SupabaseManager.shared.client
                .from("issuebooks")
                .select("*")
                .execute()
                .value
            
            print("Fetched \(issuedBooks.count) issued books")
            
            await MainActor.run {
                self.issuedBooksCount = issuedBooks.count
                print("Updated issuedBooksCount: \(self.issuedBooksCount)")
            }
        } catch {
            print("Error fetching issued books count: \(error)")
        }
    }
    
    private func fetchTotalMembersCount() async {
        do {
            print("Fetching total members count from Supabase...")
            let members: [User] = try await SupabaseManager.shared.client
                .from("Members")
                .select("*")
                .execute()
                .value
            
            print("Fetched \(members.count) members")
            
            await MainActor.run {
                self.totalMembersCount = members.count
                print("Updated totalMembersCount: \(self.totalMembersCount)")
            }
        } catch {
            print("Error fetching total members count: \(error)")
        }
    }
    
    private func fetchRevenueAndFines() async {
        do {
            let client = SupabaseManager.shared.client
            
            // Define the required structs
            struct MembershipSetting: Codable {
                let Membership: Double?
                let PerDayFine: Double?
                let FineSet_id: UUID?
            }
            
            struct Fine: Codable {
                let fineAmount: Double?
                let id: UUID?
            }
            
            // Fetch membership fee and members count
            let membershipFeeResponse: [MembershipSetting] = try await client
                .from("FineAndMembershipSet")
                .select("*")
                .execute()
                .value
            
            let membershipFee = membershipFeeResponse.first?.Membership ?? 0.0
            
            let membersCount: Int = try await client
                .from("Members")
                .select("*", head: true)
                .execute()
                .count ?? 0
            
            let membershipRevenue = Double(membersCount) * membershipFee
            
            // Fetch fines
            let finesResponse: [Fine] = try await client
                .from("issuebooks")
                .select("fineAmount, id")
                .execute()
                .value
            
            let totalFines = finesResponse.reduce(0.0) { sum, fine in
                sum + (fine.fineAmount ?? 0)
            }
            
            // Calculate total revenue
            let totalAmount = membershipRevenue + totalFines
            
            await MainActor.run {
                self.totalRevenue = totalAmount
                self.overdueFines = totalFines
            }
        } catch {
            print("Error fetching revenue and fines: \(error)")
        }
    }
    
    private func fetchActiveLibrariansCount() async {
        do {
            struct LibrarianUser: Codable {
                var email: String
                var roleFetched: String
                var status: String
            }
            
            let librarians: [LibrarianUser] = try await SupabaseManager.shared.client
                .from("Users")
                .select("email, roleFetched, status")
                .eq("roleFetched", value: "librarian")
                .eq("status", value: "working")
                .execute()
                .value
            
            await MainActor.run {
                self.activeLibrariansCount = librarians.count
            }
        } catch {
            print("Error fetching active librarians count: \(error)")
        }
    }
    
    private func loadBooksFromSupabase() async {
        do {
            print("Loading books from Supabase...")
            let books: [Book] = try await SupabaseManager.shared.client
                .from("Books")
                .select("*")
                .execute()
                .value
            
            print("Loaded \(books.count) books from Supabase")
            print("Books with categories: \(books.filter { $0.categories != nil }.count)")
            
            await MainActor.run {
                self.books = books
            }
        } catch {
            print("Error loading books from Supabase: \(error)")
        }
    }
    
    func getPopularGenres() -> [(String, Int)] {
        var genreCounts: [String: Int] = [:]
        
        // Count occurrences of each genre from all books
        books.forEach { book in
            if let categories = book.categories {
                categories.forEach { genre in
                    genreCounts[genre, default: 0] += 1
                }
            }
        }
        
        // Sort by count and get the most frequent genre
        if let mostPopularGenre = genreCounts.max(by: { $0.value < $1.value }) {
            print("Most popular genre: \(mostPopularGenre.key)")
            return [(mostPopularGenre.key, 0)] // Return 0 as count since we don't need it
        }
        
        print("No genres found")
        return []
    }
    
    func getGenreWiseIssues() -> [(String, Int)] {
        var genreIssues: [String: Int] = [:]
        
        // Get issued books
        let issuedBooks = books.filter { $0.availableQuantity < $0.quantity }
        
        issuedBooks.forEach { book in
            if let categories = book.categories, let firstCategory = categories.first {
                genreIssues[firstCategory, default: 0] += (book.quantity - book.availableQuantity)
            }
        }
        
        return genreIssues.sorted { $0.value > $1.value }
    }
} 