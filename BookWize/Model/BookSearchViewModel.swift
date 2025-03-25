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
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var selectedGenre: String? = nil
    let userPreferredGenres: [String]
    
    private var searchTextSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    
//    @Published var books: [UserBook] = [
//        // Technology Books
//        UserBook(id: UUID(), title: "The Design of Everyday Things", author: "Don Norman", isbn: "978-0465050659", genre: "Technology", publicationYear: 2013, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780465050659-L.jpg"),
//        UserBook(id: UUID(), title: "The Innovators", author: "Walter Isaacson", isbn: "978-1476708690", genre: "Technology", publicationYear: 2014, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9781476708690-L.jpg"),
//        UserBook(id: UUID(), title: "Clean Code", author: "Robert C. Martin", isbn: "978-0132350884", genre: "Technology", publicationYear: 2008, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780132350884-L.jpg"),
//        
//        // Fiction Books
//        UserBook(id: UUID(), title: "Dune", author: "Frank Herbert", isbn: "978-0441172719", genre: "Fiction", publicationYear: 1965, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780441172719-L.jpg"),
//        UserBook(id: UUID(), title: "1984", author: "George Orwell", isbn: "978-0451524935", genre: "Fiction", publicationYear: 1949, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780451524935-L.jpg"),
//        UserBook(id: UUID(), title: "The Great Gatsby", author: "F. Scott Fitzgerald", isbn: "978-0743273565", genre: "Fiction", publicationYear: 1925, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780743273565-L.jpg"),
//        UserBook(id: UUID(), title: "To Kill a Mockingbird", author: "Harper Lee", isbn: "978-0446310789", genre: "Fiction", publicationYear: 1960, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780446310789-L.jpg"),
//        
//        // Science Books
//        UserBook(id: UUID(), title: "A Brief History of Time", author: "Stephen Hawking", isbn: "978-0553380163", genre: "Science", publicationYear: 1988, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780553380163-L.jpg"),
//        UserBook(id: UUID(), title: "Cosmos", author: "Carl Sagan", isbn: "978-0345539435", genre: "Science", publicationYear: 1980, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780345539435-L.jpg"),
//        UserBook(id: UUID(), title: "The Selfish Gene", author: "Richard Dawkins", isbn: "978-0198788607", genre: "Science", publicationYear: 1976, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780198788607-L.jpg"),
//        
//        // History Books
//        UserBook(id: UUID(), title: "1776", author: "David McCullough", isbn: "978-0743226721", genre: "History", publicationYear: 2005, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780743226721-L.jpg"),
//        UserBook(id: UUID(), title: "Sapiens", author: "Yuval Noah Harari", isbn: "978-0062316097", genre: "History", publicationYear: 2014, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780062316097-L.jpg"),
//        UserBook(id: UUID(), title: "Guns, Germs, and Steel", author: "Jared Diamond", isbn: "978-0393354324", genre: "History", publicationYear: 1997, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780393354324-L.jpg"),
//        
//        // Business Books
//        UserBook(id: UUID(), title: "Zero to One", author: "Peter Thiel", isbn: "978-0804139298", genre: "Business", publicationYear: 2014, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780804139298-L.jpg"),
//        UserBook(id: UUID(), title: "Good to Great", author: "Jim Collins", isbn: "978-0066620992", genre: "Business", publicationYear: 2001, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780066620992-L.jpg"),
//        UserBook(id: UUID(), title: "The Lean Startup", author: "Eric Ries", isbn: "978-0307887894", genre: "Business", publicationYear: 2011, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780307887894-L.jpg"),
//        UserBook(id: UUID(), title: "Start with Why", author: "Simon Sinek", isbn: "978-1591846444", genre: "Business", publicationYear: 2009, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9781591846444-L.jpg"),
//        
//        // Mystery Books
//        UserBook(id: UUID(), title: "The Silent Patient", author: "Alex Michaelides", isbn: "978-1250301697", genre: "Mystery", publicationYear: 2019, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9781250301697-L.jpg"),
//        UserBook(id: UUID(), title: "Gone Girl", author: "Gillian Flynn", isbn: "978-0307588371", genre: "Mystery", publicationYear: 2012, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780307588371-L.jpg"),
//        UserBook(id: UUID(), title: "The Da Vinci Code", author: "Dan Brown", isbn: "978-0307474278", genre: "Mystery", publicationYear: 2003, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780307474278-L.jpg"),
//        
//        // Romance Books
//        UserBook(id: UUID(), title: "Pride and Prejudice", author: "Jane Austen", isbn: "978-0141439518", genre: "Romance", publicationYear: 1813, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780141439518-L.jpg"),
//        UserBook(id: UUID(), title: "The Notebook", author: "Nicholas Sparks", isbn: "978-0553816716", genre: "Romance", publicationYear: 1996, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780553816716-L.jpg"),
//        UserBook(id: UUID(), title: "Me Before You", author: "Jojo Moyes", isbn: "978-0143124542", genre: "Romance", publicationYear: 2012, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780143124542-L.jpg"),
//        
//        // Biography Books
//        UserBook(id: UUID(), title: "Steve Jobs", author: "Walter Isaacson", isbn: "978-1451648539", genre: "Biography", publicationYear: 2011, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9781451648539-L.jpg"),
//        UserBook(id: UUID(), title: "Becoming", author: "Michelle Obama", isbn: "978-1524763138", genre: "Biography", publicationYear: 2018, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9781524763138-L.jpg"),
//        UserBook(id: UUID(), title: "Long Walk to Freedom", author: "Nelson Mandela", isbn: "978-0316548182", genre: "Biography", publicationYear: 1994, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780316548182-L.jpg"),
//        
//        // Poetry Books
//        UserBook(id: UUID(), title: "Milk and Honey", author: "Rupi Kaur", isbn: "978-1449474256", genre: "Poetry", publicationYear: 2015, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9781449474256-L.jpg"),
//        UserBook(id: UUID(), title: "The Sun and Her Flowers", author: "Rupi Kaur", isbn: "978-1449486792", genre: "Poetry", publicationYear: 2017, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9781449486792-L.jpg"),
//        UserBook(id: UUID(), title: "Selected Poems", author: "Emily Dickinson", isbn: "978-0486264660", genre: "Poetry", publicationYear: 1890, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780486264660-L.jpg"),
//        
//        // Self Help Books
//        UserBook(id: UUID(), title: "Atomic Habits", author: "James Clear", isbn: "978-0735211292", genre: "Self Help", publicationYear: 2018, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9780735211292-L.jpg"),
//        UserBook(id: UUID(), title: "The 7 Habits of Highly Effective People", author: "Stephen Covey", isbn: "978-1982137274", genre: "Self Help", publicationYear: 1989, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9781982137274-L.jpg"),
//        UserBook(id: UUID(), title: "Think and Grow Rich", author: "Napoleon Hill", isbn: "978-1585424337", genre: "Self Help", publicationYear: 1937, availability: .available, reservedBy: nil, imageURL: "https://covers.openlibrary.org/b/isbn/9781585424337-L.jpg")
//    ]
    
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
        // Setup For You section with books from user's preferred genres
        if userPreferredGenres.isEmpty {
            forYouBooks = Array(books.shuffled().prefix(6))
            allPreferredBooks = books
        } else {
            // Filter books by user's preferred genres
            let preferredBooks = books.filter { book in
                userPreferredGenres.contains(book.genre ?? "")
            }
            allPreferredBooks = preferredBooks // Store all books from preferred genres
            forYouBooks = Array(preferredBooks.shuffled().prefix(6))
        }
        
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
    
    private func searchBooks() {
        guard !searchText.isEmpty else { 
            searchResults = []
            isLoading = false
            errorMessage = nil
            return 
        }
        
        let searchQuery = searchText.lowercased()
        
        // Search local books
        let filteredBooks = books
            .map { book -> (Book, Int) in
                var score = 0
                let title = book.title.lowercased()
                let author = book.author.lowercased()
                let genre = book.genre?.lowercased()
                
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
