import SwiftUI
import Supabase
struct ReservedBookView: View {
    @State private var searchText = ""
    @State private var reservations: [ReservationRecord] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedReservation: ReservationRecord?
    @State private var showingDetail = false
    
    // MARK: - Issue reserved book states
    @State private var showIssueConfirmation = false
    @State private var issuedReservationId: UUID?
    @State private var showSuccessAlert = false
    
    // MARK: - Cleanup timer
    @State private var cleanupTimer: Timer?
    
    private let supabase = SupabaseConfig.client
    
    var filteredReservations: [ReservationRecord] {
        if searchText.isEmpty { return reservations }
        return reservations.filter { reservation in
            let bookTitle = reservation.book?.title.lowercased() ?? ""
            let memberName = reservation.member?.name.lowercased() ?? ""
            let searchQuery = searchText.lowercased()
            return bookTitle.contains(searchQuery) || memberName.contains(searchQuery)
        }
    }
    
    var body: some View {
        mainContent
            .searchable(text: $searchText, prompt: "Search reservations")
            .refreshable {
                isLoading = true
                await fetchReservations()
                await checkExpiredReservations()
            }
            .onAppear {
                Task {
                    await fetchReservations()
                    await checkExpiredReservations()
                    startCleanupTimer()
                }
            }
            .onDisappear {
                cleanupTimer?.invalidate()
                cleanupTimer = nil
            }
            .onChange(of: searchText) { _ in
                Task {
                    await fetchReservations()
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let reservation = selectedReservation {
                    ReservationDetailSheet(
                        reservation: reservation,
                        issueAction: {
                            showingDetail = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showIssueConfirmation = true
                            }
                        }
                    )
                }
            }
            .alert("Issue Book", isPresented: $showIssueConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Issue") {
                    if let reservation = selectedReservation {
                        Task {
                            await issueReservedBook(reservation: reservation)
                        }
                    }
                }
            } message: {
                if let reservation = selectedReservation {
                    Text("Are you sure you want to issue '\(reservation.book?.title ?? "Unknown Book")' to \(reservation.member?.name ?? "Unknown Member")?")
                } else {
                    Text("Issue reserved book?")
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("Book has been successfully issued!")
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
    }
    
    // MARK: - Timer Functions
    
    private func startCleanupTimer() {
        cleanupTimer?.invalidate()
        // Check for expired reservations every 5 minutes
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { _ in
            Task {
                await checkExpiredReservations()
            }
        }
    }
    
    // MARK: - Extracted View Components
    
//    private var mainContent: some View {
//        ZStack {
//            if isLoading {
//                LoadingView()
//            } else if reservations.isEmpty {
//                EmptyStateView(
//                    icon: "clock.badge.exclamationmark",
//                    title: "No Reservations Found",
//                    message: "Reservations expire automatically after 24 hours if not processed. Check back later or refresh the page."
//                )
//            } else {
//                reservationsList
//            }
//        }
//    }
    
    private var mainContent: some View {
        ZStack {
            if isLoading {
                LoadingView()
            } else if reservations.isEmpty {
                EmptyStateView(
                    icon: "clock.badge.exclamationmark",
                    title: "No Reservations Found",
                    message: "Reservations expire automatically after 24 hours if not processed. Check back later or refresh the page."
                )
            } else if filteredReservations.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results Found",
                    message: "Try searching with a different keyword."
                )
            } else {
                reservationsList
            }
        }
    }

//    private var filteredReservations: [ReservationRecord] {
//        reservations.filter { reservation in
//            searchText.isEmpty || reservation.book?.title?.localizedCaseInsensitiveContains(searchText) == true
//        }
//    }
    
    private var reservationsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredReservations) { reservation in
                    ReservationCard(
                        reservation: reservation,
                        issueAction: {
                            selectedReservation = reservation
                            showIssueConfirmation = true
                        }
                    )
                    .onTapGesture {
                        selectedReservation = reservation
                        showingDetail = true
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Data Fetching and Processing
    
    func fetchReservations() async {
        do {
            let response: [ReservationRecord] = try await supabase.database
                .from("BookReservation")
                .select("""
                    *, 
                    member:Members(*), 
                    book:Books(*)
                    """)
                .order("created_at", ascending: false) // Latest reservations first
                .execute()
                .value
            
            await MainActor.run {
                reservations = response
                isLoading = false
                errorMessage = nil
            }
        } catch {
            await MainActor.run {
                print("Error fetching reservations: \(error)")
                errorMessage = "Failed to load reservations"
                isLoading = false
            }
        }
    }
    
    // Check for and process expired reservations
    func checkExpiredReservations() async {
        print("Checking for expired reservations...")
        
        var expiredReservations: [ReservationRecord] = []
        let now = Date()
        
        // Identify expired reservations (older than 24 hours)
        for reservation in reservations {
            let expirationDate = Calendar.current.date(byAdding: .hour, value: 24, to: reservation.created_at) ?? Date()
            if now > expirationDate {
                expiredReservations.append(reservation)
            }
        }
        
        if expiredReservations.isEmpty {
            print("No expired reservations found.")
            return
        }
        
        print("Found \(expiredReservations.count) expired reservations. Processing...")
        
        // Process each expired reservation
        for reservation in expiredReservations {
            await processExpiredReservation(reservation)
        }
        
        // Refresh the reservations list
        await fetchReservations()
    }
    
    // Process a single expired reservation
    private func processExpiredReservation(_ reservation: ReservationRecord) async {
        guard let book = reservation.book, let isbn = book.isbn else {
            print("Missing book information for reservation \(reservation.id)")
            return
        }
        
        do {
            // Start a transaction
            try await SupabaseManager.shared.client.rpc("begin_transaction")
            
            // First, get the current book quantities
            let response = try await SupabaseManager.shared.client
                .from("Books")
                .select("availableQuantity, quantity")
                .eq("isbn", value: isbn)
                .single()
                .execute()
            
            guard let data = response.data as? [[String: Any]],
                  let firstBook = data.first,
                  let availableQuantity = firstBook["availableQuantity"] as? Int,
                  let quantity = firstBook["quantity"] as? Int else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get book quantity"])
            }
            
            // Update book quantities (increment availableQuantity by 1)
            try await SupabaseManager.shared.client
                .from("Books")
                .update(["availableQuantity": availableQuantity + 1])
                .eq("isbn", value: isbn)
                .execute()
            
            // Delete the reservation
            try await SupabaseManager.shared.client
                .from("BookReservation")
                .delete()
                .eq("id", value: reservation.id.uuidString)
                .execute()
            
            // Commit the transaction
            try await SupabaseManager.shared.client.rpc("commit_transaction")
            
            print("Successfully processed expired reservation \(reservation.id) for book: \(book.title)")
            
        } catch {
            // Rollback the transaction if it was started
            try? await SupabaseManager.shared.client.rpc("rollback_transaction")
            print("Error processing expired reservation \(reservation.id): \(error.localizedDescription)")
        }
    }
    
    //MARK: - issue reserved books:
//    func issueReservedBook(reservation: ReservationRecord) async {
//        guard let book = reservation.book, let member = reservation.member else {
//            errorMessage = "Missing book or member information"
//            return
//        }
//        
//        isLoading = true
//        
//        do {
//            // First, check if the book exists and has available quantity
//            struct BookQuantity: Codable {
//                let availableQuantity: Int
//            }
//            
//            let response: BookQuantity = try await supabase
//                .from("Books")
//                .select("availableQuantity")
//                .eq("id", value: book.id.uuidString)
//                .single()
//                .execute()
//                .value
//            
//            // Print the data for debugging
//            print("Book query response: \(response)")
//            
//            let currentQuantity = response.availableQuantity
//            
//            // Check if there are books available
//            guard currentQuantity > 0 else {
//                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No books available"])
//            }
//            
//            // Create the issueBooks object
//            let issueDate = Date()
//            let returnDate = Calendar.current.date(byAdding: .day, value: 10, to: issueDate)
//            
//            let newIssue = issueBooks(
//                id: UUID(),
//                isbn: book.isbn ?? "",
//                memberEmail: member.email,
//                issueDate: issueDate,
//                returnDate: returnDate
//            )
//            
//            // Start a transaction using the same client
//            try await supabase.rpc("begin_transaction")
//            
//            // Insert the issued book record
//            try await supabase
//                .from("issuebooks")
//                .insert(newIssue)
//                .execute()
//            
//            // Update the available quantity
//            try await supabase
//                .from("Books")
//                .update(["availableQuantity": currentQuantity - 1])
//                .eq("id", value: book.id.uuidString)
//                .execute()
//            
//            // Delete the reservation
//            try await supabase
//                .from("BookReservation")
//                .delete()
//                .eq("id", value: reservation.id.uuidString)
//                .execute()
//            
//            // Commit the transaction
//            try await supabase.rpc("commit_transaction")
//            
//            await MainActor.run {
//                isLoading = false
//                issuedReservationId = reservation.id
//                showSuccessAlert = true
//                
//                // Remove the issued book from the local array
//                reservations.removeAll(where: { $0.id == reservation.id })
//            }
//        } catch {
//            // Rollback the transaction if it was started
//            try? await supabase.rpc("rollback_transaction")
//            
//            await MainActor.run {
//                print("Error issuing book: \(error)")
//                errorMessage = "Failed to issue book: \(error.localizedDescription)"
//                isLoading = false
//            }
//        }
//    }
//    
//    func issueReservedBook(reservation: ReservationRecord) async {
//        guard let book = reservation.book, let member = reservation.member else {
//            errorMessage = "Missing book or member information"
//            return
//        }
//        
//        isLoading = true
//        
//        do {
//            // Create the issueBooks object
//            let issueDate = Date()
//            let returnDate = Calendar.current.date(byAdding: .day, value: 10, to: issueDate)
//            
//            let newIssue = issueBooks(
//                id: UUID(),
//                isbn: book.isbn ?? "",
//                memberEmail: member.email,
//                issueDate: issueDate,
//                returnDate: returnDate,
//                actualReturnedDate: nil
//            )
//            
//            // Start a transaction using the same client
//            try await supabase.rpc("begin_transaction")
//            
//            // Insert the issued book record
//            try await supabase
//                .from("issuebooks")
//                .insert(newIssue)
//                .execute()
//            
//            // Query current quantity (we still need this to keep track)
//            struct BookQuantity: Codable {
//                let availableQuantity: Int
//            }
//            
//            let response: BookQuantity = try await supabase
//                .from("Books")
//                .select("availableQuantity")
//                .eq("id", value: book.id.uuidString)
//                .single()
//                .execute()
//                .value
//            
//            let currentQuantity = response.availableQuantity
//            
//            // Update the available quantity only if it's greater than 0
//            // This prevents negative quantities but allows issuing reserved books
//            if currentQuantity > 0 {
//                try await supabase
//                    .from("Books")
//                    .update(["availableQuantity": currentQuantity - 1])
//                    .eq("id", value: book.id.uuidString)
//                    .execute()
//            }
//            
//            // Delete the reservation
//            try await supabase
//                .from("BookReservation")
//                .delete()
//                .eq("id", value: reservation.id.uuidString)
//                .execute()
//            
//            // Commit the transaction
//            try await supabase.rpc("commit_transaction")
//            
//            await MainActor.run {
//                isLoading = false
//                issuedReservationId = reservation.id
//                showSuccessAlert = true
//                
//                // Remove the issued book from the local array
//                reservations.removeAll(where: { $0.id == reservation.id })
//            }
//        } catch {
//            // Rollback the transaction if it was started
//            try? await supabase.rpc("rollback_transaction")
//            
//            await MainActor.run {
//                print("Error issuing book: \(error)")
//                errorMessage = "Failed to issue book: \(error.localizedDescription)"
//                isLoading = false
//            }
//        }
//    }
//    
    
    func issueReservedBook(reservation: ReservationRecord) async {
        guard let book = reservation.book, let member = reservation.member else {
            errorMessage = "Missing book or member information"
            return
        }
        
        isLoading = true
        
        do {
            // Check how many books the member has already issued
            // Using filter() to check for null values
            let countResponse = try await supabase
                .from("issuebooks")
                .select("id", count: .exact)
                .eq("member_email", value: member.email)
                .filter("actual_returned_date", operator: "is", value: "null") // Correct syntax for null check
                .execute()
            
            let currentlyIssuedCount = countResponse.count ?? 0
            
            // Check if the member has reached the limit
            if currentlyIssuedCount >= 5 {
                await MainActor.run {
                    errorMessage = "Member has reached the maximum limit of 5 issued books"
                    isLoading = false
                }
                return
            }
            
            // Create the issueBooks object
            let issueDate = Date()
            let returnDate = Calendar.current.date(byAdding: .day, value: 10, to: issueDate)
            
            let newIssue = issueBooks(
                id: UUID(),
                isbn: book.isbn ?? "",
                memberEmail: member.email,
                issueDate: issueDate,
                returnDate: returnDate,
                actualReturnedDate: nil
            )
            
            // Start a transaction using the same client
            try await supabase.rpc("begin_transaction")
            
            // Insert the issued book record
            try await supabase
                .from("issuebooks")
                .insert(newIssue)
                .execute()
            
            // Query current quantity (we still need this to keep track)
            struct BookQuantity: Codable {
                let availableQuantity: Int
            }
            
            let response: BookQuantity = try await supabase
                .from("Books")
                .select("availableQuantity")
                .eq("id", value: book.id.uuidString)
                .single()
                .execute()
                .value
            
            let currentQuantity = response.availableQuantity
            
            // Update the available quantity only if it's greater than 0
            // This prevents negative quantities but allows issuing reserved books
            if currentQuantity > 0 {
                try await supabase
                    .from("Books")
                    .update(["availableQuantity": currentQuantity - 1])
                    .eq("id", value: book.id.uuidString)
                    .execute()
            }
            
            // Delete the reservation
            try await supabase
                .from("BookReservation")
                .delete()
                .eq("id", value: reservation.id.uuidString)
                .execute()
            
            // Commit the transaction
            try await supabase.rpc("commit_transaction")
            
            await MainActor.run {
                isLoading = false
                issuedReservationId = reservation.id
                showSuccessAlert = true
                
                // Remove the issued book from the local array
                reservations.removeAll(where: { $0.id == reservation.id })
            }
        } catch {
            // Rollback the transaction if it was started
            try? await supabase.rpc("rollback_transaction")
            
            await MainActor.run {
                print("Error issuing book: \(error)")
                errorMessage = "Failed to issue book: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    struct ReservationCard: View {
        let reservation: ReservationRecord
        let issueAction: () -> Void
        @State private var timeRemaining: TimeInterval = 0
        @State private var timer: Timer?
        
        var formattedTimeRemaining: String {
            if timeRemaining <= 0 {
                return "Expired"
            }
            
            let hours = Int(timeRemaining) / 3600
            let minutes = Int(timeRemaining) % 3600 / 60
            
            if hours > 0 {
                return "\(hours)h \(minutes)m remaining"
            } else {
                return "\(minutes)m remaining"
            }
        }
        
        var timeRemainingColor: Color {
            if timeRemaining <= 0 {
                return .red
            } else if timeRemaining < 3600 { // Less than 1 hour
                return .orange
            } else {
                return .blue
            }
        }
        
        var body: some View {
            VStack(spacing: 0) {
                // Book Cover and Basic Info
                HStack(alignment: .top, spacing: 16) {
                    // Book Cover
                    if let imageURL = reservation.book?.imageURL,
                       let url = URL(string: imageURL) {
                        CachedAsyncImage(url: url)
                            .frame(width: 100, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 100, height: 150)
                            .overlay(
                                Image(systemName: "book.closed")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    // Book and Member Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(reservation.book?.title ?? "Unknown Book")
                            .font(.headline)
                            .lineLimit(2)
                        
                        Text(reservation.book?.author ?? "Unknown Author")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Member Info
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text(reservation.member?.name ?? "Unknown Member")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Reservation Date and Time Remaining
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                Text(reservation.created_at.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Countdown Timer
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(timeRemainingColor)
                                Text(formattedTimeRemaining)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(timeRemainingColor)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Action Button
                Button(action: issueAction){
                    Text("Issue Book")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.top, 12)
                .disabled(timeRemaining <= 0)
                .opacity(timeRemaining <= 0 ? 0.5 : 1)
            }
            .padding(16)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            .onAppear {
                calculateTimeRemaining()
                startTimer()
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
        
        private func calculateTimeRemaining() {
            let expirationDate = Calendar.current.date(byAdding: .hour, value: 24, to: reservation.created_at) ?? Date()
            timeRemaining = expirationDate.timeIntervalSince(Date())
            if timeRemaining < 0 {
                timeRemaining = 0
            }
        }
        
        private func startTimer() {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                calculateTimeRemaining()
            }
        }
    }
    
    struct ReservationDetailSheet: View {
        let reservation: ReservationRecord
        let issueAction: () -> Void
        @Environment(\.dismiss) private var dismiss
        @State private var timeRemaining: TimeInterval = 0
        @State private var timer: Timer?
        
        private var expirationDate: Date {
            Calendar.current.date(byAdding: .hour, value: 24, to: reservation.created_at) ?? Date()
        }
        
        var formattedTimeRemaining: String {
            if timeRemaining <= 0 {
                return "Expired"
            }
            
            let hours = Int(timeRemaining) / 3600
            let minutes = Int(timeRemaining) % 3600 / 60
            
            if hours > 0 {
                return "\(hours) hours \(minutes) minutes remaining"
            } else {
                return "\(minutes) minutes remaining"
            }
        }
        
        var timeRemainingColor: Color {
            if timeRemaining <= 0 {
                return .red
            } else if timeRemaining < 3600 { // Less than 1 hour
                return .orange
            } else {
                return .blue
            }
        }
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // Book Cover
                        if let imageURL = reservation.book?.imageURL,
                           let url = URL(string: imageURL) {
                            CachedAsyncImage(url: url)
                                .frame(height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 4)
                        }
                        
                        // Book Details
                        DetailSection(title: "Book Information") {
                            DetailItem(title: "Title", value: reservation.book?.title ?? "N/A")
                            DetailItem(title: "Author", value: reservation.book?.author ?? "N/A")
                            if let isbn = reservation.book?.isbn {
                                DetailItem(title: "ISBN", value: isbn)
                            }
                            if let genre = reservation.book?.genre {
                                DetailItem(title: "Genre", value: genre)
                            }
                        }
                        
                        // Member Details
                        DetailSection(title: "Member Information") {
                            DetailItem(title: "Name", value: reservation.member?.name ?? "N/A")
                            DetailItem(title: "Email", value: reservation.member?.email ?? "N/A")
                            DetailItem(title: "Library", value: reservation.member?.selectedLibrary ?? "N/A")
                        }
                        
                        // Reservation Details
                        DetailSection(title: "Reservation Information") {
                            DetailItem(
                                title: "Reserved On",
                                value: reservation.created_at.formatted(date: .long, time: .shortened)
                            )
                            
                            DetailItem(
                                title: "Expires On",
                                value: expirationDate.formatted(date: .long, time: .shortened),
                                valueColor: timeRemaining > 0 ? .primary : .red
                            )
                            
                            DetailItem(
                                title: "Time Left",
                                value: formattedTimeRemaining,
                                valueColor: timeRemainingColor
                            )
                            
                            DetailItem(
                                title: "Status",
                                value: timeRemaining > 0 ? "Reserved" : "Expired",
                                valueColor: timeRemaining > 0 ? .blue : .red
                            )
                        }
                        
                        // Expiration Notice
                        if timeRemaining > 0 {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("Reservation Expiration Policy")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                }
                                
                                Text("This reservation will automatically expire in \(formattedTimeRemaining) if not processed. Once expired, the book will become available for others to reserve.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.red)
                                    Text("Reservation Expired")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                                
                                Text("This reservation has expired and will be automatically removed. The book is now available for others to reserve.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Action Button
                        Button(action: issueAction) {
                            Text("Issue Book")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(timeRemaining > 0 ? Color.blue : Color.gray)
                                .cornerRadius(12)
                        }
                        .padding(.top)
                        .disabled(timeRemaining <= 0)
                    }
                    .padding()
                }
                .navigationTitle("Reservation Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
                .onAppear {
                    calculateTimeRemaining()
                    startTimer()
                }
                .onDisappear {
                    timer?.invalidate()
                    timer = nil
                }
            }
        }
        
        private func calculateTimeRemaining() {
            timeRemaining = expirationDate.timeIntervalSince(Date())
            if timeRemaining < 0 {
                timeRemaining = 0
            }
        }
        
        private func startTimer() {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                calculateTimeRemaining()
            }
        }
    }
    
    struct DetailSection<Content: View>: View {
        let title: String
        let content: Content
        
        init(title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                content
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
    
    struct DetailItem: View {
        let title: String
        let value: String
        var valueColor: Color = .primary
        
        var body: some View {
            HStack(alignment: .top) {
                Text(title)
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                Text(value)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(valueColor)
            }
            .font(.subheadline)
        }
    }
    
    struct LoadingView: View {
        var body: some View {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.blue)
                Text("Loading reservations...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
        }
    }
    
    struct EmptyStateView: View {
        var icon: String
        var title: String
        var message: String

        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(.blue.opacity(0.7))
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
