import Foundation

struct Book: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var isbn: String
    var title: String
    var author: String
    var publisher: String
    var publishedDate: String?
    var description: String?
    var pageCount: Int?
    var categories: [String]?
    var genre: String? {
        return categories?[0]
    }
    var imageURL: String?
    var quantity: Int
    var availableQuantity: Int
    var addedDate: Date
    var lastModified: Date
    
    // Status tracking
    var isAvailable: Bool {
        return availableQuantity > 0
    }
    
    init(isbn: String, title: String, author: String, publisher: String, quantity: Int,
         publishedDate: String? = nil,
         description: String? = nil,
         pageCount: Int? = nil,
         categories: [String]? = nil,
         imageURL: String? = nil) {
        self.isbn = isbn
        self.title = title
        self.author = author
        self.publisher = publisher
        self.quantity = quantity
        self.availableQuantity = quantity
        self.publishedDate = publishedDate
        self.description = description
        self.pageCount = pageCount
        self.categories = categories
        self.imageURL = imageURL
        self.addedDate = Date()
        self.lastModified = Date()
    }
} 
