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
            }
            .onAppear {
                Task {
                    await fetchReservations()
                }
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
    
    // MARK: - Extracted View Components
    
    private var mainContent: some View {
        ZStack {
            if isLoading {
                LoadingView()
            } else if reservations.isEmpty {
                EmptyView()
            } else {
                reservationsList
            }
        }
    }
    
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
    
    //MARK: - issue reserved books:
    func issueReservedBook(reservation: ReservationRecord) async {
        guard let book = reservation.book, let member = reservation.member else {
            errorMessage = "Missing book or member information"
            return
        }
        
        isLoading = true
        
        do {
            // First, check if the book exists and has available quantity
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
            
            // Print the data for debugging
            print("Book query response: \(response)")
            
            let currentQuantity = response.availableQuantity
            
            // Check if there are books available
            guard currentQuantity > 0 else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No books available"])
            }
            
            // Create the issueBooks object
            let issueDate = Date()
            let returnDate = Calendar.current.date(byAdding: .day, value: 10, to: issueDate)
            
            let newIssue = issueBooks(
                id: UUID(),
                isbn: book.isbn ?? "",
                memberEmail: member.email,
                issueDate: issueDate,
                returnDate: returnDate
            )
            
            // Start a transaction using the same client
            try await supabase.rpc("begin_transaction")
            
            // Insert the issued book record
            try await supabase
                .from("issuebooks")
                .insert(newIssue)
                .execute()
            
            // Update the available quantity
            try await supabase
                .from("Books")
                .update(["availableQuantity": currentQuantity - 1])
                .eq("id", value: book.id.uuidString)
                .execute()
            
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
                        
                        // Reservation Date
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                            Text(reservation.created_at.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
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
            }
            .padding(16)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
    }
    
    struct ReservationDetailSheet: View {
        let reservation: ReservationRecord
        let issueAction: () -> Void
        @Environment(\.dismiss) private var dismiss
        
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
                                title: "Status",
                                value: "Reserved",
                                valueColor: .blue
                            )
                        }
                        
                        // Action Button
                        Button(action: issueAction) {
                            Text("Issue Book")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.top)
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
}
