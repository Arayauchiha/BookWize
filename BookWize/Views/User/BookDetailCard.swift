import SwiftUI
import Supabase

// Add a WishlistManager to handle persistent state
class WishlistManager {
    static let shared = WishlistManager()
    private var wishlistBooks: [String: Bool] = [:]
    
    private init() {}
    
    func setInWishlist(isbn: String) {
        wishlistBooks[isbn] = true
    }
    
    func removeFromWishlist(isbn: String) {
        wishlistBooks.removeValue(forKey: isbn)
    }
    
    func isBookInWishlist(isbn: String) -> Bool {
        return wishlistBooks[isbn] ?? false
    }
    
    func clearWishlist() {
        wishlistBooks.removeAll()
    }
}

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
        try await supabase
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
    @State private var isBookReserved: Bool
    @State private var reservationId: UUID?
    @State private var showReserveSuccessAlert = false
    @State private var showCancelConfirmation = false
    @Binding var currentAvailability: Int
    @Binding var parentIsBookReserved: Bool
    @Binding var parentShowReserveSuccessAlert: Bool
    
    init(book: Book, supabase: SupabaseClient, isReserving: Binding<Bool>, addedToWishlist: Binding<Bool>, currentAvailability: Binding<Int>, parentIsBookReserved: Binding<Bool>, parentShowReserveSuccessAlert: Binding<Bool>) {
        self.book = book
        self.supabase = supabase
        self._isReserving = isReserving
        self._addedToWishlist = addedToWishlist
        self._currentAvailability = currentAvailability
        self._isBookReserved = State(initialValue: parentIsBookReserved.wrappedValue)
        self._reservationId = State(initialValue: BookReservationManager.shared.getReservationId(bookId: book.id))
        self._parentIsBookReserved = parentIsBookReserved
        self._parentShowReserveSuccessAlert = parentShowReserveSuccessAlert
    }
    
    private func checkReservationStatus() {
        print("Checking reservation status for book: \(book.title) with ID: \(book.id)")
        
        // We need to check for both the current book ID and any possible database ID
        var bookIdToUse = book.id
        var foundReservation = false
        
        // First check local cache
        if BookReservationManager.shared.isReserved(bookId: book.id) {
            isBookReserved = true
            parentIsBookReserved = true
            reservationId = BookReservationManager.shared.getReservationId(bookId: book.id)
            print("Book is reserved locally with reservation ID: \(reservationId?.uuidString ?? "unknown")")
            foundReservation = true
        }
        
        // If we have a stored database ID for this ISBN, check that too
        if !foundReservation, let storedId = BookIdentifier.getDatabaseId(for: book.isbn) {
            print("Checking stored database ID: \(storedId) for ISBN: \(book.isbn)")
            bookIdToUse = storedId
            
            if BookReservationManager.shared.isReserved(bookId: bookIdToUse) {
                isBookReserved = true
                parentIsBookReserved = true
                reservationId = BookReservationManager.shared.getReservationId(bookId: bookIdToUse)
                print("Book is reserved locally using database ID with reservation ID: \(reservationId?.uuidString ?? "unknown")")
                foundReservation = true
            }
        }
        
        // If we still haven't found a reservation, check with the server
        if !foundReservation {
            Task {
                do {
                    // Get current user ID from UserDefaults
                    guard let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                        return
                    }
                    
                    print("Checking database for reservation: book_id=\(bookIdToUse.uuidString), member_id=\(userId)")
                    
                    // Check if this book is already reserved by the current user
                    let response = try await supabase
                        .from("BookReservation")
                        .select("id")
                        .eq("book_id", value: bookIdToUse.uuidString)
                        .eq("member_id", value: userId)
                        .execute()
                    
                    // Try to parse the response data directly for debugging
                    if let jsonString = String(data: response.data, encoding: .utf8) {
                        print("Raw reservation response: \(jsonString)")
                    }
                    
                    struct ReservationResponse: Codable {
                        let id: String
                    }
                    
                    // Parse the response
                    if let jsonString = String(data: response.data, encoding: .utf8),
                       let jsonData = jsonString.data(using: .utf8),
                       let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                       !jsonArray.isEmpty,
                       let firstReservation = jsonArray.first,
                       let reservationIdString = firstReservation["id"] as? String,
                       let reservationUUID = UUID(uuidString: reservationIdString) {
                        
                        // Book is reserved, update the UI
                        await MainActor.run {
                            isBookReserved = true
                            parentIsBookReserved = true
                            reservationId = reservationUUID
                            // Save to BookReservationManager for both IDs
                            BookReservationManager.shared.setReservation(bookId: book.id, reservationId: reservationUUID)
                            if bookIdToUse != book.id {
                                BookReservationManager.shared.setReservation(bookId: bookIdToUse, reservationId: reservationUUID)
                            }
                        }
                        print("Found reservation in database with ID: \(reservationUUID.uuidString)")
                    } else {
                        // Try decoding with JSONDecoder as fallback
                        let decoder = JSONDecoder()
                        if let reservations = try? decoder.decode([ReservationResponse].self, from: response.data),
                           let firstReservation = reservations.first,
                           let reservationUUID = UUID(uuidString: firstReservation.id) {
                            
                            // Book is reserved, update the UI
                            await MainActor.run {
                                isBookReserved = true
                                parentIsBookReserved = true
                                reservationId = reservationUUID
                                // Save to BookReservationManager for both IDs
                                BookReservationManager.shared.setReservation(bookId: book.id, reservationId: reservationUUID)
                                if bookIdToUse != book.id {
                                    BookReservationManager.shared.setReservation(bookId: bookIdToUse, reservationId: reservationUUID)
                                }
                            }
                            print("Found reservation in database with ID: \(reservationUUID.uuidString)")
                        } else {
                            // Book is not reserved, update the UI
                            await MainActor.run {
                                isBookReserved = false
                                parentIsBookReserved = false
                                reservationId = nil
                                // Make sure it's removed from BookReservationManager if needed
                                if BookReservationManager.shared.isReserved(bookId: book.id) {
                                    BookReservationManager.shared.removeReservation(bookId: book.id)
                                }
                                if bookIdToUse != book.id && BookReservationManager.shared.isReserved(bookId: bookIdToUse) {
                                    BookReservationManager.shared.removeReservation(bookId: bookIdToUse)
                                }
                            }
                            print("No reservation found in database for book: \(bookIdToUse.uuidString)")
                        }
                    }
                } catch {
                    print("Error checking reservation status: \(error)")
                }
            }
        }
    }
    
    private func reserveBook() async {
        // Begin reservation operation - return if already in progress
        if !BookReservationManager.shared.beginOperation(bookId: book.id) {
            print("Reservation operation already in progress for book: \(book.id)")
            return
        }
        
        print("Starting reservation process for book: \(book.title)")
        isReserving = true
        
        do {
            // First get a valid member ID from the database
            guard let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            }
            
            // When we're in wishlist, the book ID might be different from the one in the database
            // Try to get the correct database ID for this book
            var bookIdToUse = book.id
            
            // If we have a stored database ID for this ISBN, use that instead
            if let storedId = BookIdentifier.getDatabaseId(for: book.isbn) {
                print("Using stored database ID: \(storedId) instead of \(book.id) for ISBN: \(book.isbn)")
                bookIdToUse = storedId
            }
            
            // Create the reservation with the correct book ID
            let reservation = BookReservation(
                id: UUID(),
                created_at: Date(),
                member_id: UUID(uuidString: userId)!,
                book_id: bookIdToUse
            )
            
            // First check if we already have a reservation for this book
            if BookReservationManager.shared.isReserved(bookId: bookIdToUse) {
                print("Book is already reserved locally, not creating duplicate reservation")
                BookReservationManager.shared.endOperation(bookId: book.id)
                return
            }
            
            // Insert the reservation
            try await supabase
                .from("BookReservation")
                .insert(reservation)
                .execute()
            
            // Update book's available quantity - only do this here, nowhere else
            if currentAvailability > 0 {
                // Update the database with the current availability value
                try await supabase
                    .from("Books")
                    .update(["availableQuantity": currentAvailability - 1])
                    .eq("id", value: bookIdToUse)
                    .execute()
                
                // Update our local state to match what we just set in the database
                await MainActor.run {
                    currentAvailability -= 1
                }
            }
            
            print("Book reserved successfully! New availability: \(currentAvailability)")
            
            // Update UI state and show success alert
            await MainActor.run {
                isBookReserved = true
                parentIsBookReserved = true
                reservationId = reservation.id
                // Update local cache
                BookReservationManager.shared.setReservation(bookId: book.id, reservationId: reservation.id)
                BookReservationManager.shared.setReservation(bookId: bookIdToUse, reservationId: reservation.id)
                
                // Broadcast reservation change to all instances
                broadcastReservationChange(bookId: book.id, isReserved: true)
                if bookIdToUse != book.id {
                    broadcastReservationChange(bookId: bookIdToUse, isReserved: true)
                }
                
                // Notify that book status has changed
                NotificationCenter.default.post(name: Notification.Name("RefreshBookStatus"), object: nil)
                
                // Show success alert - this is not working reliably
                print("Attempting to show reserve success alert from within reserveBook")
                parentShowReserveSuccessAlert = true
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
            
            // When we're in wishlist, the book ID might be different from the one in the database
            // Try to get the correct database ID for this book
            var bookIdToUse = book.id
            
            // If we have a stored database ID for this ISBN, use that instead
            if let storedId = BookIdentifier.getDatabaseId(for: book.isbn) {
                print("Using stored database ID: \(storedId) instead of \(book.id) for ISBN: \(book.isbn)")
                bookIdToUse = storedId
            }
            
            // Check if this book is already removed from the reservation
            if !BookReservationManager.shared.isReserved(bookId: bookIdToUse) && !BookReservationManager.shared.isReserved(bookId: book.id) {
                print("Book is not reserved locally, no need to remove reservation")
                await MainActor.run {
                    isBookReserved = false
                    self.reservationId = nil
                }
                BookReservationManager.shared.endOperation(bookId: book.id)
                return
            }
            
            // Delete the reservation
            try await supabase
                .from("BookReservation")
                .delete()
                .eq("id", value: reservationId)
                .execute()
            
            // Increase book's available quantity - only do this here, nowhere else
            // Use the current availability rather than the book's property
            try await supabase
                .from("Books")
                .update(["availableQuantity": currentAvailability + 1])
                .eq("id", value: bookIdToUse)
                .execute()
            
            // Update our local state
            await MainActor.run {
                currentAvailability += 1
            }
            
            print("Reservation removed successfully! New availability: \(currentAvailability)")
            await MainActor.run {
                isBookReserved = false
                parentIsBookReserved = false
                self.reservationId = nil
                // Update local cache
                BookReservationManager.shared.removeReservation(bookId: book.id)
                BookReservationManager.shared.removeReservation(bookId: bookIdToUse)
                
                // Broadcast reservation change to all instances
                broadcastReservationChange(bookId: book.id, isReserved: false)
                if bookIdToUse != book.id {
                    broadcastReservationChange(bookId: bookIdToUse, isReserved: false)
                }
                
                // Notify that book status has changed
                NotificationCenter.default.post(name: Notification.Name("RefreshBookStatus"), object: nil)
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
            // Reserve Button
            if currentAvailability > 0 && !parentIsBookReserved {
                Button(action: {
                    Task {
                        await reserveBook()
                        
                        // Force show the success alert on the main thread
                        await MainActor.run {
                            print("Showing reserve success alert")
                            parentShowReserveSuccessAlert = true
                        }
                    }
                }) {
                    if isReserving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Reserve")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(isReserving)
            } else if parentIsBookReserved {
                Button(action: {
                    showCancelConfirmation = true
                }) {
                    if isReserving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Cancel Reservation")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(isReserving)
            } else {
                Button(action: {}) {
                    Text("Currently Unavailable")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(true)
            }
            
            // Wishlist Button
            Button(action: {
                if addedToWishlist {
                    showRemoveConfirmation = true
                } else {
                    addBookToWishlist()
                }
            }) {
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
        .alert("Cancel Reservation", isPresented: $showCancelConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm", role: .destructive) {
                Task {
                    await removeReservation()
                }
            }
        } message: {
            Text("Are you sure you want to cancel your reservation for '\(book.title)'?")
        }
        .onAppear {
            print("ActionButtonsView appeared for book: \(book.title) with ID: \(book.id)")
            checkIfBookInWishlist()
            checkReservationStatus()
            
            // If this is accessed from wishlist (addedToWishlist is already true), 
            // make sure other state is updated
            if addedToWishlist {
                // Update WishlistManager shared state
                WishlistManager.shared.setInWishlist(isbn: book.isbn)
                print("Book is in wishlist, updating shared state")
            }
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
                
                // Get existing wishlist for the user - don't use .single() to avoid the error
                let response = try await SupabaseManager.shared.client
                    .from("Members")
                    .select("wishlist")
                    .eq("id", value: userId)
                    .execute()
                
                // Parse the response to get current wishlist
                if let jsonString = String(data: response.data, encoding: .utf8),
                   let jsonData = jsonString.data(using: .utf8),
                   let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                   let firstMember = jsonArray.first,
                   let wishlist = firstMember["wishlist"] as? [String] {
                    
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
                                    .execute()
                                
                                if let jsonString = String(data: bookResponse.data, encoding: .utf8),
                                   let jsonData = jsonString.data(using: .utf8),
                                   let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                                   let firstBook = jsonArray.first,
                                   let isbn = firstBook["isbn"] as? String {
                                    
                                    if isbn == book.isbn {
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
                        if inWishlist {
                            WishlistManager.shared.setInWishlist(isbn: book.isbn)
                        }
                    }
                } else {
                    print("Could not parse wishlist data: \(String(data: response.data, encoding: .utf8) ?? "nil")")
                    await MainActor.run {
                        addedToWishlist = false
                    }
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
                if let jsonString = String(data: verifyResponse.data, encoding: .utf8),
                   let jsonData = jsonString.data(using: .utf8),
                   let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                   let firstBook = jsonArray.first,
                   let databaseId = firstBook["id"] as? String {
                    
                    // Use the ID from the database, which is the canonical ID for this ISBN
                    dbBookId = databaseId
                    print("Using database ID \(dbBookId) instead of local ID \(bookId) for ISBN \(isbn)")
                    
                    // Update our BookIdentifier map
                    if let uuid = UUID(uuidString: dbBookId) {
                        BookIdentifier.setDatabaseId(uuid, for: isbn)
                    }
                }
                
                // Get existing wishlist for the user
                let response = try await SupabaseManager.shared.client
                    .from("Members")
                    .select("wishlist")
                    .eq("id", value: userId)
                    .execute()
                
                // Parse the response to get current wishlist using safer approach
                if let jsonString = String(data: response.data, encoding: .utf8),
                   let jsonData = jsonString.data(using: .utf8),
                   let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                   let firstMember = jsonArray.first {
                    
                    // Get the wishlist or create empty array if it doesn't exist
                    var updatedWishlist = (firstMember["wishlist"] as? [String]) ?? []
                    
                    print("Current wishlist before addition: \(updatedWishlist)")
                    
                    // Check if book is already in wishlist by ID
                    if updatedWishlist.contains(dbBookId) {
                        print("⚠️ Book is already in wishlist with matching ID, not adding duplicate")
                        await showAlert("This book is already in your wishlist")
                        isAddingToWishlist = false
                        return
                    }
                    
                    // Check if any books in the wishlist have the same ISBN
                    var alreadyInWishlist = false
                    for existingBookId in updatedWishlist {
                        let bookResponse = try await SupabaseManager.shared.client
                            .from("Books")
                            .select("isbn")
                            .eq("id", value: existingBookId)
                            .execute()
                        
                        if let jsonString = String(data: bookResponse.data, encoding: .utf8),
                           let jsonData = jsonString.data(using: .utf8),
                           let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                           let firstBook = jsonArray.first,
                           let existingIsbn = firstBook["isbn"] as? String {
                            
                            if existingIsbn == isbn {
                                print("⚠️ Book with ISBN \(isbn) is already in wishlist with ID \(existingBookId), not adding duplicate")
                                alreadyInWishlist = true
                                break
                            }
                        }
                    }
                    
                    if alreadyInWishlist {
                        await showAlert("This book is already in your wishlist")
                        isAddingToWishlist = false
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
                            
                            // Update WishlistManager
                            WishlistManager.shared.setInWishlist(isbn: book.isbn)
                            
                            // Notify that book status has changed
                            NotificationCenter.default.post(name: Notification.Name("RefreshBookStatus"), object: nil)
                        }
                    } else {
                        print("❌ Failed to update wishlist in Supabase: Status code \(updateResponse.status)")
                        await showAlert("Failed to update wishlist")
                    }
                } else {
                    print("Failed to retrieve or parse wishlist data")
                    await showAlert("Failed to retrieve your wishlist")
                    isAddingToWishlist = false
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
                    .execute()
                
                // Parse the response using safer JSON approach
                if let jsonString = String(data: response.data, encoding: .utf8),
                   let jsonData = jsonString.data(using: .utf8),
                   let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                   let firstMember = jsonArray.first,
                   var wishlist = firstMember["wishlist"] as? [String] {
                    
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
                                    .execute()
                                
                                if let jsonString = String(data: bookResponse.data, encoding: .utf8),
                                   let jsonData = jsonString.data(using: .utf8),
                                   let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                                   let firstBook = jsonArray.first,
                                   let bookIsbn = firstBook["isbn"] as? String {
                                    
                                    if bookIsbn == isbn {
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
                            
                            // Update WishlistManager
                            WishlistManager.shared.removeFromWishlist(isbn: book.isbn)
                            
                            // Notify that book status has changed
                            NotificationCenter.default.post(name: Notification.Name("RefreshBookStatus"), object: nil)
                        }
                    } else {
                        print("❌ Failed to update wishlist in Supabase: Status code \(updateResponse.status)")
                        await showAlert("Failed to update wishlist")
                    }
                } else {
                    print("Failed to retrieve or parse wishlist data")
                    await showAlert("Failed to retrieve your wishlist")
                    isRemovingFromWishlist = false
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

// Add a ReservationManager notification function to keep all instances in sync
extension Notification.Name {
    static let reservationStatusChanged = Notification.Name("reservationStatusChanged")
}

// Function to broadcast reservation changes
func broadcastReservationChange(bookId: UUID, isReserved: Bool) {
    // Update the shared manager first
    if isReserved {
        if let reservationId = BookReservationManager.shared.getReservationId(bookId: bookId) {
            print("Broadcasting reservation for book ID: \(bookId), reservation ID: \(reservationId)")
        } else {
            print("Broadcasting reservation for book ID: \(bookId), but no reservation ID found")
        }
    } else {
        print("Broadcasting reservation removal for book ID: \(bookId)")
    }
    
    // Send notification to update all instances
    NotificationCenter.default.post(
        name: .reservationStatusChanged,
        object: nil,
        userInfo: ["bookId": bookId, "isReserved": isReserved]
    )
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
    @State private var forceUpdateKey = UUID()
    @State private var isBookReserved: Bool
    @State private var showReserveSuccessAlert = false
    @State private var showCancelConfirmation = false
    
    init(book: Book, supabase: SupabaseClient, isPresented: Binding<Bool>) {
        self.book = book
        self.supabase = supabase
        self._isPresented = isPresented
        self._currentAvailability = State(initialValue: book.availableQuantity)
        // Check if book is already reserved at init time
        let reserved = BookReservationManager.shared.isReserved(bookId: book.id)
        self._isBookReserved = State(initialValue: reserved)
        print("BookDetailCard init - Book \(book.title) reserved status: \(reserved)")
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
                            currentAvailability: $currentAvailability,
                            parentIsBookReserved: $isBookReserved,
                            parentShowReserveSuccessAlert: $showReserveSuccessAlert
                        )
                        .id(forceUpdateKey)
                        
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
            print("BookDetailCard onAppear for book: \(book.title)")
            
            // Force update to ensure consistency
            forceUpdateKey = UUID()
            
            // Get the database ID if available
            var bookIdToUse = book.id
            if let storedId = BookIdentifier.getDatabaseId(for: book.isbn) {
                print("Using stored database ID: \(storedId) for ISBN: \(book.isbn)")
                bookIdToUse = storedId
            }
            
            // Update reservation status immediately based on BookReservationManager
            // Check both the local ID and the database ID
            if BookReservationManager.shared.isReserved(bookId: book.id) || 
               (bookIdToUse != book.id && BookReservationManager.shared.isReserved(bookId: bookIdToUse)) {
                isBookReserved = true
                print("BookDetailCard onAppear - Book is reserved")
            } else {
                isBookReserved = false
                print("BookDetailCard onAppear - Book is not reserved")
                
                // Check if there's a reservation for this book and user in the database
                Task {
                    do {
                        let userId = UserDefaults.standard.string(forKey: "currentMemberId") ?? ""
                        if !userId.isEmpty {
                            let response = try await supabase
                                .from("BookReservation")
                                .select("id")
                                .eq("book_id", value: bookIdToUse.uuidString)
                                .eq("member_id", value: userId)
                                .execute()
                            
                            print("Checking for reservation immediately on appear using ID: \(bookIdToUse)")
                            
                            if let jsonString = String(data: response.data, encoding: .utf8),
                               let jsonData = jsonString.data(using: .utf8),
                               let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                               !jsonArray.isEmpty,
                               let firstReservation = jsonArray.first,
                               let reservationId = firstReservation["id"] as? String,
                               let reservationUUID = UUID(uuidString: reservationId) {
                                print("Found reservation in database: \(reservationId)")
                                // Save the reservation with both IDs to ensure consistency
                                BookReservationManager.shared.setReservation(bookId: book.id, reservationId: reservationUUID)
                                BookReservationManager.shared.setReservation(bookId: bookIdToUse, reservationId: reservationUUID)
                                
                                await MainActor.run {
                                    isBookReserved = true
                                    forceUpdateKey = UUID() // Force view to update
                                    
                                    // Broadcast the change to all instances
                                    broadcastReservationChange(bookId: book.id, isReserved: true)
                                    if bookIdToUse != book.id {
                                        broadcastReservationChange(bookId: bookIdToUse, isReserved: true)
                                    }
                                }
                            }
                        }
                    } catch {
                        print("Error checking reservation on appear: \(error)")
                    }
                }
            }
            
            // Always fetch the latest availability from the database when the view appears
            Task {
                do {
                    print("Fetching latest availability for book: \(book.title) with ID: \(book.id)")
                    let response = try await supabase
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
            
            // Check initial wishlist and reservation status to ensure UI is up-to-date
            DispatchQueue.main.async {
                addedToWishlist = WishlistManager.shared.isBookInWishlist(isbn: book.isbn)
                
                // If we already know it's in the wishlist, update the shared state
                if addedToWishlist {
                    WishlistManager.shared.setInWishlist(isbn: book.isbn)
                    print("Book is in wishlist, updating WishlistManager state")
                }
                
                // Directly check BookReservationManager as first priority
                if let reservationId = BookReservationManager.shared.getReservationId(bookId: book.id) {
                    print("Book is already reserved with ID: \(reservationId)")
                    isBookReserved = true
                    // Force UI update
                    forceUpdateKey = UUID()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .reservationStatusChanged)) { notification in
            if let bookId = notification.userInfo?["bookId"] as? UUID,
               let isReserved = notification.userInfo?["isReserved"] as? Bool {
                if bookId == book.id {
                    // Update this view's reservation status
                    print("BookDetailCard received reservation change notification: \(isReserved ? "reserved" : "not reserved")")
                    isBookReserved = isReserved
                    forceUpdateKey = UUID() // Force view to update
                }
            }
        }
        .onDisappear {
            // This ensures the reservation status persists when the view disappears
            // ONLY log the status, don't make any database updates here
            if BookReservationManager.shared.getReservationId(bookId: book.id) != nil {
                print("Persisting reservation state for book: \(book.title) with ID: \(book.id)")
            }
        }
        .alert("Reservation Successful", isPresented: $showReserveSuccessAlert) {
            Button("OK", role: .cancel) {
                print("Success alert OK button tapped")
            }
        } message: {
            Text("Book has been successfully reserved!")
        }
        .onChange(of: showReserveSuccessAlert) { oldValue, newValue in
            print("BookDetailCard: Reserve success alert changed from \(oldValue) to \(newValue)")
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

