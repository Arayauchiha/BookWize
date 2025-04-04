import Foundation
import SwiftUI

class InventoryManager: ObservableObject {
    @Published private(set) var books: [Book] = []
    @Published private(set) var bookImages: [String: UIImage] = [:] // Dictionary to store book images by ISBN
    private let saveKey = "library_inventory"
    private let imageDirectoryName = "BookImages"
    
    init() {
        loadBooks()
        loadImages()
        Task {
            do {
                try await refreshBooks()
            } catch {
                print("Error refreshing books during initialization: \(error)")
            }
        }
    }
    
    // Add this method to your InventoryManager class
    func uploadBookImage(_ image: UIImage, for isbn: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // Create a unique filename with ISBN and timestamp
        let fileName = "\(isbn)_\(Int(Date().timeIntervalSince1970)).jpg"
        
        // Upload to Supabase Storage
        _ = try await SupabaseManager.shared.client.storage
            .from("book-covers") // Replace with your actual bucket name
            .upload(
                fileName,
                data: imageData,
                options: .init(contentType: "image/jpeg")
            )
        
        // Generate public URL
        let publicURL = try await SupabaseManager.shared.client.storage
            .from("book-covers") // Replace with your actual bucket name
            .getPublicURL(path: fileName)
        
        // Convert URL to String
        return publicURL.absoluteString
    }

    // Then modify your addBook method to include imageURL
    func addBook(_ book: Book, withImage image: UIImage? = nil) {
        // Create a task to handle async operations
        Task {
            var updatedBook = book
            
            // If an image is provided, upload it and get URL
            if let image = image {
                do {
                    // Upload image and get URL
                    let imageURL = try await uploadBookImage(image, for: book.isbn)
                    updatedBook.imageURL = imageURL
                    
                    // Also save locally
                    saveBookImage(image, for: book.isbn)
                } catch {
                    print("Error uploading image: \(error)")
                }
            }
            
            // Now add the book with the imageURL (if available)
            if let index = books.firstIndex(where: { $0.isbn == updatedBook.isbn }) {
                // Update existing book locally
                books[index].quantity += updatedBook.quantity
                books[index].availableQuantity += updatedBook.quantity
                books[index].lastModified = Date()
                
                // Update imageURL if we have a new one
                if updatedBook.imageURL != nil {
                    books[index].imageURL = updatedBook.imageURL
                }
                
                // Update in Supabase
                do {
                    try await SupabaseManager.shared.client
                        .from("Books")
                        .update(books[index])
                        .eq("isbn", value: updatedBook.isbn)
                        .execute()
                    saveBooks()
                } catch {
                    print("Error updating book in Supabase: \(error)")
                }
            } else {
                // Add new book
                books.append(updatedBook)
                
                // Insert in Supabase
                do {
                    try await SupabaseManager.shared.client
                        .from("Books")
                        .insert(updatedBook)
                        .execute()
                    saveBooks()
                } catch {
                    print("Error inserting book in Supabase: \(error)")
                }
            }
        }
    }
    
    func removeBook(isbn: String) {
        books.removeAll { $0.isbn == isbn }
        
        // Also remove the image
        bookImages.removeValue(forKey: isbn)
        if let directory = getImagesDirectory() {
            let fileURL = directory.appendingPathComponent("\(isbn).jpg")
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        // Delete from Supabase
        Task {
            try! await SupabaseManager.shared.client
                .from("Books")
                .delete()
                .eq("isbn", value: isbn)
                .execute()
        }
        
        saveBooks()
    }
    
    func updateBook(_ book: Book) {
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            Task {
                do {
                    let _ = try await SupabaseManager.shared.client
                        .from("Books")
                        .update(book)
                        .eq("id", value: book.id)
                        .execute()
                    
                    await MainActor.run {
                        self.books[index] = book
                    }
                } catch {
                    print("Error updating book: \(error)")
                }
            }
        }
    }
    
    // MARK: - Image Management
    
    func saveBookImage(_ image: UIImage, for isbn: String) {
        // Store in memory
        bookImages[isbn] = image
        
        // Save to disk
        if let data = image.jpegData(compressionQuality: 0.8) {
            if let directory = getImagesDirectory() {
                let fileURL = directory.appendingPathComponent("\(isbn).jpg")
                try? data.write(to: fileURL)
            }
        }
    }
    
    func getBookImage(for isbn: String) -> UIImage? {
        // Check if image is in memory
        if let image = bookImages[isbn] {
            return image
        }
        
        // Try to load from disk
        if let directory = getImagesDirectory() {
            let fileURL = directory.appendingPathComponent("\(isbn).jpg")
            if let data = try? Data(contentsOf: fileURL),
               let image = UIImage(data: data) {
                // Cache in memory
                bookImages[isbn] = image
                return image
            }
        }
        
        return nil
    }
    
    func fetchBookImageFromAPI(isbn: String, completion: @escaping (UIImage?) -> Void) {
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil,
                  let self = self else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]],
                   !items.isEmpty,
                   let volumeInfo = items[0]["volumeInfo"] as? [String: Any],
                   let imageLinks = volumeInfo["imageLinks"] as? [String: Any],
                   let thumbnailURLString = imageLinks["thumbnail"] as? String {
                    
                    // Convert http to https if needed
                    let secureURLString = thumbnailURLString.replacingOccurrences(of: "http://", with: "https://")
                    
                    if let imageURL = URL(string: secureURLString) {
                        self.downloadImage(from: imageURL) { image in
                            if let image = image {
                                // Save the image
                                self.saveBookImage(image, for: isbn)
                            }
                            DispatchQueue.main.async {
                                completion(image)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    private func getImagesDirectory() -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let directoryURL = documentsDirectory.appendingPathComponent(imageDirectoryName)
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        
        return directoryURL
    }
    
    private func loadImages() {
        guard let directory = getImagesDirectory() else { return }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                let filename = fileURL.lastPathComponent
                if filename.hasSuffix(".jpg"), let isbn = filename.components(separatedBy: ".").first {
                    if let data = try? Data(contentsOf: fileURL),
                       let image = UIImage(data: data) {
                        bookImages[isbn] = image
                    }
                }
            }
        } catch {
            print("Error loading images: \(error)")
        }
    }
    
    // MARK: - CSV Import
    func importCSV(from url: URL) throws {
        let csvString = try String(contentsOf: url, encoding: .utf8)
        let rows = csvString.components(separatedBy: "\n")
        
        for row in rows.dropFirst() { // Skip header row
            let columns = row.components(separatedBy: ",")
            
            // Ensure there are enough columns before parsing
            guard columns.count >= 10 else {
                print("Skipping invalid row: \(row)")
                continue
            }
            
            let isbn = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let title = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let author = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let publisher = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
            let quantity = Int(columns[4].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 1
            let publishedDate = columns[5].trimmingCharacters(in: .whitespacesAndNewlines)
            let description = columns[6].trimmingCharacters(in: .whitespacesAndNewlines)
            let pageCount = Int(columns[7].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            let genre = columns[8].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Ensure Image URL is properly formatted
            let imageURL = columns[9].trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"")) // Remove extra quotes
            
            print("Parsed Image URL: '\(imageURL)'") // Debugging
            
            let book = Book(
                isbn: isbn,
                title: title,
                author: author,
                publisher: publisher,
                quantity: quantity,
                publishedDate: publishedDate.isEmpty ? nil : publishedDate,
                description: description.isEmpty ? nil : description,
                pageCount: pageCount > 0 ? pageCount : nil,
                categories: genre.isEmpty ? nil : [genre],
                imageURL: imageURL.isEmpty ? nil : imageURL
               // quantity: quantity // Avoid storing empty URLs
            )
            
            addBook(book)
        }
    }

    // MARK: - Persistence
    
    private func saveBooks() {
        if let encoded = try? JSONEncoder().encode(books) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadBooks() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Book].self, from: data) {
            books = decoded
        }
    }
    
    // MARK: - Book Search
    
    func findBook(by isbn: String) -> Book? {
        return books.first { $0.isbn == isbn }
    }
    
    func searchBooks(query: String) -> [Book] {
        guard !query.isEmpty else { return books }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.author.localizedCaseInsensitiveContains(query) ||
            $0.isbn.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getBook(_ id: UUID) -> Book? {
        books.first { $0.id == id }
    }
    
    func updateBookAvailability(_ id: UUID, issuedCopy: Bool) {
        if let index = books.firstIndex(where: { $0.id == id }) {
            var book = books[index]
            if issuedCopy {
                book.availableQuantity -= 1
            } else {
                book.availableQuantity += 1
            }
            books[index] = book
            saveBooks()
        }
    }
    
    // MARK: - Supabase Integration
    
    @MainActor
    public func refreshBooks() async throws {
        do {
            print("Fetching books from Supabase...")
            let fetchedBooks: [Book] = try await SupabaseManager.shared.client
                .from("Books")
                .select()
                .order("title")
                .execute()
                .value
            
            print("Successfully fetched \(fetchedBooks.count) books")
            self.books = fetchedBooks
        } catch {
            print("Error loading books: \(error)")
            throw error
        }
    }
}

#Preview {
    Text("InventoryManager")
        .environmentObject(InventoryManager())
}


