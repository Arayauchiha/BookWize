import SwiftUI
import Supabase

// Add these near the top of the file, after the imports
private struct SupabaseClientKey: EnvironmentKey {
    static let defaultValue: SupabaseClient = SupabaseClient(
        supabaseURL: URL(string: "https://qjhfnprghpszprfhjzdl.supabase.coL")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqaGZucHJnaHBzenByZmhqemRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzNzE5NTAsImV4cCI6MjA1Nzk0Nzk1MH0.Bny2_LBt2fFjohwmzwCclnFNmrC_LZl3s3PVx-SOeNc"
    )
}

extension EnvironmentValues {
    var supabaseClient: SupabaseClient {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}

// MARK: - Book Cover View
private struct BookCoverView: View {
    let imageURL: String
    let scrollOffset: CGFloat
    let isFullScreen: Bool
    
    var body: some View {
        if let url = URL(string: imageURL) {
            GeometryReader { imageGeometry in
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: max(400 - scrollOffset, 200))
                .cornerRadius(8)
                .shadow(radius: 5)
                .scaleEffect(isFullScreen ? 1 : min(1, max(0.8, 1 - scrollOffset / 400)))
                .opacity(isFullScreen ? 1 : min(1, max(0.5, 1 - scrollOffset / 400)))
            }
            .frame(height: 400)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Book Info View
private struct BookInfoView: View {
    let book: Book
    
    var body: some View {
        VStack(spacing: 8) {
            Text(book.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(book.author)
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .id("titleSection")
    }
}

// Add this class
class BookReservationViewModel: ObservableObject {
    private let supabase: SupabaseClient
    
    @Published var isReserving = false
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func reserveBook(book: Book) async throws {
        isReserving = true
        defer { isReserving = false }
        
        let reservation = BookReservation(
            id: UUID(),
            created_at: Date(),
            member_id: try await supabase.auth.session.user.id,
            book_id: book.id
        )
        
        let response: BookReservation = try await supabase.database
            .from("BookReservation")
            .insert(reservation)
            .single()
            .execute()
            .value
        
        try await supabase
            .from("Books")
            .update(["availableQuantity": book.availableQuantity - 1])
            .eq("id", value: book.id)
            .execute()
    }
}

// Modify ActionButtonsView to use the view model
private struct ActionButtonsView: View {
    let book: Book
    let supabase: SupabaseClient
    @Binding var isReserving: Bool
    @Binding var addedToWishlist: Bool
    @State private var isAddingToWishlist = false
    @State private var isRemovingFromWishlist = false
    @State private var showWishlistAlert = false
    @State private var wishlistAlertMessage = ""
    @State private var showRemoveConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private func reserveBook() async {
        isReserving = true
        
        do {
            // First get a valid member ID from the database
            let members: [MemberID] = try await supabase.database
                .from("Members")
                .select("id")
                .limit(1)
                .execute()
                .value
            
            guard let member = members.first else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No members found in the system"])
            }
            
            let reservation = BookReservation(
                id: UUID(),
                created_at: Date(),
                member_id: member.id,
                book_id: book.id
            )
            
            // Insert the reservation
            try await supabase.database
                .from("BookReservation")
                .insert(reservation)
                .execute()
            
            // Update book's available quantity
            if book.availableQuantity > 0 {
                try await supabase.database
                    .from("Books")
                    .update(["availableQuantity": book.availableQuantity - 1])
                    .eq("id", value: book.id)
                    .execute()
            }
            
            print("Book reserved successfully!")
            
        } catch {
            print("Error reserving book: \(error)")
            errorMessage = "Failed to reserve book. Please try again."
            showError = true
        }
        
        isReserving = false
    }
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await reserveBook()
                }
            }) {
                HStack {
                    if isReserving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Reserve")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(book.isAvailable ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(!book.isAvailable || isReserving)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            
            Button(action: {
                if addedToWishlist {
                    // Show confirmation alert instead of removing immediately
                    showRemoveConfirmation = true
                } else {
                    addBookToWishlist()
                }
            }) {
                HStack {
                    if isAddingToWishlist || isRemovingFromWishlist {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: addedToWishlist ? "heart.fill" : "heart")
                        Text(addedToWishlist ? "Remove from Wishlist" : "Add to Wishlist")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(addedToWishlist ? .red : .primary)
                .cornerRadius(8)
            }
            .disabled(isAddingToWishlist || isRemovingFromWishlist)
        }
        .padding(.horizontal)
        .alert(wishlistAlertMessage, isPresented: $showWishlistAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Remove from Wishlist", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                removeBookFromWishlist()
            }
        } message: {
            Text("Are you sure you want to remove '\(book.title)' from your wishlist?")
        }
        .onAppear {
            checkIfBookInWishlist()
        }
    }
    
    private func checkIfBookInWishlist() {
        Task {
            do {
                // Get current user ID from UserDefaults
                guard let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                    return
                }
                
                print("Checking wishlist for book: \(book.title) with ID: \(book.id.uuidString), ISBN: \(book.isbn)")
                
                // Get existing wishlist for the user
                let response = try await SupabaseManager.shared.client
                    .from("Members")
                    .select("wishlist")
                    .eq("id", value: userId)
                    .single()
                    .execute()
                
                // Parse the response to get current wishlist
                struct MemberResponse: Codable {
                    let wishlist: [String]?
                }
                
                do {
                    let decoder = JSONDecoder()
                    let member = try decoder.decode(MemberResponse.self, from: response.data)
                    
                    // Check if book is in wishlist
                    if let wishlist = member.wishlist {
                        print("Current wishlist: \(wishlist)")
                        
                        // Now we need to check if any of the book IDs in the wishlist match our book
                        let bookId = book.id.uuidString
                        var inWishlist = wishlist.contains(bookId)
                        
                        // If not found by direct ID, check each book in the database to find our ISBN
                        if !inWishlist && !wishlist.isEmpty {
                            print("Book not found by ID, checking by ISBN...")
                            
                            // Check if any books in the wishlist have the same ISBN
                            for dbBookId in wishlist {
                                do {
                                    let bookResponse = try await SupabaseManager.shared.client
                                        .from("Books")
                                        .select("isbn")
                                        .eq("id", value: dbBookId)
                                        .single()
                                        .execute()
                                    
                                    struct BookIsbnResponse: Codable {
                                        let isbn: String
                                    }
                                    
                                    if let bookData = try? decoder.decode(BookIsbnResponse.self, from: bookResponse.data) {
                                        if bookData.isbn == book.isbn {
                                            print("Found book in wishlist by ISBN match: \(book.isbn)")
                                            inWishlist = true
                                            
                                            // Store this ID to use for later operations
                                            BookIdentifier.setDatabaseId(UUID(uuidString: dbBookId) ?? book.id, for: book.isbn)
                                            break
                                        }
                                    }
                                } catch {
                                    print("Error checking book \(dbBookId): \(error)")
                                }
                            }
                        }
                        
                        print("Book \(book.title) is \(inWishlist ? "in" : "not in") wishlist")
                        
                        await MainActor.run {
                            addedToWishlist = inWishlist
                        }
                    } else {
                        print("User has no wishlist")
                        await MainActor.run {
                            addedToWishlist = false
                        }
                    }
                } catch {
                    print("Error checking wishlist status: \(error)")
                }
            } catch {
                print("Error fetching wishlist: \(error)")
            }
        }
    }
    
    private func addBookToWishlist() {
        isAddingToWishlist = true
        
        Task {
            do {
                // Get current user ID from UserDefaults
                guard let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                    await showAlert("You need to be logged in to add to wishlist")
                    return
                }
                
                let bookId = book.id.uuidString
                let isbn = book.isbn
                print("Adding book to wishlist: \(book.title) with ID: \(bookId), ISBN: \(isbn)")
                
                // First, verify that this book exists in the database with this exact ID
                // This prevents inconsistencies where the same book might have different IDs
                let verifyResponse = try await SupabaseManager.shared.client
                    .from("Books")
                    .select("id, isbn")
                    .eq("isbn", value: isbn)
                    .execute()
                
                var dbBookId = bookId
                
                // If we get a response, use the ID from the database
                struct BookIdResponse: Codable {
                    let id: String
                    let isbn: String
                }
                
                // Use a safer approach to handle the data
                do {
                    let books = try JSONDecoder().decode([BookIdResponse].self, from: verifyResponse.data)
                    if let firstBook = books.first {
                        // Use the ID from the database, which is the canonical ID for this ISBN
                        dbBookId = firstBook.id
                        print("Using database ID \(dbBookId) instead of local ID \(bookId) for ISBN \(isbn)")
                        
                        // Update our BookIdentifier map
                        if let uuid = UUID(uuidString: dbBookId) {
                            BookIdentifier.setDatabaseId(uuid, for: isbn)
                        }
                    }
                } catch {
                    print("Error decoding book data from database: \(error)")
                    // Continue using the local book ID
                }
                
                // Get existing wishlist for the user
                let response = try await SupabaseManager.shared.client
                    .from("Members")
                    .select("wishlist")
                    .eq("id", value: userId)
                    .single()
                    .execute()
                
                // Parse the response to get current wishlist
                struct MemberResponse: Codable {
                    let wishlist: [String]?
                }
                
                do {
                    let decoder = JSONDecoder()
                    let member = try decoder.decode(MemberResponse.self, from: response.data)
                    
                    // Update the wishlist with the new book ID
                    var updatedWishlist = member.wishlist ?? []
                    
                    print("Current wishlist before addition: \(updatedWishlist)")
                    
                    // Check if book is already in wishlist by ID or ISBN
                    if updatedWishlist.contains(dbBookId) {
                        print("⚠️ Book is already in wishlist with matching ID, not adding duplicate")
                        await showAlert("This book is already in your wishlist")
                        return
                    }
                    
                    // Check if any books in the wishlist have the same ISBN
                    var alreadyInWishlist = false
                    for existingBookId in updatedWishlist {
                        let bookResponse = try await SupabaseManager.shared.client
                            .from("Books")
                            .select("isbn")
                            .eq("id", value: existingBookId)
                            .single()
                            .execute()
                        
                        struct BookIsbnResponse: Codable {
                            let isbn: String
                        }
                        
                        if let bookData = try? decoder.decode(BookIsbnResponse.self, from: bookResponse.data) {
                            if bookData.isbn == isbn {
                                print("⚠️ Book with ISBN \(isbn) is already in wishlist with ID \(existingBookId), not adding duplicate")
                                alreadyInWishlist = true
                                break
                            }
                        }
                    }
                    
                    if alreadyInWishlist {
                        await showAlert("This book is already in your wishlist")
                        return
                    }
                    
                    // Add book to wishlist using the database ID
                    updatedWishlist.append(dbBookId)
                    
                    print("Updated wishlist after addition: \(updatedWishlist)")
                    
                    // Update the user's wishlist in Supabase
                    let updateResponse = try await SupabaseManager.shared.client
                        .from("Members")
                        .update(["wishlist": updatedWishlist])
                        .eq("id", value: userId)
                        .execute()
                    
                    if updateResponse.status == 200 || updateResponse.status == 201 || updateResponse.status == 204 {
                        // Success
                        print("✅ Successfully added book to wishlist in Supabase")
                        await MainActor.run {
                            addedToWishlist = true
                            wishlistAlertMessage = "Book added to your wishlist"
                            showWishlistAlert = true
                            isAddingToWishlist = false
                        }
                    } else {
                        print("❌ Failed to update wishlist in Supabase: Status code \(updateResponse.status)")
                        await showAlert("Failed to update wishlist")
                    }
                } catch {
                    print("Error decoding wishlist: \(error)")
                    await showAlert("Failed to retrieve your wishlist: \(error.localizedDescription)")
                }
            } catch {
                print("Error adding to wishlist: \(error)")
                await showAlert("Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func removeBookFromWishlist() {
        isRemovingFromWishlist = true
        
        Task {
            do {
                // Get current user ID from UserDefaults
                guard let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                    await showAlert("You need to be logged in to manage your wishlist")
                    return
                }
                
                let isbn = book.isbn
                print("Removing book from wishlist: \(book.title) with ISBN: \(isbn)")
                
                // Get existing wishlist for the user
                let response = try await SupabaseManager.shared.client
                    .from("Members")
                    .select("wishlist")
                    .eq("id", value: userId)
                    .single()
                    .execute()
                
                // Parse the response to get current wishlist
                struct MemberResponse: Codable {
                    let wishlist: [String]?
                }
                
                do {
                    let decoder = JSONDecoder()
                    let member = try decoder.decode(MemberResponse.self, from: response.data)
                    
                    if var wishlist = member.wishlist {
                        print("Current wishlist before removal: \(wishlist)")
                        
                        // Identify all book IDs in the wishlist that match our ISBN
                        var bookIdsToRemove: [String] = []
                        var bookIdMatches = 0
                        
                        // First check if we have a stored ID for this ISBN
                        if let storedId = BookIdentifier.getDatabaseId(for: isbn) {
                            let storedIdString = storedId.uuidString
                            print("Using stored database ID: \(storedIdString) for ISBN: \(isbn)")
                            bookIdsToRemove.append(storedIdString)
                            bookIdMatches += wishlist.filter { $0 == storedIdString }.count
                        }
                        
                        // If we didn't find a match or not all instances were removed, scan the database
                        if bookIdMatches == 0 {
                            print("No stored ID found or no matches in wishlist, scanning database for ISBN matches...")
                            
                            // Check all books in the wishlist to find matching ISBN
                            for dbBookId in wishlist {
                                do {
                                    let bookResponse = try await SupabaseManager.shared.client
                                        .from("Books")
                                        .select("isbn")
                                        .eq("id", value: dbBookId)
                                        .single()
                                        .execute()
                                    
                                    struct BookIsbnResponse: Codable {
                                        let isbn: String
                                    }
                                    
                                    if let bookData = try? decoder.decode(BookIsbnResponse.self, from: bookResponse.data) {
                                        if bookData.isbn == isbn {
                                            print("Found book in wishlist with ID \(dbBookId) matching ISBN \(isbn)")
                                            bookIdsToRemove.append(dbBookId)
                                        }
                                    }
                                } catch {
                                    print("Error checking book \(dbBookId): \(error)")
                                }
                            }
                        }
                        
                        // Add the current book ID as a fallback if no other matches found
                        if bookIdsToRemove.isEmpty {
                            let bookId = book.id.uuidString
                            print("No matching books found by ISBN, using current book ID: \(bookId)")
                            bookIdsToRemove.append(bookId)
                        }
                        
                        // Remove all occurrences of book IDs that match our criteria
                        let originalCount = wishlist.count
                        for idToRemove in bookIdsToRemove {
                            wishlist.removeAll { $0 == idToRemove }
                        }
                        
                        let removedCount = originalCount - wishlist.count
                        print("Removed \(removedCount) book entries from wishlist")
                        print("Updated wishlist after removal: \(wishlist)")
                        
                        // Update the wishlist in Supabase
                        let updateResponse = try await SupabaseManager.shared.client
                            .from("Members")
                            .update(["wishlist": wishlist])
                            .eq("id", value: userId)
                            .execute()
                        
                        if updateResponse.status == 200 || updateResponse.status == 201 || updateResponse.status == 204 {
                            // Success
                            print("✅ Successfully removed book from wishlist in Supabase")
                            await MainActor.run {
                                addedToWishlist = false
                                wishlistAlertMessage = "Book removed from your wishlist"
                                showWishlistAlert = true
                                isRemovingFromWishlist = false
                            }
                        } else {
                            print("❌ Failed to update wishlist in Supabase: Status code \(updateResponse.status)")
                            await showAlert("Failed to update wishlist")
                        }
                    } else {
                        print("Wishlist is nil for user \(userId)")
                        await showAlert("Wishlist not found")
                    }
                } catch {
                    print("Error decoding wishlist: \(error)")
                    await showAlert("Failed to retrieve your wishlist: \(error.localizedDescription)")
                }
            } catch {
                print("Error removing from wishlist: \(error)")
                await showAlert("Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func showAlert(_ message: String) async {
        await MainActor.run {
            wishlistAlertMessage = message
            showWishlistAlert = true
            isAddingToWishlist = false
            isRemovingFromWishlist = false
        }
    }
}

struct BookReservation: Codable {
    let id: UUID
    let created_at: Date
    let member_id: UUID
    let book_id: UUID
}

// Add a simple struct for member ID
private struct MemberID: Codable {
    let id: UUID
}

struct BookDetailCard: View {
    let book: Book
    let supabase: SupabaseClient

    @Binding var isPresented: Bool
    @State private var cardOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var scrollOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    @State private var isReserving = false
    @State private var addedToWishlist = false
    @State private var isFullScreen = false
    @State private var isImageLoaded = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // Book Cover
                        if let imageURL = book.imageURL {
                            BookCoverView(
                                imageURL: imageURL,
                                scrollOffset: scrollOffset,
                                isFullScreen: isFullScreen
                            )
                        }
                        
                        // Book Info
                        BookInfoView(book: book)
                        
                        // Availability Status
                        HStack {
                            Image(systemName: book.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(book.isAvailable ? .green : .red)
                            Text(book.isAvailable ? "Available" : "Unavailable")
                                .foregroundColor(book.isAvailable ? .green : .red)
                        }
                        
                        // Action Buttons
                        ActionButtonsView(
                            book: book,
                            supabase: supabase,
                            isReserving: $isReserving,
                            addedToWishlist: $addedToWishlist
                        )
                        
                        // Book Description
                        if let description = book.description {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Book Details Grid
                        HStack(spacing: 0) {
                            BookDetailItem(
                                icon: "book.closed",
                                title: "Genre",
                                value: book.genre ?? "Unknown"
                            )
                            
                            Divider()
                                .frame(height: 40)
                            
                            BookDetailItem(
                                icon: "calendar",
                                title: "Released",
                                value: book.publishedDate ?? "Unknown"
                            )
                            
                            Divider()
                                .frame(height: 40)
                            
                            BookDetailItem(
                                icon: "text.justify",
                                title: "Length",
                                value: "\(book.pageCount ?? 0) pages"
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                    .background(GeometryReader { proxy in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: proxy.frame(in: .named("scroll")).minY
                        )
                    })
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = -value
                    isFullScreen = scrollOffset > 50
                }
            }
            .background(Color(.systemBackground))
        }
        .overlay(
            Button(action: {
                isPresented = false
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.gray)
                    .padding()
            }
            .opacity(isDragging || scrollOffset > 50 ? 0 : 1),
            alignment: .topTrailing
        )
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.height > 0 && scrollOffset <= 0 {
                        state = value.translation.height
                    }
                }
                .onChanged { _ in
                    isDragging = true
                }
                .onEnded { value in
                    isDragging = false
                    if value.translation.height > 100 && scrollOffset <= 0 {
                        dismiss()
                    }
                }
        )
        .offset(y: dragOffset)
    }
}

struct BookDetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.gray)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
} 
