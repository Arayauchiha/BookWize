//
//  SearchBrowseView.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import SwiftUI

enum SearchCategory: String, CaseIterable {
    case topResults = "Top Results"
    case available = "Available"
    case authors = "By Author"
    case genres = "Genres"
}

struct SearchBrowseView: View {
    @StateObject private var viewModel: BookSearchViewModel
    @State private var selectedFilter: String? = nil
    @State private var selectedGenreFromCard: String? = nil
    @State private var showingSuggestions = false
    @State private var selectedAuthor: String? = nil
    @State private var initialBooksByGenre: [String: [Book]] = [:]
    @FocusState private var isSearchFocused: Bool
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedCategory: SearchCategory = .topResults
    let userPreferredGenres: [String]
    
    // Add these states for book detail presentation
    @State private var selectedBook: Book?
    @State private var showingBookDetail = false
    @State private var selectedSectionBooks: [Book] = []
    @State private var selectedIndex: Int = 0
    @State private var cardOffset: CGFloat = 0
    
    let genres = [
        "Fiction", "Non-Fiction", "Science", "History", "Technology", 
        "Business", "Mystery", "Romance", "Biography", "Poetry",
        "Children's Books", "Self Help", "Travel", "Art", "Cooking"
    ]
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    init(userPreferredGenres: [String] = []) {
        self.userPreferredGenres = userPreferredGenres
        self._viewModel = StateObject(wrappedValue: BookSearchViewModel(userPreferredGenres: userPreferredGenres))
        
        // Configure the navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        // Apply the appearance to all navigation bars
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !viewModel.searchText.isEmpty {
                        // Categories Picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(SearchCategory.allCases, id: \.self) { category in
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
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
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
                    } else {
                        BookSectionsView(
                            forYouBooks: viewModel.forYouBooks,
                            popularBooks: viewModel.popularBooks,
                            booksByGenre: initialBooksByGenre,
                            selectedGenreFromCard: $selectedGenreFromCard,
                            selectedFilter: $selectedFilter,
                            userPreferredGenres: userPreferredGenres,
                            viewModel: viewModel
                        )
                    }
                }
                .onAppear {
                    initialBooksByGenre = viewModel.booksByGenre
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
            .sheet(isPresented: $showingBookDetail) {
                if let book = selectedBook {
                    NavigationView {
                        GeometryReader { geometry in
                            ZStack {
                                // Current book (always show)
                                BookDetailCard(book: book, isPresented: $showingBookDetail)
                                    .offset(x: cardOffset)
                                
                                // Only show previous/next for multiple books
                                if selectedSectionBooks.count > 1 {
                                    // Previous book (preloaded)
                                    if selectedIndex > 0 {
                                        BookDetailCard(
                                            book: selectedSectionBooks[selectedIndex - 1],
                                            isPresented: $showingBookDetail
                                        )
                                        .offset(x: -geometry.size.width + cardOffset)
                                    }
                                    
                                    // Next book (preloaded)
                                    if selectedIndex < selectedSectionBooks.count - 1 {
                                        BookDetailCard(
                                            book: selectedSectionBooks[selectedIndex + 1],
                                            isPresented: $showingBookDetail
                                        )
                                        .offset(x: geometry.size.width + cardOffset)
                                    }
                                }
                            }
                        }
                        .navigationBarHidden(true)
                    }
                    .gesture(
                        // Only enable swiping gesture for multiple books
                        selectedSectionBooks.count > 1 ?
                        DragGesture()
                            .onChanged { value in
                                withAnimation(.interactiveSpring()) {
                                    cardOffset = value.translation.width
                                }
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                if value.translation.width > threshold && selectedIndex > 0 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedIndex -= 1
                                    }
                                } else if value.translation.width < -threshold && selectedIndex < selectedSectionBooks.count - 1 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedIndex += 1
                                    }
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    cardOffset = 0
                                }
                            } : nil
                    )
                    .interactiveDismissDisabled()
                }
            }
            .onChange(of: selectedIndex) { oldValue, newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedBook = selectedSectionBooks[newValue]
                    cardOffset = 0
                }
            }
        }
        .tabItem {
            Image(systemName: "safari")
            Text("Explore")
        }
    }
    
    private var searchResultsGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.searchResults) { book in
                BookCardView(book: book) {
                    selectedBook = book
                    selectedSectionBooks = viewModel.searchResults
                    if let index = selectedSectionBooks.firstIndex(where: { $0.id == book.id }) {
                        selectedIndex = index
                    }
                    showingBookDetail = true
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var availableBooksGrid: some View {
        let availableBooks = viewModel.searchResults.filter { $0.isAvailable }
        
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(availableBooks) { book in
                BookCardView(book: book) {
                    selectedBook = book
                    selectedSectionBooks = availableBooks
                    if let index = selectedSectionBooks.firstIndex(where: { $0.id == book.id }) {
                        selectedIndex = index
                    }
                    showingBookDetail = true
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var booksByAuthorGrid: some View {
        let groupedBooks = Dictionary(grouping: viewModel.searchResults) { $0.author }
        
        return ForEach(groupedBooks.keys.sorted(), id: \.self) { author in
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
                                selectedSectionBooks = groupedBooks[author] ?? []
                                if let index = selectedSectionBooks.firstIndex(where: { $0.id == book.id }) {
                                    selectedIndex = index
                                }
                                showingBookDetail = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var genresGrid: some View {
        let uniqueGenres = Array(Set(viewModel.searchResults.compactMap { $0.genre })).sorted()
        
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(uniqueGenres, id: \.self) { genre in
                NavigationLink {
                    GenreBooksView(
                        genre: genre,
                        books: viewModel.searchResults.filter { $0.genre == genre }
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
