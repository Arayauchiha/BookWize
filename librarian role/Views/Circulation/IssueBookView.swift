//
//  IssueBookView.swift
//  BookWize
//
//  Created by Anshika on 26/03/25.
//

import SwiftUI

struct IssueBookView: View {
    @StateObject private var circulationManager = CirculationManager.shared
    @State private var searchText = ""
    @State private var showingIssueForm = false
    @State private var loans: [BookCirculation] = []

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if loans.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "No Books Issued",
                        message: "Start by issuing a new book"
                    )
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(loans) { loan in
                            LoanCard(loan: loan)
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
                loans.append(newLoan)
            }
        }
    }
}

struct LoanCard: View {
    let loan: BookCirculation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("ISBN: \(loan.isbn)", systemImage: "barcode")
                Spacer()
                Label("Member ID: \(loan.memberID.uuidString.prefix(8))", systemImage: "person.circle.fill")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("Issue Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(loan.startDate, style: .date)
                        .font(.subheadline)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Return Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let returnDate = loan.endDate {
                        Text(returnDate, style: .date)
                            .font(.subheadline)
                    } else {
                        Text("Not Returned").foregroundColor(.red)
                    }
                }
            }

            HStack {
                Text("Status: \(loan.status.rawValue.capitalized)")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(loan.status == .issued ? .blue : .green)
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
    @StateObject private var circulationManager = CirculationManager.shared
    @State private var isbn = ""
    @State private var smartCardID = ""
    @State private var bookName = ""
    @State private var authorName = ""
    @State private var showingScanner = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let onIssue: (BookCirculation) -> Void
    
    // Auto-filled issue & return dates
    private let issueDate = Date()
    private let returnDate = Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date()
    
    // Computed property to check if all fields are filled
    private var isFormValid: Bool {
        !isbn.isEmpty &&
        !bookName.isEmpty &&
        !authorName.isEmpty &&
        !smartCardID.isEmpty
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
                    Button(action: scanSmartCard) {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(.blue)
                    }
                }) {
                    TextField("Scan Smart Card ID", text: $smartCardID)
                        .keyboardType(.numberPad)
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
            .sheet(isPresented: $showingScanner) {
                ISBNScannerView { scannedISBN in
                    isbn = scannedISBN
                    Task {
                        await fetchBookDetails(isbn: scannedISBN)
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
            let book = try await circulationManager.fetchBookByISBN(isbn)
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

    func scanSmartCard() {
        print("Opening Smart Card Scanner...")
        // Simulate scanning by setting a dummy value
        smartCardID = "1234567890"
    }

    func issueBook() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let newLoan = BookCirculation(
                id: UUID(),
                isbn: isbn,
                memberID: UUID(uuidString: smartCardID) ?? UUID(),
                startDate: issueDate,
                endDate: returnDate,
                status: .issued
            )
            
            circulationManager.issueBook(newLoan) { success in
                DispatchQueue.main.async {
                    isLoading = false
                    if success {
                        onIssue(newLoan)
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        errorMessage = "Failed to issue book. Please try again."
                    }
                }
            }
        }
    }


}

