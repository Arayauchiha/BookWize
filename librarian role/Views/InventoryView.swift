import SwiftUI
import UniformTypeIdentifiers

struct InventoryView: View {
    @StateObject private var inventoryManager = InventoryManager()
    @State private var searchText = ""
    @State private var showingAddBookSheet = false
    @State private var showingISBNScanner = false
    @State private var showingCSVUpload = false
    @State private var selectedBook: Book?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var filteredBooks: [Book] {
        inventoryManager.searchBooks(query: searchText)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredBooks) { book in
                    BookRowView(book: book)
                        .onTapGesture {
                            selectedBook = book
                        }
                }
            }
            .searchable(text: $searchText, prompt: "Search books...")
            .navigationTitle("Library Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddBookSheet = true }) {
                            Label("Add Book Manually", systemImage: "plus")
                        }
                        
                        Button(action: { showingISBNScanner = true }) {
                            Label("Scan ISBN", systemImage: "barcode.viewfinder")
                        }
                        
                        Button(action: { showingCSVUpload = true }) {
                            Label("Import CSV", systemImage: "doc.text.below.ecg")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddBookSheet) {
                AddBookView(inventoryManager: inventoryManager)
            }
            .sheet(isPresented: $showingISBNScanner) {
                ISBNScannerView { scannedISBN in
                    handleScannedISBN(scannedISBN)
                }
            }
            .sheet(isPresented: $showingCSVUpload) {
                CSVUploadView(viewModel: inventoryManager)
            }
            .sheet(item: $selectedBook) { book in
                BookDetailView(book: book, inventoryManager: inventoryManager)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .overlay {
                if isLoading {
                    ProgressView("Fetching book details...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 10)
                }
            }
        }
    }
    
    private func handleScannedISBN(_ isbn: String) {
        isLoading = true
        Task {
            do {
                let book = try await BookService.shared.fetchBookDetails(isbn: isbn)
                await MainActor.run {
                    inventoryManager.addBook(book)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error fetching book details: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

struct BookRowView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(book.title)
                .font(.headline)
            Text("by \(book.author)")
                .font(.subheadline)
            HStack {
                Text("ISBN: \(book.isbn)")
                Spacer()
                Text("Available: \(book.availableQuantity)/\(book.quantity)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddBookView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var inventoryManager: InventoryManager
    
    @State private var isbn = ""
    @State private var title = ""
    @State private var author = ""
    @State private var publisher = ""
    @State private var quantity = 1
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Details")) {
                    TextField("ISBN", text: $isbn)
                        .keyboardType(.numberPad)
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Publisher", text: $publisher)
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...100)
                }
            }
            .navigationTitle("Add New Book")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    let newBook = Book(
                        isbn: isbn,
                        title: title,
                        author: author,
                        publisher: publisher,
                        quantity: quantity
                    )
                    inventoryManager.addBook(newBook)
                    dismiss()
                }
                .disabled(isbn.isEmpty || title.isEmpty || author.isEmpty || publisher.isEmpty)
            )
        }
    }
}

struct BookDetailView: View {
    let book: Book
    @ObservedObject var inventoryManager: InventoryManager
    @Environment(\.dismiss) var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var editedBook: Book?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Book Information")) {
                    DetailRow(title: "Title", value: book.title)
                    DetailRow(title: "Author", value: book.author)
                    DetailRow(title: "ISBN", value: book.isbn)
                    DetailRow(title: "Publisher", value: book.publisher)
                    if let publishedDate = book.publishedDate {
                        DetailRow(title: "Published Date", value: publishedDate)
                    }
                }
                
                Section(header: Text("Inventory Status")) {
                    DetailRow(title: "Total Quantity", value: "\(book.quantity)")
                    DetailRow(title: "Available", value: "\(book.availableQuantity)")
                    DetailRow(title: "Status", value: book.isAvailable ? "Available" : "Not Available")
                }
                
                if let description = book.description {
                    Section(header: Text("Description")) {
                        Text(description)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Book", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Book Details")
            .navigationBarItems(
                trailing: HStack {
                    Button("Edit") {
                        editedBook = book
                        showingEditSheet = true
                    }
                    Button("Done") { dismiss() }
                }
            )
            .sheet(isPresented: $showingEditSheet) {
                if let book = editedBook {
                    EditBookView(book: book, inventoryManager: inventoryManager) { updatedBook in
                        inventoryManager.updateBook(updatedBook)
                        dismiss()
                    }
                }
            }
            .alert("Delete Book", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    inventoryManager.removeBook(isbn: book.isbn)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this book? This action cannot be undone.")
            }
        }
    }
}

struct EditBookView: View {
    let book: Book
    @ObservedObject var inventoryManager: InventoryManager
    let onSave: (Book) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String
    @State private var author: String
    @State private var publisher: String
    @State private var quantity: Int
    @State private var publishedDate: String
    @State private var description: String
    @State private var pageCount: String
    @State private var genre: String
    @State private var imageURL: String
    
    init(book: Book, inventoryManager: InventoryManager, onSave: @escaping (Book) -> Void) {
        self.book = book
        self.inventoryManager = inventoryManager
        self.onSave = onSave
        
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author)
        _publisher = State(initialValue: book.publisher)
        _quantity = State(initialValue: book.quantity)
        _publishedDate = State(initialValue: book.publishedDate ?? "")
        _description = State(initialValue: book.description ?? "")
        _pageCount = State(initialValue: book.pageCount.map(String.init) ?? "")
        _genre = State(initialValue: book.genre ?? "")
        _imageURL = State(initialValue: book.imageURL ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Details")) {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Publisher", text: $publisher)
                    TextField("ISBN", text: .constant(book.isbn))
                        .disabled(true)
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...100)
                }
                
                Section(header: Text("Additional Information")) {
                    TextField("Published Date", text: $publishedDate)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Page Count", text: $pageCount)
                        .keyboardType(.numberPad)
                    TextField("Genre", text: $genre)
                    TextField("Image URL", text: $imageURL)
                }
            }
            .navigationTitle("Edit Book")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    let updatedBook = Book(
                        isbn: book.isbn,
                        title: title,
                        author: author,
                        publisher: publisher,
                        publishedDate: publishedDate.isEmpty ? nil : publishedDate, description: description.isEmpty ? nil : description, pageCount: Int(pageCount), categories: genre.isEmpty ? nil : [genre], imageURL: imageURL.isEmpty ? nil : imageURL, quantity: quantity
                    )
                    onSave(updatedBook)
                }
                .disabled(title.isEmpty || author.isEmpty || publisher.isEmpty)
            )
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}
#Preview {
    InventoryView()
}











