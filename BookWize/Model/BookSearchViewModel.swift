//
//  BookSearchViewModel.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import Foundation
import Combine

class BookSearchViewModel: ObservableObject {
    @Published var searchResults: [Book] = []
    @Published var books: [Book] = [
        // Technology Books
        Book(id: UUID(), title: "The Design of Everyday Things", author: "Don Norman", isbn: "978-0465050659", genre: "Technology", publicationYear: 2013, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780465050659-L.jpg"),
        Book(id: UUID(), title: "The Innovators", author: "Walter Isaacson", isbn: "978-1476708690", genre: "Technology", publicationYear: 2014, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9781476708690-L.jpg"),
        Book(id: UUID(), title: "Clean Code", author: "Robert C. Martin", isbn: "978-0132350884", genre: "Technology", publicationYear: 2008, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780132350884-L.jpg"),
        
        // Fiction Books
        Book(id: UUID(), title: "Dune", author: "Frank Herbert", isbn: "978-0441172719", genre: "Fiction", publicationYear: 1965, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780441172719-L.jpg"),
        Book(id: UUID(), title: "1984", author: "George Orwell", isbn: "978-0451524935", genre: "Fiction", publicationYear: 1949, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780451524935-L.jpg"),
        Book(id: UUID(), title: "The Great Gatsby", author: "F. Scott Fitzgerald", isbn: "978-0743273565", genre: "Fiction", publicationYear: 1925, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780743273565-L.jpg"),
        Book(id: UUID(), title: "To Kill a Mockingbird", author: "Harper Lee", isbn: "978-0446310789", genre: "Fiction", publicationYear: 1960, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780446310789-L.jpg"),
        
        // Science Books
        Book(id: UUID(), title: "A Brief History of Time", author: "Stephen Hawking", isbn: "978-0553380163", genre: "Science", publicationYear: 1988, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780553380163-L.jpg"),
        Book(id: UUID(), title: "Cosmos", author: "Carl Sagan", isbn: "978-0345539435", genre: "Science", publicationYear: 1980, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780345539435-L.jpg"),
        Book(id: UUID(), title: "The Selfish Gene", author: "Richard Dawkins", isbn: "978-0198788607", genre: "Science", publicationYear: 1976, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780198788607-L.jpg"),
        
        // History Books
        Book(id: UUID(), title: "1776", author: "David McCullough", isbn: "978-0743226721", genre: "History", publicationYear: 2005, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780743226721-L.jpg"),
        Book(id: UUID(), title: "Sapiens", author: "Yuval Noah Harari", isbn: "978-0062316097", genre: "History", publicationYear: 2014, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780062316097-L.jpg"),
        Book(id: UUID(), title: "Guns, Germs, and Steel", author: "Jared Diamond", isbn: "978-0393354324", genre: "History", publicationYear: 1997, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780393354324-L.jpg"),
        
        // Business Books
        Book(id: UUID(), title: "Zero to One", author: "Peter Thiel", isbn: "978-0804139298", genre: "Business", publicationYear: 2014, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780804139298-L.jpg"),
        Book(id: UUID(), title: "Good to Great", author: "Jim Collins", isbn: "978-0066620992", genre: "Business", publicationYear: 2001, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780066620992-L.jpg"),
        Book(id: UUID(), title: "The Lean Startup", author: "Eric Ries", isbn: "978-0307887894", genre: "Business", publicationYear: 2011, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780307887894-L.jpg"),
        Book(id: UUID(), title: "Start with Why", author: "Simon Sinek", isbn: "978-1591846444", genre: "Business", publicationYear: 2009, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9781591846444-L.jpg")
    ]
    
    @Published var forYouBooks: [Book] = []
    @Published var popularBooks: [Book] = []
    @Published var booksByAuthor: [String: [Book]] = [:]
    
    var booksByGenre: [String: [Book]] {
        Dictionary(grouping: books, by: { $0.genre })
    }
    
    var availableGenres: [String] {
        Array(Set(books.map { $0.genre })).sorted()
    }
    
    init() {
        setupInitialData()
    }
    
    private func setupInitialData() {
        // Setup For You section with a mix of books
        forYouBooks = Array(books.shuffled().prefix(6))
        
        // Setup Popular Books
        popularBooks = Array(books.shuffled().prefix(8))
        
        // Setup Books by Author
        booksByAuthor = Dictionary(grouping: books, by: { $0.author })
        
        // Setup debounced search
        searchTextSubject
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.searchBooks()
            }
            .store(in: &cancellables)
        
        $searchText
            .sink { [weak self] text in
                self?.isLoading = !text.isEmpty
                self?.searchTextSubject.send(text)
            }
            .store(in: &cancellables)
    }
        @Published var searchText = ""
    private var searchTextSubject = PassthroughSubject<String, Never>()
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var selectedGenre: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, diskPath: nil)
        return URLSession(configuration: config)
    }()
    
    func searchBooks() {
        guard !searchText.isEmpty else { 
            searchResults = []
            isLoading = false
            errorMessage = nil
            return 
        }
        
        let searchQuery = searchText.lowercased()
        
        // First search local books
        let filteredBooks = books
            .map { book -> (Book, Int) in
                var score = 0
                let title = book.title.lowercased()
                let author = book.author.lowercased()
                let genre = book.genre.lowercased()
                
                // Exact title match gets highest priority
                if title == searchQuery {
                    score += 100
                }
                // Title starts with search query
                else if title.hasPrefix(searchQuery) {
                    score += 50
                }
                // Title contains search query
                else if title.contains(searchQuery) {
                    score += 25
                }
                
                // Author name matching
                if author.contains(searchQuery) {
                    score += 15
                }
                
                // Genre matching
                if genre.contains(searchQuery) {
                    score += 10
                }
                
                return (book, score)
            }
            .filter { $0.1 > 0 } // Only keep matches
            .sorted { $0.1 > $1.1 } // Sort by score descending
            .map { $0.0 } // Extract just the books
        
        // Update search results with local matches
        self.searchResults = Array(filteredBooks)
        
        // Construct the OpenLibrary search URL for additional results
        let baseURL = "https://openlibrary.org/search.json"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)?q=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        urlSession.dataTaskPublisher(for: url)
            .retry(3)
            .delay(for: .seconds(1), scheduler: DispatchQueue.global())
            .tryMap { output -> Data in
                guard let response = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                switch response.statusCode {
                case 200: return output.data
                case 401: throw URLError(.userAuthenticationRequired)
                case 429: throw URLError(.networkConnectionLost)
                case 503: throw URLError(.badServerResponse)
                default: throw URLError(.badServerResponse)
                }
            }
            .decode(type: OpenLibraryResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    if let decodingError = error as? DecodingError {
                        self?.errorMessage = "Failed to decode response: \(decodingError.localizedDescription)"
                    } else if let urlError = error as? URLError {
                        switch urlError.code {
                        case .notConnectedToInternet:
                            self?.errorMessage = "No internet connection. Please check your network settings."
                        case .timedOut:
                            self?.errorMessage = "Request timed out. Please try again."
                        case .userAuthenticationRequired:
                            self?.errorMessage = "API key authentication failed."
                        case .badServerResponse:
                            self?.errorMessage = "Service is temporarily unavailable. Please try again later."
                        default:
                            self?.errorMessage = "Network error: \(urlError.localizedDescription)"
                        }
                    } else {
                        self?.errorMessage = "Failed to fetch books: \(error.localizedDescription)"
                    }
                }
            }, receiveValue: { [weak self] (response: OpenLibraryResponse) in
                let apiBooks = response.allBooks.map { $0.book }
                DispatchQueue.main.async {
                    if !apiBooks.isEmpty {
                        // Append API results to existing local results
                        self?.searchResults.append(contentsOf: apiBooks)
                        self?.errorMessage = nil
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    func fetchBooksByGenre(_ genre: String) {
        isLoading = true
        errorMessage = nil
        
        let query = genre.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://openlibrary.org/subjects/\(query.lowercased()).json"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        urlSession.dataTaskPublisher(for: url)
            .retry(3)
            .delay(for: .seconds(1), scheduler: DispatchQueue.global())
            .tryMap { output -> Data in
                guard let response = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                switch response.statusCode {
                case 200: return output.data
                case 401: throw URLError(.userAuthenticationRequired)
                case 429: throw URLError(.networkConnectionLost)
                case 503: throw URLError(.badServerResponse)
                default: throw URLError(.badServerResponse)
                }
            }
            .decode(type: OpenLibraryResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    if let decodingError = error as? DecodingError {
                        print("Decoding Error: \(decodingError)")
                        self?.errorMessage = "Failed to decode response: \(decodingError.localizedDescription)"
                    } else if let urlError = error as? URLError {
                        switch urlError.code {
                        case .notConnectedToInternet:
                            self?.errorMessage = "No internet connection. Please check your network settings."
                        case .timedOut:
                            self?.errorMessage = "Request timed out. Please try again."
                        case .userAuthenticationRequired:
                            self?.errorMessage = "API key authentication failed."
                        case .badServerResponse:
                            self?.errorMessage = "Service is temporarily unavailable. Please try again later."
                        default:
                            self?.errorMessage = "Network error: \(urlError.localizedDescription)"
                        }
                    } else {
                        self?.errorMessage = "Failed to fetch books: \(error.localizedDescription)"
                    }
                }
            } receiveValue: { [weak self] response in
                let books = response.docs?.map { $0.book } ?? []
                DispatchQueue.main.async {
                    self?.books = books
                    if books.isEmpty {
                        self?.errorMessage = "No books found"
                    } else {
                        self?.errorMessage = nil
                    }
                }
            }
            .store(in: &cancellables)
    }
}