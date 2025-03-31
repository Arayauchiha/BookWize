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
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(circulationManager.loans) { loan in
                            LoanCard(issuedBooks: loan)
                        }
                    }
                    .padding()
                }
            }
            
            VStack {
                Button {
                    showingIssueForm = true
                } label: {
                    Label("Issue New Book", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .shadow(radius: 2)
        }
        .searchable(text: $searchText, prompt: "Search transactions...")
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

struct LoanCard: View {
    let issuedBooks: issueBooks
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("ISBN: \(issuedBooks.isbn)", systemImage: "barcode")
                Spacer()
                Label("Member Email: \(issuedBooks.memberEmail)", systemImage: "person.circle.fill")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

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
                        Text("Not Returned").foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
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
                        Text("Return Date")
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
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
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
                        errorMessage = "Member details not found."
                        isLoading = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch member details."
                isLoading = false
            }
        }
    }
    
    //    func issueBook() {
    //        circulationManager.isLoading = true
    //        circulationManager.errorMessage = nil
    //
    //        Task {
    //            let newIssue = issueBooks(
    //                id: UUID(),
    //                isbn: isbn,
    //                memberEmail: smartCardID,  // Ensure this is the correct email
    //                issueDate: issueDate,
    //                returnDate: returnDate
    //            )
    //
    //            do {
    //                let response = try await SupabaseManager.shared.client
    //                    .from("issuebooks")
    //                    .insert(newIssue)
    //                    .execute()
    //
    //                // Print the response for debugging
    //                print("Insertion Response: \(response)")
    //
    //                DispatchQueue.main.async {
    //                    circulationManager.isLoading = false
    //                    onIssue(newIssue)
    //                    presentationMode.wrappedValue.dismiss()
    //                }
    //            } catch {
    //                // Print the detailed error for debugging
    //                print("Book Issue Error: \(error.localizedDescription)")
    //
    //                DispatchQueue.main.async {
    //                    circulationManager.errorMessage = "Failed to issue book: \(error.localizedDescription)"
    //                    circulationManager.isLoading = false
    //                }
    //            }
    //        }
    //    }
  
    func issueBook() {
        circulationManager.isLoading = true
        circulationManager.errorMessage = nil

        Task {
            let newIssue = issueBooks(
                id: UUID(),
                isbn: isbn,
                memberEmail: smartCardID,
                issueDate: issueDate,
                returnDate: returnDate
            )

            do {
                let response = try await SupabaseManager.shared.client
                    .from("issuebooks")
                    .insert(newIssue)
                    .execute()

                print("Insertion Response: \(response)")

                DispatchQueue.main.async {
                    circulationManager.isLoading = false
                    onIssue(newIssue)
                    showSuccessAlert = true // Show success alert
                }
            } catch {
                print("Book Issue Error: \(error.localizedDescription)")

                DispatchQueue.main.async {
                    circulationManager.errorMessage = "Failed to issue book: \(error.localizedDescription)"
                    circulationManager.isLoading = false
                }
            }
        }
    }
} 

