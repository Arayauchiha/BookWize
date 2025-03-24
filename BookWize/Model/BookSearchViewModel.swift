import Foundation
import Combine

class BookSearchViewModel: ObservableObject {
    @Published var searchResults: [Book] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var selectedGenre: String? = nil
    let userPreferredGenres: [String]
    
    private var searchTextSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    @Published var books: [Book] = []
    @Published var forYouBooks: [Book] = []
    @Published var popularBooks: [Book] = []
    @Published var booksByAuthor: [String: [Book]] = [:]
    @Published var allPreferredBooks: [Book] = []
    
    var booksByGenre: [String: [Book]] {
        Dictionary(grouping: books, by: { $0.genre ?? "" })
    }
    
    var availableGenres: [String] {
        Array(Set(books.map { $0.genre ?? "" })).sorted()
    }
    
    init(userPreferredGenres: [String] = []) {
        self.userPreferredGenres = userPreferredGenres
        setupInitialData()
        Task {
            let readableBooks: [Book]? = try! await SupabaseManager.shared.client
                .from("Books")
                .select("*")
                .execute()
                .value
            DispatchQueue.main.async {
                guard let readableBooks else {
                    return
                }
            
                self.books = readableBooks
            }
        }
    }
    
    private func setupInitialData() {
        if userPreferredGenres.isEmpty {
            forYouBooks = Array(books.shuffled().prefix(6))
            allPreferredBooks = books
        } else {
            let preferredBooks = books.filter { book in
                userPreferredGenres.contains(book.genre ?? "")
            }
            allPreferredBooks = preferredBooks
            forYouBooks = Array(preferredBooks.shuffled().prefix(6))
        }
        popularBooks = Array(books.shuffled().prefix(8))

        booksByAuthor = Dictionary(grouping: books, by: { $0.author })
        
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
    
    private func searchBooks() {
        guard !searchText.isEmpty else { 
            searchResults = []
            isLoading = false
            errorMessage = nil
            return 
        }
        
        let searchQuery = searchText.lowercased()

        let filteredBooks = books
            .map { book -> (Book, Int) in
                var score = 0
                let title = book.title.lowercased()
                let author = book.author.lowercased()
                let genre = book.genre?.lowercased()

                if title == searchQuery {
                    score += 100
                }
                else if title.hasPrefix(searchQuery) {
                    score += 50
                }
                else if title.contains(searchQuery) {
                    score += 25
                }

                if author.contains(searchQuery) {
                    score += 15
                }

                if let genre {
                    if genre.contains(searchQuery) {
                        score += 10
                    }
                }
                
                return (book, score)
            }
            .filter { $0.1 > 0 } // Only keep results with a score greater than 0
            .sorted { $0.1 > $1.1 } // Sort by score in descending order
            .map { $0.0 } // Extract just the books
        
        searchResults = filteredBooks
        isLoading = false
        errorMessage = nil
    }
}
