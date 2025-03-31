import SwiftUI
import Supabase

// Add a BookReservationManager to handle persistent state
class BookReservationManager {
    static let shared = BookReservationManager()
    private var reservedBooks: [UUID: UUID] = [:] // [bookId: reservationId]
    private var pendingOperations: Set<UUID> = [] // Currently processing book IDs
    
    private init() {}
    
    func setReservation(bookId: UUID, reservationId: UUID) {
        reservedBooks[bookId] = reservationId
        pendingOperations.remove(bookId)
    }
    
    func removeReservation(bookId: UUID) {
        reservedBooks.removeValue(forKey: bookId)
        pendingOperations.remove(bookId)
    }
    
    func isReserved(bookId: UUID) -> Bool {
        return reservedBooks[bookId] != nil
    }
    
    func getReservationId(bookId: UUID) -> UUID? {
        return reservedBooks[bookId]
    }
    
    func beginOperation(bookId: UUID) -> Bool {
        // Return false if operation already in progress
        if pendingOperations.contains(bookId) {
            return false
        }
        
        pendingOperations.insert(bookId)
        return true
    }
    
    func endOperation(bookId: UUID) {
        pendingOperations.remove(bookId)
    }
}

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
        
        guard let memberIdString = UserDefaults.standard.string(forKey: "currentMemberId"),
                  let memberId = UUID(uuidString: memberIdString) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Member not logged in or invalid ID"])
            }
        let reservation = BookReservation(
            id: UUID(),
            created_at: Date(),
            member_id: memberId,
            book_id: book.id
        )
        
        // Don't try to capture the response as BookReservation
        try await supabase.database
            .from("BookReservation")
            .insert(reservation)
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
    @State private var isBookReserved = false
    @State private var reservationId: UUID?
    @Binding var currentAvailability: Int
    
    private func checkReservationStatus() {
        // First check local cache
        if BookReservationManager.shared.isReserved(bookId: book.id) {
            isBookReserved = true
            reservationId = BookReservationManager.shared.getReservationId(bookId: book.id)
            print("Book is reserved locally with reservation ID: \(reservationId?.uuidString ?? "unknown")")
            return
        }
        
        Task {
            do {
                // Get current user ID from UserDefaults
                guard let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                    return
                }
                
                // Check if this book is already reserved by the current user
                let response = try await supabase.database
                    .from("BookReservation")
                    .select("id")
                    .eq("book_id", value: book.id.uuidString)
                    .eq("member_id", value: userId)
                    .execute()
                
                struct ReservationResponse: Codable {
                    let id: String
                }
                
                // Parse the response
                let decoder = JSONDecoder()
                if let reservations = try? decoder.decode([ReservationResponse].self, from: response.data),
                   let firstReservation = reservations.first,
                   let uuid = UUID(uuidString: firstReservation.id) {
                    // Book is already reserved by this user
                    await MainActor.run {
                        isBookReserved = true
                        reservationId = uuid
                        // Update local cache
                        BookReservationManager.shared.setReservation(bookId: book.id, reservationId: uuid)
                    }
                    print("Book is already reserved by user with reservation ID: \(uuid)")
                } else {
                    await MainActor.run {
                        isBookReserved = false
                        reservationId = nil
                        // Make sure not in cache
                        BookReservationManager.shared.removeReservation(bookId: book.id)
                    }
                    print("Book is not reserved by this user")
                }
            } catch {
                print("Error checking reservation status: \(error)")
            }
        }
    }
    
    private func reserveBook() async {
        // Begin reservation operation - return if already in progress
        if !BookReservationManager.shared.beginOperation(bookId: book.id) {
            print("Reservation operation already in progress for book: \(book.id)")
            return
        }
        
        isReserving = true
        
        do {
            // First get a valid member ID from the database
            guard let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            }
            
            let reservation = BookReservation(
                id: UUID(),
                created_at: Date(),
                member_id: UUID(uuidString: userId)!,
                book_id: book.id
            )
            
            // First check if we already have a reservation for this book
            if BookReservationManager.shared.isReserved(bookId: book.id) {
                print("Book is already reserved locally, not creating duplicate reservation")
                BookReservationManager.shared.endOperation(bookId: book.id)
                return
            }
            
            // Insert the reservation
            try await supabase.database
                .from("BookReservation")
                .insert(reservation)
                .execute()
            
            // Update book's available quantity - only do this here, nowhere else
            if currentAvailability > 0 {
                // Update the database with the current availability value
                try await supabase.database
                    .from("Books")
                    .update(["availableQuantity": currentAvailability - 1])
                    .eq("id", value: book.id)
                    .execute()
                
                // Update our local state to match what we just set in the database
                await MainActor.run {
                    currentAvailability -= 1
                }
            }
            
            print("Book reserved successfully! New availability: \(currentAvailability)")
            await MainActor.run {
                isBookReserved = true
                reservationId = reservation.id
                // Update local cache
                BookReservationManager.shared.setReservation(bookId: book.id, reservationId: reservation.id)
            }
            
        } catch {
            print("Error reserving book: \(error)")
            errorMessage = "Failed to reserve book. Please try again."
            showError = true
            BookReservationManager.shared.endOperation(bookId: book.id)
        }
        
        isReserving = false
        BookReservationManager.shared.endOperation(bookId: book.id)
    }
    
    private func removeReservation() async {
        // Begin remove operation - return if already in progress
        if !BookReservationManager.shared.beginOperation(bookId: book.id) {
            print("Remove reservation operation already in progress for book: \(book.id)")
            return
        }
        
        isReserving = true
        
        do {
            guard let reservationId = reservationId else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Reservation ID not found"])
            }
            
            // Check if this book is already removed from the reservation
            if !BookReservationManager.shared.isReserved(bookId: book.id) {
                print("Book is not reserved locally, no need to remove reservation")
                await MainActor.run {
                    isBookReserved = false
                    self.reservationId = nil
                }
                BookReservationManager.shared.endOperation(bookId: book.id)
                return
            }
            
            // Delete the reservation
            try await supabase.database
                .from("BookReservation")
                .delete()
                .eq("id", value: reservationId)
                .execute()
            
            // Increase book's available quantity - only do this here, nowhere else
            // Use the current availability rather than the book's property
            try await supabase.database
                .from("Books")
                .update(["availableQuantity": currentAvailability + 1])
                .eq("id", value: book.id)
                .execute()
            
            // Update our local state
            await MainActor.run {
                currentAvailability += 1
            }
            
            print("Reservation removed successfully! New availability: \(currentAvailability)")
            await MainActor.run {
                isBookReserved = false
                self.reservationId = nil
                // Update local cache
                BookReservationManager.shared.removeReservation(bookId: book.id)
            }
            
        } catch {
            print("Error removing reservation: \(error)")
            errorMessage = "Failed to remove reservation. Please try again."
            showError = true
            BookReservationManager.shared.endOperation(bookId: book.id)
        }
        
        isReserving = false
        BookReservationManager.shared.endOperation(bookId: book.id)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    if isBookReserved {
                        await removeReservation()
                    } else {
                        await reserveBook()
                    }
                }
            }) {
                HStack {
                    if isReserving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isBookReserved ? "Remove from Reserved" : "Reserve")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isBookReserved ? Color.red : (currentAvailability > 0 ? Color.blue : Color.gray))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled((currentAvailability <= 0 && !isBookReserved) || isReserving)
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
            checkReservationStatus()
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
    @State private var currentAvailability: Int
    
    init(book: Book, supabase: SupabaseClient, isPresented: Binding<Bool>) {
        self.book = book
        self.supabase = supabase
        self._isPresented = isPresented
        self._currentAvailability = State(initialValue: book.availableQuantity)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // Add top padding to create space from the top
                        Spacer()
                            .frame(height: 16)
                            
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
                            Image(systemName: currentAvailability > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(currentAvailability > 0 ? .green : .red)
                            Text(currentAvailability > 0 ? "Available" : "Unavailable")
                                .foregroundColor(currentAvailability > 0 ? .green : .red)
                        }
                        
                        // Action Buttons
                        ActionButtonsView(
                            book: book,
                            supabase: supabase,
                            isReserving: $isReserving,
                            addedToWishlist: $addedToWishlist,
                            currentAvailability: $currentAvailability
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
        .onAppear {
            // Always fetch the latest availability from the database when the view appears
            Task {
                do {
                    print("Fetching latest availability for book: \(book.title) with ID: \(book.id)")
                    let response = try await supabase.database
                        .from("Books")
                        .select("availableQuantity")
                        .eq("id", value: book.id)
                        .single()
                        .execute()
                    
                    struct BookAvailability: Codable {
                        let availableQuantity: Int
                    }
                    
                    if let decodedData = try? JSONDecoder().decode(BookAvailability.self, from: response.data) {
                        print("Updated availability from database: \(decodedData.availableQuantity)")
                        await MainActor.run {
                            currentAvailability = decodedData.availableQuantity
                        }
                    } else {
                        print("Failed to decode availability data")
                        
                        // Try JSON parsing as a fallback
                        if let jsonString = String(data: response.data, encoding: .utf8),
                           let jsonData = jsonString.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let availQty = json["availableQuantity"] as? Int {
                            print("Parsed availability using JSON: \(availQty)")
                            await MainActor.run {
                                currentAvailability = availQty
                            }
                        }
                    }
                } catch {
                    print("Error fetching availability: \(error)")
                }
            }
        }
        .onDisappear {
            // This ensures the reservation status persists when the view disappears
            // ONLY log the status, don't make any database updates here
            if let reservationId = BookReservationManager.shared.getReservationId(bookId: book.id) {
                print("Persisting reservation state for book: \(book.title) with ID: \(book.id)")
            }
        }
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
