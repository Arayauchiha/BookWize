import Foundation

class DashboardManager: ObservableObject {
    @Published private(set) var overdueMembersCount: Int = 0
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
        await fetchOverdueMembersCount()
        await fetchTotalBooksCount()
        await fetchIssuedBooksCount()
        await fetchTotalMembersCount()
        await fetchTotalRevenue()
        await fetchOverdueFines()
        await fetchActiveLibrariansCount()
        await loadBooksFromSupabase()
    }
    
    private func fetchOverdueMembersCount() async {
        do {
            struct OverdueMember: Codable {
                let fine: Double?
            }

            let overdueMembers: [OverdueMember] = try await SupabaseManager.shared.client
                .from("Members")
                .select("fine")
                .gt("fine", value: 0) // Fetch members who have a fine greater than 0
                .execute()
                .value
            
            await MainActor.run {
                self.overdueMembersCount = overdueMembers.count
            }
            
            print("Fetched overdue members count: \(overdueMembers.count)")
        } catch {
            print("Error fetching overdue members count: \(error)")
        }
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
    
//    private func fetchRevenueAndFines() async {
//        do {
//            let client = SupabaseManager.shared.client
//
//            // Define the required structs
//            struct MembershipSetting: Codable {
//                let Membership: Double?
//            }
//
//            struct MemberFine: Codable {
//                let fine: Double?
//            }
//
//            // Fetch membership fee
//            let membershipFeeResponse: [MembershipSetting] = try await client
//                .from("FineAndMembershipSet")
//                .select("Membership")
//                .execute()
//                .value
//            
//            let membershipFee = membershipFeeResponse.first?.Membership ?? 0.0
//
//            // Fetch total members count
//            let membersCount: Int = try await client
//                .from("Members")
//                .select("*", head: true)
//                .execute()
//                .count ?? 0
//            
//            let membershipRevenue = Double(membersCount) * membershipFee
//
//            // Fetch total overdue fines from "Members" table
//            let finesResponse: [MemberFine] = try await client
//                .from("Members")
//                .select("fine")
//                .execute()
//                .value
//            
//            let totalFines = finesResponse.reduce(0.0) { sum, member in
//                sum + (member.fine ?? 0)
//            }
//
//            // Calculate total revenue
//            let totalAmount = membershipRevenue + totalFines
//
//            await MainActor.run {
//                self.totalRevenue = totalAmount
//                self.overdueFines = totalFines
//                print("Updated Revenue: \(self.totalRevenue)")
//                print("Updated Overdue Fines: \(self.overdueFines)")
//            }
//        } catch {
//            print("Error fetching revenue and fines: \(error)")
//        }
//    }

    private func fetchTotalRevenue() async {
            do {
                let client = SupabaseManager.shared.client
                struct MembershipSetting: Codable { let Membership: Double? }
                
                let membershipFeeResponse: [MembershipSetting] = try await client
                    .from("FineAndMembershipSet")
                    .select("Membership")
                    .execute()
                    .value
                
                let membershipFee = membershipFeeResponse.first?.Membership ?? 0.0
                print("Membership Fee Response: \(membershipFeeResponse)")
                
                let membersCount: Int = try await client
                    .from("Members")
                    .select("*", count: .exact)
                    .execute()
                    .count ?? 0

                print("Total Members Count: \(membersCount)")
                
                let membershipRevenue = Double(membersCount) * membershipFee
                
                await MainActor.run { self.totalRevenue = membershipRevenue }
                print("Updated Total Revenue: \(self.totalRevenue)")
            } catch {
                print("Error fetching total revenue: \(error)")
            }
        }
        
    
    private func fetchOverdueFines() async {
            do {
                let client = SupabaseManager.shared.client
                struct MemberFine: Codable { let fine: Double? }
                
                let finesResponse: [MemberFine] = try await client
                    .from("Members")
                    .select("fine")
                    .execute()
                    .value
                
                let totalFines = finesResponse.reduce(0.0) { sum, member in
                    sum + (member.fine ?? 0)
                }
                
                await MainActor.run { self.overdueFines = totalFines }
                print("Updated Overdue Fines: \(self.overdueFines)")
            } catch {
                print("Error fetching overdue fines: \(error)")
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
