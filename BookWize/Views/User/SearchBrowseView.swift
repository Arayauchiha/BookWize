//
//  SearchBrowseView.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import SwiftUI

struct SearchBrowseView: View {
    @StateObject private var viewModel = BookSearchViewModel()
    @State private var selectedFilter: String? = nil
    @State private var selectedGenreFromCard: String? = nil
    @State private var showingSuggestions = false
    @State private var selectedAuthor: String? = nil
    @State private var initialBooksByGenre: [String: [UserBook]] = [:]
    @FocusState private var isSearchFocused: Bool
    @State private var scrollOffset: CGFloat = 0
    let userPreferredGenres: [String]
    
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
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if viewModel.searchResults.isEmpty {
                            Text("No books found")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(Array(viewModel.searchResults.prefix(8))) { book in
                                    NavigationLink {
                                        UserBookDetailView(book: book)
                                            .onAppear {
                                                isSearchFocused = false
                                                showingSuggestions = false
                                            }
                                    } label: {
                                        BookCard(book: book)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 280)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        GenreCategoriesView(
                            genres: genres,
                            selectedFilter: $selectedFilter,
                            selectedGenreFromCard: $selectedGenreFromCard
                        )
                        .padding(.top, 16)
                        
                        if let selectedGenre = selectedFilter ?? selectedGenreFromCard {
                            // Selected Genre Grid View
                            VStack(alignment: .leading) {
                                Text(selectedGenre)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(initialBooksByGenre[selectedGenre] ?? []) { book in
                                        NavigationLink {
                                            UserBookDetailView(book: book)
                                                .onAppear {
                                                    isSearchFocused = false
                                                    showingSuggestions = false
                                                }
                                        } label: {
                                            BookCard(book: book)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 280)
                                                .padding(.horizontal, 8)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            BookSectionsView(
                                forYouBooks: viewModel.forYouBooks,
                                popularBooks: viewModel.popularBooks,
                                booksByGenre: initialBooksByGenre,
                                selectedGenreFromCard: $selectedGenreFromCard,
                                selectedFilter: $selectedFilter,
                                userPreferredGenres: userPreferredGenres
                            )
                        }
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
                showingSuggestions = !newValue.isEmpty && isSearchFocused
            }
        }
        .tabItem {
            Image(systemName: "safari")
            Text("Explore")
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
