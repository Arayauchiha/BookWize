import SwiftUI
import Supabase
// Track book database IDs without relying on Book model extensions
class BookIdentifier {
    // Map to store book identifiers using ISBN as key (since it's unique)
    static var idMap: [String: UUID] = [:]
    
    static func setDatabaseId(_ databaseId: UUID, for isbn: String) {
        idMap[isbn] = databaseId
    }
    
    static func getDatabaseId(for isbn: String) -> UUID? {
        return idMap[isbn]
    }
}

struct WishlistView: View {
    @StateObject private var viewModel = WishlistViewModel()
    @State private var selectedBook: Book?
    @State private var showBookDetail = false
    let supabase = SupabaseConfig.client
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if viewModel.wishlistBooks.isEmpty {
                    emptyWishlistView
                } else {
                    wishlistContentView
                }
            }
            .navigationTitle("My Wishlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshWishlist()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .onAppear {
                // Load wishlist data every time the view appears
                viewModel.loadWishlist()
            }
            .sheet(item: $selectedBook) { book in
                NavigationView {
                    BookDetailCard(book: book, supabase: supabase, isPresented: $showBookDetail)
                        .navigationBarHidden(true)
                }
                .interactiveDismissDisabled()
            }

        }
    }
    
    private var emptyWishlistView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 72))
                .foregroundColor(.gray)
            
            Text("Your wishlist is empty")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Books you add to your wishlist will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var wishlistContentView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 20) {
                ForEach(viewModel.wishlistBooks) { book in
                    wishlistBookCard(for: book)
                }
            }
            .padding()
        }
    }
    
    private func wishlistBookCard(for book: Book) -> some View {
        Button(action: {
            selectedBook = book
            showBookDetail = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                if let imageURL = book.imageURL,
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Button(action: {
                    viewModel.removeFromWishlist(book)
                }) {
                    HStack {
                        Image(systemName: "heart.slash.fill")
                        Text("Remove")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

class WishlistViewModel: ObservableObject {
    @Published var wishlistBooks: [Book] = []
    @Published var isLoading = false
    private var wishlistBookIds: [String] = []
    
    func loadWishlist() {
        isLoading = true
        
        // Clear existing data when starting to load
        wishlistBooks = []
        wishlistBookIds = []
        
        Task {
            do {
                // 1. Get current user ID from UserDefaults
                guard let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                    return
                }
                
                print("Loading wishlist for user ID: \(userId)")
                
                // 2. Get user's wishlist from Members table
                let response = try await SupabaseManager.shared.client
                    .from("Members")
                    .select("wishlist")
                    .eq("id", value: userId)
                    .single()
                    .execute()
                
                // Parse the response to get wishlist book IDs
                struct MemberResponse: Codable {
                    let wishlist: [String]?
                }
                
                do {
                    let decoder = JSONDecoder()
                    let member = try decoder.decode(MemberResponse.self, from: response.data)
                    
                    if let wishlist = member.wishlist {
                        print("Fetched wishlist: \(wishlist)")
                        self.wishlistBookIds = wishlist
                        
                        if wishlist.isEmpty {
                            await MainActor.run {
                                self.wishlistBooks = []
                                self.isLoading = false
                                print("Wishlist is empty")
                            }
                        } else {
                            // 3. Fetch book details for each book ID in the wishlist
                            await fetchWishlistBooks(bookIds: wishlist)
                        }
                    } else {
                        // User has no wishlist items
                        await MainActor.run {
                            self.wishlistBooks = []
                            self.isLoading = false
                            print("Wishlist is nil")
                        }
                    }
                } catch {
                    print("Error decoding wishlist: \(error)")
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } catch {
                print("Error loading wishlist: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshWishlist() {
        loadWishlist()
    }
    
    private func fetchWishlistBooks(bookIds: [String]) async {
        var books: [Book] = []
        
        // Fetch each book by ID from the Books table
        for bookId in bookIds {
            do {
                print("Fetching book with ID: \(bookId)")
                
                // Try to fetch by UUID first (if the ID is a UUID)
                let bookResponse = try await SupabaseManager.shared.client
                    .from("Books")
                    .select("*")
                    .or("id.eq.\(bookId),isbn.eq.\(bookId)")
                    .execute()
                
                print("Response data for book \(bookId): \(String(data: bookResponse.data, encoding: .utf8) ?? "none")")
                
                do {
                    // Create a custom decoder with date handling capabilities
                    let decoder = JSONDecoder()
                    
                    // Setup date decoding strategy for ISO8601 format (common for timestamptz)
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ" // ISO8601 format
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    
                    // Try multiple date formats if the standard one fails
                    decoder.dateDecodingStrategy = .custom { decoder in
                        let container = try decoder.singleValueContainer()
                        let dateString = try container.decode(String.self)
                        
                        // Try ISO8601 with formatter
                        if let date = dateFormatter.date(from: dateString) {
                            return date
                        }
                        
                        // Try ISO8601 with different formats
                        let backupFormatters = [
                            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                            "yyyy-MM-dd'T'HH:mm:ss",
                            "yyyy-MM-dd"
                        ]
                        
                        for format in backupFormatters {
                            dateFormatter.dateFormat = format
                            if let date = dateFormatter.date(from: dateString) {
                                return date
                            }
                        }
                        
                        // Try ISO8601DateFormatter as a fallback
                        let iso8601Formatter = ISO8601DateFormatter()
                        if let date = iso8601Formatter.date(from: dateString) {
                            return date
                        }
                        
                        // If all else fails, return the current date and log the error
                        print("⚠️ Could not parse date string \(dateString), using current date instead")
                        return Date()
                    }
                    
                    // Custom decoding for the Book model
                    struct BookWrapper: Codable {
                        let id: UUID
                        let title: String
                        let author: String
                        let isbn: String
                        let publisher: String?
                        let description: String?
                        let imageURL: String?
                        let quantity: Int
                        let availableQuantity: Int?
                        let genre: String?
                        let publishedDate: String?
                        let pageCount: Int?
                        let addedDate: String? // For timestamptz format from Supabase
                        let categories: [String]?
                        
                        // Map to your Book model with only the required parameters
                        func toBook() -> Book {
                            let book = Book(
                                isbn: isbn,
                                title: title,
                                author: author,
                                publisher: publisher ?? "",
                                quantity: quantity,
                                publishedDate: publishedDate,
                                description: description,
                                pageCount: pageCount,
                                categories: categories,
                                imageURL: imageURL
                            )
                            
                            // Store the database ID in our map using the ISBN as key
                            BookIdentifier.setDatabaseId(id, for: isbn)
                            
                            return book
                        }
                    }
                    
                    let jsonStr = String(data: bookResponse.data, encoding: .utf8) ?? "[]"
                    print("Attempting to decode: \(jsonStr)")
                    
                    if let wrappers = try? decoder.decode([BookWrapper].self, from: bookResponse.data),
                       let wrapper = wrappers.first {
                        let book = wrapper.toBook()
                        books.append(book)
                        print("Successfully decoded book: \(book.title)")
                    } else {
                        print("Failed to decode book with wrapper. Trying alternative approach...")
                        
                        // Try to extract just the needed fields manually
                        if let jsonString = String(data: bookResponse.data, encoding: .utf8),
                           let jsonData = jsonString.data(using: .utf8) {
                            
                            if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                               let bookJson = json.first {
                                
                                // Extract values with type safety
                                if let idStr = bookJson["id"] as? String,
                                   let title = bookJson["title"] as? String,
                                   let author = bookJson["author"] as? String,
                                   let isbn = bookJson["isbn"] as? String,
                                   let quantity = bookJson["quantity"] as? Int {
                                    
                                    let book = Book(
                                        isbn: isbn,
                                        title: title,
                                        author: author,
                                        publisher: bookJson["publisher"] as? String ?? "",
                                        quantity: quantity,
                                        publishedDate: bookJson["publishedDate"] as? String,
                                        description: bookJson["description"] as? String,
                                        pageCount: bookJson["pageCount"] as? Int,
                                        categories: bookJson["categories"] as? [String],
                                        imageURL: bookJson["imageURL"] as? String
                                    )
                                    
                                    // Store the database ID in our map using ISBN as key
                                    if let idUUID = UUID(uuidString: idStr) {
                                        BookIdentifier.setDatabaseId(idUUID, for: isbn)
                                    }
                                    
                                    books.append(book)
                                    print("Successfully created book using manual JSON parsing: \(book.title)")
                                }
                            }
                        }
                    }
                } catch {
                    print("Error decoding book \(bookId): \(error)")
                }
            } catch {
                print("Error fetching book \(bookId): \(error)")
            }
        }
        
        await MainActor.run {
            self.wishlistBooks = books
            self.isLoading = false
            
            if books.isEmpty {
                print("No books found in wishlist")
            } else {
                print("Found \(books.count) books in wishlist")
                for book in books {
                    print("  - \(book.title) by \(book.author)")
                }
            }
        }
    }
    
    func removeFromWishlist(_ book: Book) {
        // Get the database ID using ISBN
        guard let databaseId = BookIdentifier.getDatabaseId(for: book.isbn) else {
            print("❌ Error: Cannot find database ID for book with ISBN: \(book.isbn)")
            return
        }
        
        print("Removing book with database ID: \(databaseId)")
        
        // Remove from local array first for immediate UI update
        if let index = wishlistBooks.firstIndex(where: { $0.isbn == book.isbn }) {
            wishlistBooks.remove(at: index)
        }
        
        // Remove from Supabase
        Task {
            do {
                // Get current user ID from UserDefaults
                guard let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                    print("Error: No user ID found in UserDefaults")
                    return
                }
                
                print("Removing book \(databaseId) from wishlist for user \(userId)")
                
                // Get existing wishlist
                let response = try await SupabaseManager.shared.client
                    .from("Members")
                    .select("wishlist")
                    .eq("id", value: userId)
                    .single()
                    .execute()
                
                // Parse and update wishlist
                struct MemberResponse: Codable {
                    let wishlist: [String]?
                }
                
                do {
                    let decoder = JSONDecoder()
                    let member = try decoder.decode(MemberResponse.self, from: response.data)
                    
                    if var wishlist = member.wishlist {
                        print("Current wishlist: \(wishlist)")
                        
                        // Remove book ID from wishlist
                        wishlist.removeAll { $0 == databaseId.uuidString }
                        
                        print("Updated wishlist: \(wishlist)")
                        
                        // Store the updated wishlist back in our model
                        wishlistBookIds = wishlist
                        
                        // Update wishlist in Supabase
                        let updateResponse = try await SupabaseManager.shared.client
                            .from("Members")
                            .update(["wishlist": wishlist])
                            .eq("id", value: userId)
                            .execute()
                        
                        if updateResponse.status == 200 || updateResponse.status == 201 || updateResponse.status == 204 {
                            print("✅ Successfully updated wishlist in Supabase")
                            
                            // Refresh the list to ensure UI is in sync with database
                            await MainActor.run {
                                // We've already removed it from the local array, and updated wishlistBookIds,
                                // so we don't need to reload the entire list
                                print("Book successfully removed from wishlist")
                            }
                        } else {
                            print("❌ Failed to update wishlist in Supabase: Status code \(updateResponse.status)")
                            // If update failed, reload the wishlist to ensure UI matches database
                            await MainActor.run {
                                self.loadWishlist()
                            }
                        }
                    } else {
                        print("Wishlist is nil for user \(userId)")
                    }
                } catch {
                    print("Error decoding wishlist: \(error)")
                    await MainActor.run {
                        self.loadWishlist()
                    }
                }
            } catch {
                print("Error removing from wishlist: \(error)")
                // If there was an error, reload the wishlist to ensure UI is in sync
                await MainActor.run {
                    self.loadWishlist()
                }
            }
        }
    }
}

struct WishlistView_Previews: PreviewProvider {
    static var previews: some View {
        WishlistView()
    }
} 
