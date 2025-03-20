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
    @State private var selectedBook: Book? = nil
    @State private var selectedAuthor: String? = nil
    @State private var initialBooksByGenre: [String: [Book]] = [:]
    
    let userName = "Bunny"
    let genres = ["Fiction", "Science", "History", "Technology", "Business"]
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.searchText.isEmpty {
                        Text("Hi \(userName)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                    }
                    
                    // Search Bar
                    VStack(alignment: .leading) {
                        HStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("Search by title, author or genre...", text: $viewModel.searchText)
                                    .disableAutocorrection(true)
                                    .onChange(of: viewModel.searchText) { oldValue, newValue in
                                        showingSuggestions = !newValue.isEmpty
                                    }
                                if !viewModel.searchText.isEmpty {
                                    Button(action: {
                                        viewModel.searchText = ""
                                        showingSuggestions = false
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            if !viewModel.searchText.isEmpty {
                                Button("Cancel") {
                                    viewModel.searchText = ""
                                    showingSuggestions = false
                                    hideKeyboard()
                                }
                                .foregroundColor(.red)
                                .transition(.move(edge: .trailing))
                            }
                        }
                        .animation(.default, value: viewModel.searchText)
                    }
                    .padding(.horizontal)
                    
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
                                    NavigationLink(isActive: Binding(
                                        get: { selectedBook?.id == book.id },
                                        set: { isActive in
                                            if isActive {
                                                selectedBook = book
                                            }
                                        }
                                    )) {
                                        BookDetailView(book: book)
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
                        
                        if let selectedGenre = selectedFilter ?? selectedGenreFromCard {
                            // Selected Genre Grid View
                            VStack(alignment: .leading) {
                                Text(selectedGenre)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(initialBooksByGenre[selectedGenre] ?? []) { book in
                                        BookCard(book: book)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 280)
                                            .padding(.horizontal, 8)
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
                                selectedFilter: $selectedFilter
                            )
                        }
                    }
                }
                .onAppear {
                    initialBooksByGenre = viewModel.booksByGenre
                }
                .onChange(of: selectedBook) { oldValue, newValue in
                    if newValue == nil {
                        selectedGenreFromCard = nil
                        viewModel.searchText = ""
                        showingSuggestions = false
                    }
                }
                .onChange(of: selectedAuthor) { oldValue, newValue in
                    if newValue == nil {
                        selectedGenreFromCard = nil
                        viewModel.searchText = ""
                        showingSuggestions = false
                    }
                }
            }
        }
    }
}
