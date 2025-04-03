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
    @Published private(set) var popularGenres: [(String, Int)] = []
    
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
        await fetchPopularGenres()
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
    
    private func fetchTotalRevenue() async {
            do {
                let client = SupabaseManager.shared.client
                struct MembershipSetting: Codable { let Membership: Double? }
                
                // Fetch membership fee
                let membershipFeeResponse: [MembershipSetting] = try await client
                    .from("FineAndMembershipSet")
                    .select("Membership")
                    .execute()
                    .value
                
                let membershipFee = membershipFeeResponse.first?.Membership ?? 0.0
                print("Membership Fee Response: \(membershipFeeResponse)")
                
                // Fetch total members count
                let membersCount: Int = try await client
                    .from("Members")
                    .select("*", count: .exact)
                    .execute()
                    .count ?? 0

                print("Total Members Count: \(membersCount)")
                
                // Calculate membership revenue
                let membershipRevenue = Double(membersCount) * membershipFee
                
                // Fetch total fines from issuebooks table
                struct IssueBookFine: Codable { let fineAmount: Double? }
                let finesResponse: [IssueBookFine] = try await client
                    .from("issuebooks")
                    .select("fineAmount")
                    .execute()
                    .value
                
                let totalFines = finesResponse.reduce(0.0) { sum, issue in
                    sum + (issue.fineAmount ?? 0)
                }
                
                // Calculate total revenue including both membership fees and fines
                let totalRevenue = membershipRevenue + totalFines
                
                await MainActor.run { self.totalRevenue = totalRevenue }
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
    
    func fetchPopularGenres() async {
        do {
            print("Fetching member genre preferences...")
            
            let members: [User] = try await SupabaseManager.shared.client
                .from("Members")
                .select("selectedGenres")
                .execute()
                .value
            
            print("Fetched \(members.count) members with genre preferences")
            
            // Debug: Count non-empty selectedGenres arrays
            let membersWithGenres = members.filter { !$0.selectedGenres.isEmpty }
            print("Members with non-empty genre preferences: \(membersWithGenres.count)/\(members.count)")
            
            // Debug log some samples
            if !membersWithGenres.isEmpty {
                let sampleMembers = Array(membersWithGenres.prefix(3))
                print("Sample member genres:")
                for (i, member) in sampleMembers.enumerated() {
                    print("  Member \(i+1): \(member.selectedGenres)")
                }
            }
            
            var genreCounts: [String: Int] = [:]
            
            // Count occurrences of each genre from members' preferences
            for member in members {
                for genre in member.selectedGenres {
                    if !genre.isEmpty {
                        genreCounts[genre, default: 0] += 1
                    }
                }
            }
            
            print("Counted \(genreCounts.count) unique genres")
            
            // If no genres found from member preferences, fall back to book categories
            if genreCounts.isEmpty {
                print("No genres found from member preferences, falling back to book categories")
                
                // Get genres from book categories
                for book in books {
                    if let categories = book.categories, !categories.isEmpty {
                        for category in categories {
                            genreCounts[category, default: 0] += 1
                        }
                    }
                }
                
                print("Counted \(genreCounts.count) unique genres from book categories")
            }
            
            // Sort genres by count in descending order
            let sortedGenres = genreCounts.sorted { $0.value > $1.value }
            
            await MainActor.run {
                if !sortedGenres.isEmpty {
                    // Update the published property with the results
                    self.popularGenres = sortedGenres
                    print("Updated popular genres: \(self.popularGenres)")
                } else {
                    // If still no genres, add a sample genre
                    self.popularGenres = [("Fiction", 5)]
                    print("No genres found at all, added a sample genre: \(self.popularGenres)")
                }
            }
        } catch {
            print("Error fetching member genre preferences: \(error)")
            await MainActor.run {
                // Add a sample genre on error
                self.popularGenres = [("Fiction", 5)]
                print("Error occurred, added a sample genre: \(self.popularGenres)")
            }
        }
    }
    
    func getPopularGenres() -> [(String, Int)] {
        return popularGenres.isEmpty ? [] : [popularGenres[0]]
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
