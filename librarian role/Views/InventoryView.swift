import SwiftUI
import UniformTypeIdentifiers
import Supabase

struct InventoryView: View {
    @StateObject private var inventoryManager = InventoryManager()
    @State private var searchText = ""
    @State private var showingAddBookSheet = false
    @State private var showingISBNScanner = false
    @State private var showingCSVUpload = false
    @State private var showingRequestBook = false
    @State private var selectedBook: Book?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedSegment = 0
    @State private var requests: [BookRequest] = []
    @State private var isFetchingRequests = false
    
    private let segments = ["Books", "Requests"]
    
    var filteredBooks: [Book] {
        inventoryManager.searchBooks(query: searchText)
    }
    
    var filteredRequests: [BookRequest] {
        if searchText.isEmpty {
            return requests
        } else {
            return requests.filter { request in
                request.author.lowercased().contains(searchText.lowercased()) ||
                request.title.lowercased().contains(searchText.lowercased()) ||
                request.reason.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("View", selection: $selectedSegment) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Text(segments[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedSegment == 0 {
                    List {
                        ForEach(filteredBooks) { book in
                            EnhancedBookRowView(book: book)
                                .onTapGesture {
                                    selectedBook = book
                                }
                        }
                    }
                } else {
                    List {
                        ForEach(filteredRequests) { request in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Author: \(request.author)")
                                    .font(.headline)
                                Text("Title: \(request.title)")
                                    .font(.subheadline)
                                Text("Quantity: \(request.quantity)")
                                    .font(.caption)
                                Text("Reason: \(request.reason)")
                                    .font(.caption)
                                Text("Status: \(request.Request_status.rawValue.capitalized)")
                                    .font(.caption)
                                    .foregroundColor(request.Request_status .background)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .overlay {
                        if isFetchingRequests {
                            ProgressView("Loading requests...")
                        }
                    }
                    .onAppear {
                        fetchRequests()
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search by title, author, or ISBN...")
            .navigationTitle("Library Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddBookSheet = true }) {
                            Label("Add Book Manually", systemImage: "plus.rectangle.fill.on.rectangle.fill")
                        }
                        
                        Button(action: { showingISBNScanner = true }) {
                            Label("Scan ISBN", systemImage: "barcode.viewfinder")
                        }
                        
                        Button(action: { showingCSVUpload = true }) {
                            Label("Import CSV", systemImage: "square.and.arrow.down.fill")
                        }
                        Button(action: { showingRequestBook = true }) {
                            Label("Request Book", systemImage: "square.and.arrow.down.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.title2)
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
            .sheet(isPresented: $showingRequestBook) {
                RequestBookView()
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
    
    private func fetchRequests() {
        isFetchingRequests = true
        Task {
            do {
                let client = SupabaseManager.shared.client
                let fetchedRequests: [BookRequest] = try await client
                    .from("BookRequest")
                    .select()
                    .execute()
                    .value
                
                await MainActor.run {
                    self.requests = fetchedRequests
                    isFetchingRequests = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to fetch requests: \(error.localizedDescription)"
                    isFetchingRequests = false
                    showError = true
                }
            }
        }
    }
    
    struct EnhancedBookRowView: View {
        let book: Book
        
        var body: some View {
            HStack(spacing: 16) {
                // Book Cover Image
                AsyncImage(url: URL(string: book.imageURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Image(systemName: "book.fill")
                            .foregroundStyle(.gray)
                    case .empty:
                        Image(systemName: "book.fill")
                            .foregroundStyle(.gray)
                    @unknown default:
                        Image(systemName: "book.fill")
                            .foregroundStyle(.gray)
                    }
                }
                .frame(width: 60, height: 90)
                .cornerRadius(8)
                .shadow(radius: 2)
                
                // Book Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        // Availability Badge
                        Text("\(book.availableQuantity) of \(book.quantity) available")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(book.isAvailable ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .foregroundStyle(book.isAvailable ? .green : .red)
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        // ISBN Badge
                        Text(book.isbn)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
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
    
    struct StatusItem: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
    }
    
//    struct AddBookView: View {
//        @Environment(\.dismiss) var dismiss
//        @ObservedObject var inventoryManager: InventoryManager
//        
//        @State private var isbn = ""
//        @State private var title = ""
//        @State private var author = ""
//        @State private var publisher = ""
//        @State private var quantity = 1
//        
//        var body: some View {
//            NavigationView {
//                Form {
//                    Section(header: Text("Book Details")) {
//                        TextField("ISBN", text: $isbn)
//                            .keyboardType(.numberPad)
//                        TextField("Title", text: $title)
//                        TextField("Author", text: $author)
//                        TextField("Publisher", text: $publisher)
//                        Stepper("Quantity: \(quantity)", value: $quantity, in: 1...100)
//                    }
//                }
//                .navigationTitle("Add New Book")
//                .navigationBarItems(
//                    leading: Button("Cancel") { dismiss() },
//                    trailing: Button("Save") {
//                        let newBook = Book(
//                            isbn: isbn,
//                            title: title,
//                            author: author,
//                            publisher: publisher,
//                            quantity: quantity
//                        )
//                        inventoryManager.addBook(newBook)
//                        dismiss()
//                    }
//                    .disabled(isbn.isEmpty || title.isEmpty || author.isEmpty || publisher.isEmpty)
//                )
//            }
//        }
//    }
    
    struct AddBookView: View {
        @Environment(\.dismiss) var dismiss
        @ObservedObject var inventoryManager: InventoryManager
        
        @State private var isbn = ""
        @State private var title = ""
        @State private var author = ""
        @State private var publisher = ""
        @State private var quantity = 1
        @State private var bookImage: UIImage?
        @State private var showImagePicker = false
        @State private var showCamera = false
        @State private var selectedSource: UIImagePickerController.SourceType = .photoLibrary
        @State private var isUploading = false // Add loading state
        
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
                    
                    Section(header: Text("Book Cover")) {
                        if let image = bookImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)
                        } else {
                            Text("No image selected")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Button("Choose from Gallery") {
                                selectedSource = .photoLibrary
                                showImagePicker = true
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Take Photo") {
                                selectedSource = .camera
                                showCamera = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .navigationTitle("Add New Book")
                .navigationBarItems(
                    leading: Button("Cancel") { dismiss() },
                    trailing:
                        Group {
                            if isUploading {
                                ProgressView()
                            } else {
                                Button("Save") {
                                    saveBook()
                                }
                                .disabled(isbn.isEmpty || title.isEmpty || author.isEmpty || publisher.isEmpty)
                            }
                        }
                )
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $bookImage, sourceType: selectedSource)
                }
                .fullScreenCover(isPresented: $showCamera) {
                    ImagePicker(image: $bookImage, sourceType: .camera)
                }
            }
        }
        
        private func saveBook() {
                isUploading = true
                
                let newBook = Book(
                    isbn: isbn,
                    title: title,
                    author: author,
                    publisher: publisher,
                    quantity: quantity
                )
                
                // Call the modified addBook method with the image
                inventoryManager.addBook(newBook, withImage: bookImage)
                
                // We'll dismiss the view right away, the upload will continue in the background
                isUploading = false
                dismiss()
            }
        }

    // MARK: - Image Picker
    struct ImagePicker: UIViewControllerRepresentable {
        @Binding var image: UIImage?
        var sourceType: UIImagePickerController.SourceType
        
        func makeCoordinator() -> Coordinator {
            return Coordinator(self)
        }
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = context.coordinator
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
        
        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            let parent: ImagePicker
            
            init(_ parent: ImagePicker) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
                if let selectedImage = info[.originalImage] as? UIImage {
                    parent.image = selectedImage
                }
                picker.dismiss(animated: true)
            }
            
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true)
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
                            quantity: quantity,
                            publishedDate: publishedDate.isEmpty ? nil : publishedDate,
                            description: description.isEmpty ? nil : description,
                            pageCount: Int(pageCount),
                            categories: genre.isEmpty ? nil : [genre],
                            imageURL: imageURL.isEmpty ? nil : imageURL
                        )
                        onSave(updatedBook)
                    }
                    .disabled(title.isEmpty || author.isEmpty || publisher.isEmpty)
                )
            }
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
                .frame(width: 100, alignment: .leading)
            
            if title == "Status" {
                let status = BookRequest.R_status(rawValue: value.lowercased()) ?? .pending
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.background)
                    .cornerRadius(6)
            } else {
                Text(value)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
    }
}
