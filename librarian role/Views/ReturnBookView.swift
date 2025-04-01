//
//  ReturnBookView.swift
//  BookWize
//
//  Created by Anshika on 26/03/25.
//

import SwiftUI
import Supabase

struct ReturnBookView: View {
    @StateObject private var circulationManager = IssuedBookManager.shared
    @State private var searchText = ""
    @State private var showingReturnForm = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if circulationManager.isLoading {
                    ProgressView()
                        .padding()
                } else if circulationManager.loans.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "No Books to Return",
                        message: "There are no books currently issued"
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
                    showingReturnForm = true
                } label: {
                    Label("Return Book", systemImage: "arrow.left.circle.fill")
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
        .searchable(text: $searchText, prompt: "Search transactions...")
        .sheet(isPresented: $showingReturnForm) {
            ReturnBookFormView { returnedBook in
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
    @State private var bookCoverURL: URL?
    @State private var isLoadingCover = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
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
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .task {
            await fetchBookCover()
        }
    }
    
    private func fetchBookCover() async {
        let coverURL = "https://covers.openlibrary.org/b/isbn/\(issuedBooks.isbn)-M.jpg"
        bookCoverURL = URL(string: coverURL)
    }
}

struct ReturnBookFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var circulationManager = IssuedBookManager.shared
    @State private var isbn = ""
    @State private var smartCardID = ""
    @State private var memberName = ""
    @State private var bookName = ""
    @State private var showingScanner = false
    @State private var showingSmartCardScanner = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedCondition = BookCondition.good
    @State private var fineAmount = ""
    @State private var duesFine: Double = 0.0
    
    let onReturn: (issueBooks) -> Void
    
    private func isValidFineAmount(_ input: String) -> Bool {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
        let characterSet = CharacterSet(charactersIn: input)
        return allowedCharacters.isSuperset(of: characterSet)
    }
    
    var isFormValid: Bool {
        let basicFieldsValid = !isbn.isEmpty || !smartCardID.isEmpty || !memberName.isEmpty || !bookName.isEmpty
        
        if selectedCondition == .damaged {
            return basicFieldsValid && !fineAmount.isEmpty &&
                   isValidFineAmount(fineAmount) &&
                   (Double(fineAmount) ?? 0) > 0
        }
        
        return basicFieldsValid
    }
    
    var body: some View {
        NavigationView {
            Form {
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
                    TextField("Scan or Enter ISBN", text: $isbn)
                        .keyboardType(.numberPad)
                        .onChange(of: isbn) { newValue in
                            if !newValue.isEmpty {
                                Task {
                                    await fetchBookDetails(isbn: newValue)
                                }
                            }
                        }
                    
                    TextField("Enter Book Name", text: $bookName)
                        .onChange(of: bookName) { newValue in
                            if !newValue.isEmpty {
                                Task {
                                    await fetchBookByName(name: newValue)
                                }
                            }
                        }
                }
                
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
                    TextField("Scan or Enter Member ID", text: $smartCardID)
                        .keyboardType(.default)
                        .onChange(of: smartCardID) { newValue in
                            if !newValue.isEmpty {
                                Task {
                                    await fetchMemberDetails(smartCardID: newValue)
                                }
                            }
                        }
                    
                    TextField("Enter Member Name", text: $memberName)
                        .onChange(of: memberName) { newValue in
                            if !newValue.isEmpty {
                                Task {
                                    await fetchMemberByName(name: newValue)
                                }
                            }
                        }
                }
                
                Section(header: Text("Book Condition")) {
                    Picker("Select Condition", selection: $selectedCondition) {
                        ForEach(BookCondition.allCases, id: \.self) { condition in
                            Text(condition.rawValue)
                                .tag(condition)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Fine Details")) {
                    HStack {
                        Text("Dues Fine")
                        Spacer()
                        Text("₹\(String(format: "%.2f", duesFine))")
                            .foregroundColor(.red)
                    }
                    
                    if selectedCondition == .damaged {
                        TextField("Enter Damage Fine Amount", text: $fineAmount)
                            .keyboardType(.decimalPad)
                            .onChange(of: fineAmount) { newValue in
                                if !isValidFineAmount(newValue) {
                                    fineAmount = String(newValue.filter { "0123456789.".contains($0) })
                                }
                                
                                if newValue.filter({ $0 == "." }).count > 1 {
                                    fineAmount = String(newValue.prefix { $0 != "." }) + "."
                                }
                                
                                if let dotIndex = newValue.firstIndex(of: ".") {
                                    let decimals = newValue[newValue.index(after: dotIndex)...]
                                    if decimals.count > 2 {
                                        fineAmount = String(newValue.prefix(through: dotIndex)) + String(decimals.prefix(2))
                                    }
                                }
                            }
                            .textContentType(.none)
                            .autocapitalization(.none)
                    }
                    
                    HStack {
                        Text("Total Fine")
                        Spacer()
                        Text("₹\(String(format: "%.2f", duesFine + (Double(fineAmount) ?? 0)))")
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    }
                }
                
                Button(action: returnBook) {
                    Label("Return Book", systemImage: "arrow.left.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!isFormValid || isLoading)
                .padding()
            }
            .navigationTitle("Return Book")
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
            .sheet(isPresented: $showingSmartCardScanner) {
                SmartCardScannerView { scannedCode in
                    smartCardID = scannedCode
                    Task {
                        await fetchMemberDetails(smartCardID: scannedCode)
                    }
                }
            }
            .onChange(of: selectedCondition) { newCondition in
                if newCondition == .good {
                    fineAmount = ""
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
            .task {
                if !isbn.isEmpty && !smartCardID.isEmpty {
                    await calculateDuesFine()
                }
            }
        }
    }
    
    private func calculateDuesFine() async {
        duesFine = 0.0
    }
    
    private func returnBook() {
        circulationManager.isLoading = true
        circulationManager.errorMessage = nil
        
        Task {
            do {
                let bookQuery = SupabaseManager.shared.client
                    .from("Books")
                    .select()
                    .eq("isbn", value: isbn)
                    .single()
                
                let currentBook: Book = try await bookQuery.execute().value
                
                let updateData = ReturnBookUpdate(
                    returnDate: Date(),
                    bookCondition: selectedCondition.rawValue,
                    fineAmount: selectedCondition == .damaged ? Double(fineAmount) : nil,
                    duesFine: duesFine
                )
                
                let updateResponse = try await SupabaseManager.shared.client
                    .from("issuebooks")
                    .update(updateData)
                    .eq("isbn", value: isbn)
                    .eq("memberEmail", value: smartCardID)
                    .execute()
                
                let bookUpdateResponse = try await SupabaseManager.shared.client
                    .from("Books")
                    .update(["availableQuantity": currentBook.availableQuantity + 1])
                    .eq("isbn", value: isbn)
                    .execute()
                
                DispatchQueue.main.async {
                    circulationManager.isLoading = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Book Return Error: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    circulationManager.errorMessage = "Failed to return book: \(error.localizedDescription)"
                    circulationManager.isLoading = false
                }
            }
        }
    }
    
    private func fetchBookByName(name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let query = SupabaseManager.shared.client
                .from("Books")
                .select()
                .ilike("title", value: "%\(name)%")
                .single()
            
            let book: Book = try await query.execute().value
            
            await MainActor.run {
                isbn = book.isbn
                bookName = book.title
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func fetchMemberByName(name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let query = SupabaseManager.shared.client
                .from("Members")
                .select()
                .ilike("name", value: "%\(name)%")
                .single()
            
            let response = try await query.execute()
            if let data = response.data as? [String: Any],
               let email = data["email"] as? String,
               let name = data["name"] as? String {
                await MainActor.run {
                    smartCardID = email
                    memberName = name
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch member details."
                isLoading = false
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
            if let jsonData = smartCardID.data(using: .utf8),
               let memberData = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let memberEmail = memberData["email"] as? String,
               let memberName = memberData["name"] as? String {
                
                await MainActor.run {
                    self.smartCardID = memberEmail
                    self.memberName = memberName
                    isLoading = false
                }
            } else {
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
}

enum BookCondition: String, CaseIterable, Codable {
    case good = "Good"
    case damaged = "Damaged"
}

struct ReturnBookUpdate: Encodable {
    let returnDate: Date
    let bookCondition: String
    let fineAmount: Double?
    let duesFine: Double
}

#Preview {
    ReturnBookView()
}
