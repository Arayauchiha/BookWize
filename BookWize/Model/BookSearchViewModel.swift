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
    //let userPreferredGenres: [String]
    
    private var searchTextSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var books: [Book] = []
    @Published var forYouBooks: [Book] = []
    @Published var popularBooks: [Book] = []
    @Published var booksByAuthor: [String: [Book]] = [:]
    @Published var allPreferredBooks: [Book] = []
    @Published var memberSelectedGenres: [String] = []
    
    var booksByGenre: [String: [Book]] {
        Dictionary(grouping: books, by: { $0.genre ?? "" })
    }
    
    var availableGenres: [String] {
        Array(Set(books.map { $0.genre ?? "" })).sorted()
    }
    
    init(userPreferredGenres: [String] = []) {
        //self.userPreferredGenres = userPreferredGenres
        setupInitialData()
        Task {
            await fetchBooks()
            await fetchMemberGenres()
        }
    }
    
    private func fetchMemberGenres() async {
            do {
                // Get the current user's ID from Supabase auth
                guard let userEmail = UserDefaults.standard.string(forKey: "userEmail") else {
                    print("No email found in UserDefaults")
                    return
                }
                let user: User? = try await SupabaseManager.shared.client
                        .from("Members")
                        .select("*")
                        .eq("email", value: userEmail)
                        .single()
                        .execute()
                        .value
                    
                    DispatchQueue.main.async {
                        if let selectedGenres = user?.selectedGenres {
                            self.memberSelectedGenres = selectedGenres
                            self.setupInitialData() // Update the sections with the fetched genres
                        }
                    }
                }
            catch {
                print("Error fetching member genres: \(error)")
            }
        }
    
    private func fetchBooks() async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            let readableBooks: [Book]? = try await SupabaseManager.shared.client
                .from("Books")
                .select("*")
                .execute()
                .value
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                guard let readableBooks else {
                    print("No books found")
                    return
                }
                
                self.books = readableBooks
                self.setupInitialData()
                
                // Post notification that book data was updated
                NotificationCenter.default.post(name: Notification.Name("BookDataUpdated"), object: nil)
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                print("Error fetching books: \(error)")
                self.errorMessage = "Failed to load books. Please try again."
            }
        }
    }
    
    private func setupInitialData() {
        // Don't setup data if we don't have any books yet
        guard !books.isEmpty else {
            print("No books available yet to setup initial data")
            return
        }
        
        // Setup For You section with books from member's selected genres
        if memberSelectedGenres.isEmpty {
            forYouBooks = Array(books.shuffled().prefix(6))
            allPreferredBooks = books
        } else {
            // Filter books by member's selected genres
            let preferredBooks = books.filter { book in
                memberSelectedGenres.contains(book.genre ?? "")
            }
            allPreferredBooks = preferredBooks // Store all books from preferred genres
            forYouBooks = Array(preferredBooks.shuffled().prefix(6))
        }
        
        // Setup Popular Books with random books from all books
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
        
        print("Initial data setup complete with \(books.count) books and \(booksByGenre.count) genres")
        
        // Post notification that data was updated
        NotificationCenter.default.post(name: Notification.Name("BookDataUpdated"), object: nil)
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
    
    // Add a new public method for explicit data refreshing
    public func refreshData() async {
        await fetchBooks()
        await fetchMemberGenres()
    }
}
