//
//  SearchBrowseView.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//
import SwiftUI
import Supabase
import PostgREST

enum SearchCategory: String, CaseIterable {
    case topResults = "Top Results"
    case available = "Available"
    case authors = "By Author"
    case genres = "Genres"
}

struct SearchBrowseView: View {
    @StateObject private var viewModel: BookSearchViewModel
    let supabase: SupabaseClient
    @State private var isSearchFocused = false
    @State private var showingSuggestions = false
    @State private var selectedBook: Book?
    @State private var showingBookDetail = false
    @State private var selectedGenreFromCard: String?
    @State private var selectedFilter: String?
    @State private var selectedCategory: SearchCategory = .topResults
    @State private var forceUpdateKey = UUID()
    @State private var initialBooksByGenre: [String: [Book]] = [:]
    
    // Define column layout for grids
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    
    init(userPreferredGenres: [String] = [], supabase: SupabaseClient) {
        self.supabase = supabase
        self._viewModel = StateObject(wrappedValue: BookSearchViewModel(userPreferredGenres: userPreferredGenres))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !viewModel.searchText.isEmpty {
                        // Categories Picker - simplified 
                        categoriesPicker
                        
                        // Search results content - simplified
                        searchResultsContent
                            .id(forceUpdateKey)
                    } else {
                        // Main browse content when no search
                        BookSectionsView(
                            forYouBooks: viewModel.forYouBooks,
                            recentlyAddedBooks: viewModel.recentlyAddedBooks,
                            booksByGenre: initialBooksByGenre,
                            supabase: supabase,
                            selectedGenreFromCard: $selectedGenreFromCard,
                            selectedFilter: $selectedFilter,
                            viewModel: viewModel
                        )
                    }
                }
                .onAppear {
                    initialBooksByGenre = viewModel.booksByGenre
                    
                    if initialBooksByGenre.isEmpty {
                        Task {
                            await viewModel.refreshData()
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("BookDataUpdated"))) { _ in
                    initialBooksByGenre = viewModel.booksByGenre
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RefreshBookStatus"))) { _ in
                    // Refresh book status in UI when notifications are received
                    forceUpdateKey = UUID()
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name.reservationStatusChanged)) { _ in
                    // When reservation status changes, force refresh
                    print("SearchBrowseView received reservation change notification, refreshing UI")
                    forceUpdateKey = UUID()
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Books, Authors, or Genres")
            .onChange(of: viewModel.searchText) { oldValue, newValue in
                if !newValue.isEmpty {
                    showingSuggestions = isSearchFocused
                }
            }
            .onSubmit(of: .search) {
                isSearchFocused = false
                showingSuggestions = false
            }
            .sheet(item: $selectedBook) { book in
                NavigationView {
                    BookDetailCard(book: book, supabase: supabase, isPresented: $showingBookDetail)
                        .navigationBarHidden(true)
                }
                .interactiveDismissDisabled(false)
            }
        }
        .tabItem {
            Image(systemName: "safari")
            Text("Explore")
        }
    }
    
    // MARK: - Extracted Views
        private var categoriesPicker: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(SearchCategory.allCases, id: \.self) { category in
                        categoryButton(for: category)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
        
        private func categoryButton(for category: SearchCategory) -> some View {
            Button(action: {
                selectedCategory = category
            }) {
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(selectedCategory == category ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedCategory == category ? Color.blue : Color.clear)
                    .cornerRadius(20)
            }
        }
        
        private var searchResultsContent: some View {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No results found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("We couldn't find any books matching '\(viewModel.searchText)'")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    .frame(maxWidth: .infinity)
                } else {
                    searchCategoryContent
                }
            }
        }
        
        private var searchCategoryContent: some View {
            Group {
                switch selectedCategory {
                case .topResults:
                    searchResultsGrid
                case .available:
                    availableBooksGrid
                case .authors:
                    booksByAuthorGrid
                case .genres:
                    genresGrid
                }
            }
        }
        
        private var searchResultsGrid: some View {
            if viewModel.searchResults.isEmpty {
                return AnyView(
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No results found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("We couldn't find any books matching '\(viewModel.searchText)'")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity)
                )
            }
            
            return AnyView(
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.searchResults) { book in
                        BookCardView(book: book) {
                            selectedBook = book
                            showingBookDetail = true
                        }
                    }
                }
                .padding(.horizontal)
            )
        }
        
        private var availableBooksGrid: some View {
            let availableBooks = viewModel.searchResults.filter { $0.isAvailable }
            
            if availableBooks.isEmpty {
                return AnyView(
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No available books found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("We couldn't find any available books matching '\(viewModel.searchText)'")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity)
                )
            }
            
            return AnyView(
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(availableBooks) { book in
                        BookCardView(book: book) {
                            selectedBook = book
                            showingBookDetail = true
                        }
                    }
                }
                .padding(.horizontal)
            )
        }
        
        private var booksByAuthorGrid: some View {
            let groupedBooks = Dictionary(grouping: viewModel.searchResults) { $0.author }
            
            if groupedBooks.isEmpty {
                return AnyView(
                    VStack(spacing: 16) {
                        Image(systemName: "person")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No authors found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("We couldn't find any authors matching '\(viewModel.searchText)'")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity)
                )
            }
            
            return AnyView(
                ForEach(groupedBooks.keys.sorted(), id: \.self) { author in
                    VStack(alignment: .leading) {
                        Text(author)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(groupedBooks[author] ?? []) { book in
                                    BookCardView(book: book) {
                                        selectedBook = book
                                        showingBookDetail = true
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
            )
        }
        
        private var genresGrid: some View {
            let uniqueGenres = Array(Set(viewModel.searchResults.compactMap { $0.genre })).sorted()
            
            if uniqueGenres.isEmpty {
                return AnyView(
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No genres found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("We couldn't find any genres matching '\(viewModel.searchText)'")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity)
                )
            }
            
            return AnyView(
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(uniqueGenres, id: \.self) { genre in
                        NavigationLink {
                            GenreBooksView(
                                genre: genre,
                                books: viewModel.searchResults.filter { $0.genre == genre }, supabase: supabase
                            )
                        } label: {
                            let filteredBooks = viewModel.searchResults.filter { $0.genre == genre }
                            if let firstBook = filteredBooks.first {
                                VStack(alignment: .center, spacing: 8) {
                                    if let imageURL = firstBook.imageURL,
                                       let url = URL(string: imageURL) {
                                        CachedAsyncImage(url: url)
                                            .frame(width: 180, height: 240)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .shadow(radius: 4)
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 180, height: 240)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    
                                    // Genre name text below the card
                                    VStack(spacing: 2) {
                                        Text(genre)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        
                                        Text("\(filteredBooks.count) books")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 4)
                                }
                                .frame(width: 180)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            )
        }
    }

    struct GenreCard: View {
        let genre: String
        let books: [Book]
        
        var body: some View {
            VStack(spacing: 6) {
                if let firstBook = books.first,
                   let imageURL = firstBook.imageURL,
                   let url = URL(string: imageURL) {
                    CachedAsyncImage(url: url)
                        .frame(width: 120, height: 120)
                        .clipped()
                        .cornerRadius(10)
                }
                
                Text(genre)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .padding(.top, 4)
                
                Text("\(books.count) books")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
