import Foundation

class BookService {
    static let shared = BookService()
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    
    private init() {}
    
    func fetchBookDetails(isbn: String) async throws -> Book {
        let query = "isbn:\(isbn)"
        guard let url = URL(string: "\(baseURL)?q=\(query)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        
        guard let volumeInfo = response.items?.first?.volumeInfo else {
            throw BookError.bookNotFound
        }
        
        return Book(
            isbn: isbn,
            title: volumeInfo.title,
            author: volumeInfo.authors?.joined(separator: ", ") ?? "Unknown Author",
            publisher: volumeInfo.publisher ?? "Unknown Publisher",
            quantity: 1, publishedDate: volumeInfo.publishedDate,
            description: volumeInfo.description,
            pageCount: volumeInfo.pageCount,
            categories: volumeInfo.categories,
            imageURL: volumeInfo.imageLinks?.thumbnail
        )
    }
}

// MARK: - Response Models
struct GoogleBooksResponse: Codable {
    let items: [Volume]?
}

struct Volume: Codable {
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let imageLinks: ImageLinks?
}

struct ImageLinks: Codable {
    let thumbnail: String?
}

// MARK: - Errors
enum BookError: Error {
    case bookNotFound
    case invalidISBN
    case networkError
} 
