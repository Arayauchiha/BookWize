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
   // var location: String?
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


//import Foundation
//
//struct Book: Identifiable, Codable, Sendable {
//    var id: UUID = UUID()
//    var isbn: String
//    var title: String
//    var author: String
//    var publisher: String
//    var publishedDate: String?
//    var description: String?
//    var pageCount: Int?
//    var categories: [String]?
//    var genre: String? {
//        return categories?[0]
//    }
//    var imageURL: String?
//    var quantity: Int
//    var location: String?
//    var addedDate: Date
//    var lastModified: Date
//    
//   
//   // var loanTracking: [BookCirculation] = []
//    
//    var availableQuantity: Int 
//    
////    var availableQuantity: Int {
////        let activeLoans = loanTracking.filter { $0.status == .issued || $0.status == .renewed }.count
////        return max(0, quantity - activeLoans)
////    }
//    
//    // Computed property: Fetch loaned books and calculate available quantity
////        var availableQuantity: Int {
////            // Get active loans from Supabase (you will implement this function)
////            let activeLoans = fetchActiveLoansCount(for: self.id)
////            return max(0, quantity - activeLoans)
////        }
//    
//    var isAvailable: Bool {
//        return availableQuantity > 0
//    }
//    
//    init(isbn: String, title: String, author: String, publisher: String, quantity: Int,
//         publishedDate: String? = nil,
//         description: String? = nil,
//         pageCount: Int? = nil,
//         categories: [String]? = nil,
//         imageURL: String? = nil) {
//        self.isbn = isbn
//        self.title = title
//        self.author = author
//        self.publisher = publisher
//        self.quantity = quantity
//        self.publishedDate = publishedDate
//        self.description = description
//        self.pageCount = pageCount
//        self.categories = categories
//        self.imageURL = imageURL
//        self.addedDate = Date()
//        self.lastModified = Date()
//        self.loanTracking = []
//        self.availableQuantity = quantity
//    }
//}
