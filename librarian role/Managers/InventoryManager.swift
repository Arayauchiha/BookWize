//import Foundation
//import SwiftUI
//
//class InventoryManager: ObservableObject {
//    @Published private(set) var books: [Book] = []
//    private let saveKey = "library_inventory"
//    
//    init() {
//        loadBooks()
//    }
//    
//    // MARK: - Book Management
//    
//    func addBook(_ book: Book) {
//        if let index = books.firstIndex(where: { $0.isbn == book.isbn }) {
//            // Update existing book
//            books[index].quantity += book.quantity
//            books[index].availableQuantity += book.quantity
//            books[index].lastModified = Date()
//        } else {
//            // Add new book
//            books.append(book)
//        }
//        saveBooks()
//    }
//    
//    func removeBook(isbn: String) {
//        books.removeAll { $0.isbn == isbn }
//        saveBooks()
//    }
//    
//    // MARK: - CSV Import
//    
//    func importCSV(from url: URL) throws {
//        let csvString = try String(contentsOf: url, encoding: .utf8)
//        let rows = csvString.components(separatedBy: "\n")
//        
//        // Assuming CSV format: ISBN,Title,Author,Publisher,Quantity
//        for row in rows.dropFirst() { // Skip header row
//            let columns = row.components(separatedBy: ",")
//            guard columns.count >= 5 else { continue }
//            
//            let book = Book(
//                isbn: columns[0].trimmingCharacters(in: .whitespacesAndNewlines),
//                title: columns[1].trimmingCharacters(in: .whitespacesAndNewlines),
//                author: columns[2].trimmingCharacters(in: .whitespacesAndNewlines),
//                publisher: columns[3].trimmingCharacters(in: .whitespacesAndNewlines),
//                quantity: Int(columns[4].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 1
//            )
//            addBook(book)
//        }
//    }
//    
//    // MARK: - Persistence
//    
//    private func saveBooks() {
//        if let encoded = try? JSONEncoder().encode(books) {
//            UserDefaults.standard.set(encoded, forKey: saveKey)
//        }
//    }
//    
//    private func loadBooks() {
//        if let data = UserDefaults.standard.data(forKey: saveKey),
//           let decoded = try? JSONDecoder().decode([Book].self, from: data) {
//            books = decoded
//        }
//    }
//    
//    // MARK: - Book Search
//    
//    func findBook(by isbn: String) -> Book? {
//        return books.first { $0.isbn == isbn }
//    }
//    
//    func searchBooks(query: String) -> [Book] {
//        guard !query.isEmpty else { return books }
//        return books.filter {
//            $0.title.localizedCaseInsensitiveContains(query) ||
//            $0.author.localizedCaseInsensitiveContains(query) ||
//            $0.isbn.localizedCaseInsensitiveContains(query)
//        }
//    }
//    
//    func getBook(_ id: UUID) -> Book? {
//        books.first { $0.id == id }
//    }
//    
//    func updateBookAvailability(_ id: UUID, issuedCopy: Bool) {
//        if let index = books.firstIndex(where: { $0.id == id }) {
//            var book = books[index]
//            if issuedCopy {
//                book.availableQuantity -= 1
//            } else {
//                book.availableQuantity += 1
//            }
//            books[index] = book
//            saveBooks()
//        }
//    }
//}

















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
    }
    
    // MARK: - Book Management
    
    func addBook(_ book: Book) {
        if let index = books.firstIndex(where: { $0.isbn == book.isbn }) {
            // Update existing book
            books[index].quantity += book.quantity
            books[index].availableQuantity += book.quantity
            books[index].lastModified = Date()
        } else {
            // Add new book
            books.append(book)
        }
        saveBooks()
    }
    
    func removeBook(isbn: String) {
        books.removeAll { $0.isbn == isbn }
        
        // Also remove the image
        bookImages.removeValue(forKey: isbn)
        if let directory = getImagesDirectory() {
            let fileURL = directory.appendingPathComponent("\(isbn).jpg")
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        saveBooks()
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
        
        // Assuming CSV format: ISBN,Title,Author,Publisher,Quantity
        for row in rows.dropFirst() { // Skip header row
            let columns = row.components(separatedBy: ",")
            guard columns.count >= 5 else { continue }
            
            let book = Book(
                isbn: columns[0].trimmingCharacters(in: .whitespacesAndNewlines),
                title: columns[1].trimmingCharacters(in: .whitespacesAndNewlines),
                author: columns[2].trimmingCharacters(in: .whitespacesAndNewlines),
                publisher: columns[3].trimmingCharacters(in: .whitespacesAndNewlines),
                quantity: Int(columns[4].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 1
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
}
