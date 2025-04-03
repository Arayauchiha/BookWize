//
//  IssueBookView.swift
//  BookWize
//
//  Created by Anshika on 26/03/25.
//

import SwiftUI
import Supabase

struct IssueBookView: View {
    @StateObject private var circulationManager = IssuedBookManager.shared
    @State private var searchText = ""
    @State private var showingIssueForm = false

    var filteredLoans: [issueBooks] {
        if searchText.isEmpty {
            return circulationManager.loans.filter { $0.actualReturnedDate == nil }
        }
        return circulationManager.loans.filter { loan in
            (loan.isbn.localizedCaseInsensitiveContains(searchText) ||
            loan.memberEmail.localizedCaseInsensitiveContains(searchText)) &&
            loan.actualReturnedDate == nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if circulationManager.isLoading {
                    ProgressView()
                        .padding()
                } else if circulationManager.loans.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "No Books Issued",
                        message: "Start by issuing a new book"
                    )
                } else if !searchText.isEmpty && filteredLoans.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Results Found",
                        message: "Try searching with different keywords"
                    )
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredLoans) { loan in
                            EnhancedLoanCard(issuedBooks: loan)
                        }
                    }
                    .padding()
                }
            }
            
            VStack {
                Button {
                    showingIssueForm = true
                } label: {
                    Label("Issue Book", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(height: 60)
                        .frame(width: 370)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.vertical, 8)
            }
        }
        .searchable(text: $searchText, prompt: "Search Issue Books")
        .sheet(isPresented: $showingIssueForm) {
            IssueBookFormView { newLoan in
                Task {
                    await circulationManager.fetchIssuedBooks()
                }
            }
        }
        .task {
            await circulationManager.fetchIssuedBooks()
        }
        .alert("Error", isPresented: .constant(circulationManager.errorMessage != nil)) {
            Button("OK") {
                circulationManager.errorMessage = nil
            }
        } message: {
            Text(circulationManager.errorMessage ?? "")
        }
    }
}

// ADD: Enhanced loan card with book cover
struct EnhancedLoanCard: View {
    let issuedBooks: issueBooks
    @State private var bookCoverURL: URL?
    @State private var isLoadingCover = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Book Cover
                AsyncImage(url: bookCoverURL) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                    case .failure:
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "book.closed")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Book Details
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("ISBN: \(issuedBooks.isbn)", systemImage: "barcode")
                            .font(.subheadline)
                    }
                    
                    Text("Member Email: \(issuedBooks.memberEmail)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Issue Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(issuedBooks.issueDate, style: .date)
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Return Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let returnDate = issuedBooks.returnDate {
                        Text(returnDate, style: .date)
                            .font(.subheadline)
                    } else {
                        Text("Not Returned")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color.customCardBackground)
        .cornerRadius(12)
        .task {
            await fetchBookCover()
        }
    }
    
    // Function to fetch book cover
    private func fetchBookCover() async {
        // Construct OpenLibrary API URL for book cover
        let coverURL = "https://covers.openlibrary.org/b/isbn/\(issuedBooks.isbn)-M.jpg"
        bookCoverURL = URL(string: coverURL)
    }
}

struct IssueBookFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var circulationManager = IssuedBookManager.shared
    @State private var isbn = ""
    @State private var smartCardID = ""
    @State private var memberName = ""
    @State private var bookName = ""
    @State private var authorName = ""
    @State private var showingScanner = false
    @State private var showingSmartCardScanner = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    let onIssue: (issueBooks) -> Void
    
    // Auto-filled issue & return dates
    private let issueDate = Date()
    private let returnDate = Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date()
    
    // Computed property to check if all fields are filled
    private var isFormValid: Bool {
        !isbn.isEmpty &&
        !bookName.isEmpty &&
        !authorName.isEmpty &&
        !smartCardID.isEmpty &&
        !memberName.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Book Details Section
                Section(header: HStack {
                    Text("Book Details")
                    Spacer()
                    Button(action: {
                        showingScanner = true
                    }) {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(.blue)
                    }
                }) {
                    TextField("Scan ISBN", text: $isbn)
                        .keyboardType(.numberPad)
                        .onChange(of: isbn) { newValue in
                            if !newValue.isEmpty {
                                Task {
                                    await fetchBookDetails(isbn: newValue)
                                }
                            }
                        }
                    
                    TextField("Book Name", text: $bookName)
                        .disabled(isLoading)
                    TextField("Author", text: $authorName)
                        .disabled(isLoading)
                }
                
                // Member Details Section
                Section(header: HStack {
                    Text("Member Details")
                    Spacer()
                    Button(action: {
                        showingSmartCardScanner = true
                    }) {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(.blue)
                    }
                }) {
                    TextField("Scan Smart Card ID", text: $smartCardID)
                        .keyboardType(.numberPad)
                        .disabled(true)
                    
                    TextField("Member Name", text: $memberName)
                        .disabled(true)
                }
                
                // Issue Details Section
                Section(header: Text("Issue Details")) {
                    HStack {
                        Text("Issue Date")
                        Spacer()
                        Text(issueDate, style: .date)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Due Date")
                        Spacer()
                        Text(returnDate, style: .date)
                            .foregroundColor(.gray)
                    }
                }
                
                // Issue Book Button
                Button(action: issueBook) {
                    Label("Issue Book", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? AppTheme.primaryColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!isFormValid || isLoading)
                .padding()
                
            }
            .navigationTitle("Issue Book")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Book has been successfully issued!")
            }
            
            .sheet(isPresented: $showingScanner) {
                ISBNScannerView { scannedISBN in
                    isbn = scannedISBN
                    Task {
                        await fetchBookDetails(isbn: scannedISBN)
                    }
                }
            }
            .sheet(isPresented: $showingSmartCardScanner) {
                SmartCardScannerView { scannedCode in
                    smartCardID = scannedCode
                    Task {
                        await fetchMemberDetails(smartCardID: scannedCode)
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private func fetchBookDetails(isbn: String) async {
        isLoading = true
        errorMessage = nil
        
        // Check if this is coming from a scanner or manual input
        guard isbn.count >= 10 else {
            await MainActor.run {
                errorMessage = "Please use the barcode scanner to scan the ISBN"
                isLoading = false
            }
            return
        }
        
        do {
            let query = SupabaseManager.shared.client
                .from("Books")
                .select()
                .eq("isbn", value: isbn)
                .single()
            
            let book: Book = try await query.execute().value
            
            await MainActor.run {
                bookName = book.title
                authorName = book.author
                isLoading = false
            }
        } catch let error as PostgrestError where error.code == "PGRST116" {
            // PostgrestError with code PGRST116 means "json object requested, multiple (or no rows) returned"
            await MainActor.run {
                errorMessage = "This book does not exist in the library inventory. Add this to the inventory first."
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Please use the barcode scanner to scan the ISBN"
                isLoading = false
            }
        }
    }
    
    private func fetchMemberDetails(smartCardID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Try to parse the JSON data from the smart card
            if let jsonData = smartCardID.data(using: .utf8),
               let memberData = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let memberEmail = memberData["email"] as? String,
               let memberName = memberData["name"] as? String {
                
                await MainActor.run {
                    // Update the @State properties
                    self.smartCardID = memberEmail
                    self.memberName = memberName
                    isLoading = false
                }
            } else {
                // If JSON parsing fails, try fetching from Supabase
                let query = SupabaseManager.shared.client
                    .from("Members")
                    .select("email, name")
                    .eq("email", value: smartCardID)
                    .single()
                
                let response = try await query.execute()
                if let data = response.data as? [String: Any],
                   let email = data["email"] as? String,
                   let name = data["name"] as? String {
                    await MainActor.run {
                        self.smartCardID = email
                        self.memberName = name
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Member not found. Please register the member first."
                        isLoading = false
                    }
                }
            }
        } catch let error as PostgrestError where error.code == "PGRST116" {
            // This error occurs when no member is found
            await MainActor.run {
                errorMessage = "Member not found. Please register the member first."
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Please use the barcode scanner to scan the member card"
                isLoading = false
            }
        }
    }
    
    private func issueBook() {
        circulationManager.isLoading = true
        circulationManager.errorMessage = nil

        Task {
            do {
                print("Checking book limit for member: \(smartCardID)")
                
                // Get all currently issued books (not returned) for this member
                let memberBooksQuery = SupabaseManager.shared.client
                    .from("issuebooks")
                    .select()
                    .eq("member_email", value: smartCardID)
                    .is("actual_returned_date", value: nil) // Only count books that haven't been returned

                let memberBooksResponse = try await memberBooksQuery.execute()
                
                // Decode the response into [issueBooks]
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let currentlyIssuedBooks = try decoder.decode([issueBooks].self, from: memberBooksResponse.data)
                
                print("Currently issued books count: \(currentlyIssuedBooks.count)")

                // Prevent issuing if the user already has 5 books issued
                if currentlyIssuedBooks.count >= 5 {
                    print("Member has reached the 5-book limit")
                    await MainActor.run {
                        circulationManager.errorMessage = "Member has already issued 5 books. Please return some books before issuing more."
                        circulationManager.isLoading = false
                    }
                    return
                }

                print("Proceeding with book issue...")
                // Fetch the current book to get its available quantity
                let bookQuery = SupabaseManager.shared.client
                    .from("Books")
                    .select()
                    .eq("isbn", value: isbn)
                    .single()

                let currentBook: Book = try await bookQuery.execute().value

                guard currentBook.availableQuantity > 0 else {
                    await MainActor.run {
                        circulationManager.errorMessage = "Book is not available"
                        circulationManager.isLoading = false
                    }
                    return
                }

                let newIssue = issueBooks(
                    id: UUID(),
                    isbn: isbn,
                    memberEmail: smartCardID,
                    issueDate: Date(),
                    returnDate: returnDate,
                    actualReturnedDate: nil
                )

                // Insert new issue record
                let issueResponse = try await SupabaseManager.shared.client
                    .from("issuebooks")
                    .insert(newIssue)
                    .execute()

                // Decrease available quantity of the book
                let updateResponse = try await SupabaseManager.shared.client
                    .from("Books")
                    .update(["availableQuantity": currentBook.availableQuantity - 1])
                    .eq("isbn", value: isbn)
                    .execute()

                await MainActor.run {
                    circulationManager.isLoading = false
                    onIssue(newIssue)
                    showSuccessAlert = true
                }

            } catch {
                print("Book Issue Error: \(error.localizedDescription)")
                await MainActor.run {
                    circulationManager.errorMessage = "Failed to issue book: \(error.localizedDescription)"
                    circulationManager.isLoading = false
                }
            }
        }
    }
}



