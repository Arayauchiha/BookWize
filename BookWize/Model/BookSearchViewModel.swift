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
    @Published var recentlyAddedBooks: [Book] = []
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
                guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail") else {
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
            print("Fetching books from Supabase...")
            
            // Add a cache-busting query parameter
            let timestamp = Int(Date().timeIntervalSince1970)
            let readableBooks: [Book]? = try await SupabaseManager.shared.client
                .from("Books")
                .select("*")
                .order("id")
                .execute()
                .value
            
            print("Fetched \(readableBooks?.count ?? 0) books from Supabase")
            
            await MainActor.run {
                self.isLoading = false
                
                guard let readableBooks else {
                    print("No books found")
                    return
                }
                
                // Clear and update with fresh data
                self.books = readableBooks
                print("Updated books array with \(self.books.count) books")
                
                // Reset and regenerate all derived collections
                self.setupInitialData()
                
                // Post notification that book data was updated
                NotificationCenter.default.post(name: Notification.Name("BookDataUpdated"), object: nil)
            }
        } catch {
            await MainActor.run {
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
        
        // Setup Recently Added Books with books added in the last 7 days
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        recentlyAddedBooks = books.filter { book in
            return book.addedDate >= sevenDaysAgo
        }.sorted(by: { $0.addedDate > $1.addedDate }) // Sort by newest first
        
        print("Found \(recentlyAddedBooks.count) books added in the last 7 days")
        
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
        print("BookSearchViewModel: Starting data refresh from Supabase...")
        
        // Set loading state without clearing the UI
        await MainActor.run {
            self.isLoading = true
        }
        
        // Fetch fresh data from Supabase
        do {
            print("Refreshing books data from Supabase...")
            
            // Add cache-busting timestamp to force fresh data
            let timestamp = Int(Date().timeIntervalSince1970)
            let readableBooks: [Book]? = try await SupabaseManager.shared.client
                .from("Books")
                .select("*")
                .order("id")
                .execute()
                .value
            
            print("Refreshed \(readableBooks?.count ?? 0) books from Supabase")
            
            // Fetch member genres concurrently
            let genresTask = Task {
                await fetchMemberGenres()
            }
            
            // Update the UI on the main thread
            await MainActor.run {
                guard let readableBooks else {
                    print("No books found during refresh")
                    self.isLoading = false
                    return
                }
                
                // Update the main books collection
                self.books = readableBooks
                
                // Regenerate all sections by calling setupInitialData
                self.setupInitialData()
                
                self.isLoading = false
                
                // Post notification that data was updated
                NotificationCenter.default.post(name: Notification.Name("BookDataUpdated"), object: nil)
            }
            
            // Wait for the genres task to complete
            _ = await genresTask.value
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                print("Error refreshing books: \(error)")
                self.errorMessage = "Failed to refresh books. Please try again."
            }
        }
    }
}
