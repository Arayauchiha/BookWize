//
//  ReturnBookView.swift
//  BookWize
//
//  Created by Anshika on 26/03/25.
//

import SwiftUI
import Supabase

struct ReturnissueBooks: Identifiable, Codable {
    let id: UUID
    let isbn: String
    let member_email: String
    let issue_date: Date
    let return_date: Date?
    let actual_returned_date: Date?
}

struct ReturnBookView: View {
    @StateObject private var circulationManager = IssuedBookManager.shared
    @State private var searchText = ""
    @State private var showingReturnForm = false
    @State private var returnBookData: [ReturnissueBooks] = []
    @State private var returnBookWithFilter: [ReturnissueBooks] = []
    
    var filteredReturnBooks: [ReturnissueBooks] {
        if searchText.isEmpty {
            return returnBookWithFilter
        }
        return returnBookWithFilter.filter { book in
            book.isbn.localizedCaseInsensitiveContains(searchText) ||
            book.member_email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func fetchReturn() async {
        do {
            // Get email from UserDefaults
            guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail") else {
                print("No email found in UserDefaults")
                return
            }
            
            print("Fetching member with email: \(userEmail)")
            
            let response: [ReturnissueBooks] = try await SupabaseManager.shared.client
                .from("issuebooks")
                .select("*")
                .execute()
                .value
            
            DispatchQueue.main.async {
                self.returnBookData = response
                self.returnBookWithFilter = returnBookData.filter({$0.actual_returned_date != nil })
                print("Successfully fetched returbbooks: \(returnBookWithFilter)")
            }
        } catch {
            print("Error fetching member: \(error)")
        }
    }

    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if circulationManager.isLoading {
                    ProgressView()
                        .padding()
                } else if returnBookWithFilter.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "No Books Returned",
                        message: "There are no returned books to display"
                    )
                } else if !searchText.isEmpty && filteredReturnBooks.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Results Found",
                        message: "Try searching with different keywords"
                    )
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredReturnBooks) { book in
                            ReturnedBookCard(book: book)
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
        .searchable(text: $searchText, prompt: "Search Returned Books")
        .sheet(isPresented: $showingReturnForm) {
            ReturnBookFormView { returnedBook in
                Task {
                    await circulationManager.fetchIssuedBooks()
                }
            }
        }
        .task {
            await circulationManager.fetchIssuedBooks()
            await fetchReturn()
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

struct ReturnedBookCard: View {
    let book: ReturnissueBooks
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
                        Label("ISBN: \(book.isbn)", systemImage: "barcode")
                            .font(.subheadline)
                    }
                    
                    Text("Member Email: \(book.member_email)")
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
                    Text(book.issue_date, style: .date)
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Return Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let returnDate = book.actual_returned_date {
                        Text(returnDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.green)
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
        let coverURL = "https://covers.openlibrary.org/b/isbn/\(book.isbn)-M.jpg"
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
    @State private var perDayFine: Double = 0.0
    @State private var isDuesFineConfirmed = false
    
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
                   (Double(fineAmount) ?? 0) > 0 &&
                   isDuesFineConfirmed
        }
        
        return basicFieldsValid && isDuesFineConfirmed
    }
    
    private func calculateDuesFine() async {
        do {
            // 1. Get per day fine from FineAndMembershipSet
            let fineSettings: [FineSettings] = try await SupabaseManager.shared.client
                .from("FineAndMembershipSet")
                .select("PerDayFine")
                .execute()
                .value
            
            guard let perDayFine = fineSettings.first?.perDayFine else {
                print("No fine settings found")
                return
            }
            
            self.perDayFine = perDayFine
            
            // 2. Get the issue book details
            let issueBook: [IssueBook] = try await SupabaseManager.shared.client
                .from("issuebooks")
                .select("id, member_email, return_date")
                .eq("isbn", value: isbn)
                .eq("member_email", value: smartCardID)
                .execute()
                .value
            
            guard let book = issueBook.first else {
                print("No issue book found")
                return
            }
            
            guard let returnDateString = book.returnDate else {
                print("No return date found")
                return
            }
            
            // 3. Parse the return date
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            let dateFormatter1 = DateFormatter()
            dateFormatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            let dateFormatter2 = DateFormatter()
            dateFormatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            
            let dateFormatter3 = DateFormatter()
            dateFormatter3.dateFormat = "yyyy-MM-dd"
            
            var returnDate: Date?
            if let date = isoFormatter.date(from: returnDateString) {
                returnDate = date
            } else if let date = dateFormatter1.date(from: returnDateString) {
                returnDate = date
            } else if let date = dateFormatter2.date(from: returnDateString) {
                returnDate = date
            } else if let date = dateFormatter3.date(from: returnDateString) {
                returnDate = date
            }
            
            guard let returnDate = returnDate else {
                print("Failed to parse return date")
                return
            }
            
            // 4. Calculate fine for this specific book
            let currentDate = Date()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: returnDate, to: currentDate)
            let days = components.day ?? 0
            
            if days > 0 {
                let fine = Double(days) * perDayFine
                await MainActor.run {
                    self.duesFine = fine
                }
                print("Calculated fine for this book: \(fine) for \(days) days")
            } else {
                await MainActor.run {
                    self.duesFine = 0.0
                }
            }
            
        } catch {
            print("Error calculating fine:", error)
        }
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
                    
                    Toggle("Mark as Paid", isOn: $isDuesFineConfirmed)
                        .tint(.blue)
                    
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
                        if !smartCardID.isEmpty {
                            await calculateDuesFine()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSmartCardScanner) {
                SmartCardScannerView { scannedCode in
                    smartCardID = scannedCode
                    Task {
                        await fetchMemberDetails(smartCardID: scannedCode)
                        if !isbn.isEmpty {
                            await calculateDuesFine()
                        }
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
        }
    }
    
    private func returnBook() {
        circulationManager.isLoading = true
        circulationManager.errorMessage = nil
        
        Task {
            do {
                // 1. Get the book details
                let bookQuery = SupabaseManager.shared.client
                    .from("Books")
                    .select()
                    .eq("isbn", value: isbn)
                    .single()
                
                let currentBook: Book = try await bookQuery.execute().value
                
                // 2. Get current member's fine
                let memberQuery = SupabaseManager.shared.client
                    .from("Members")
                    .select("fine")
                    .eq("email", value: smartCardID)
                    .single()
                
                let memberResponse = try await memberQuery.execute()
                print("Member response data: \(memberResponse.data)")
                
                // Try to get the fine value in different ways
                var currentFine: Double = 0.0
                if let data = memberResponse.data as? [String: Any] {
                    if let fine = data["fine"] as? Double {
                        currentFine = fine
                    } else if let fine = data["fine"] as? Int {
                        currentFine = Double(fine)
                    } else if let fine = data["fine"] as? String {
                        currentFine = Double(fine) ?? 0.0
                    }
                }
                
                print("Current member fine before update: \(currentFine)")
                
                // 3. Update the issuebook record with return details and fines
                let updateData = ReturnBookUpdate(
                    actual_returned_date: Date(),
                    bookCondition: selectedCondition.rawValue,
                    fineAmount: selectedCondition == .damaged ? Double(fineAmount) : nil,
                    duesFine: duesFine
                )
                
                let updateResponse = try await SupabaseManager.shared.client
                    .from("issuebooks")
                    .update(updateData)
                    .eq("isbn", value: isbn)
                    .eq("member_email", value: smartCardID)
                    .execute()
                
                // 4. Update the book's available quantity
                let bookUpdateResponse = try await SupabaseManager.shared.client
                    .from("Books")
                    .update(["availableQuantity": currentBook.availableQuantity + 1])
                    .eq("isbn", value: isbn)
                    .execute()
                
                // Refresh the issued books list
                await circulationManager.fetchIssuedBooks()
                
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
    let actual_returned_date: Date
    let bookCondition: String
    let fineAmount: Double?
    let duesFine: Double
}

struct FineSettings: Codable {
    let perDayFine: Double
    
    enum CodingKeys: String, CodingKey {
        case perDayFine = "PerDayFine"
    }
}

struct IssueBook: Codable {
    let id: UUID
    let memberEmail: String
    let returnDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case memberEmail = "member_email"
        case returnDate = "return_date"
    }
}

#Preview {
    ReturnBookView()
}
