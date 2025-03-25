//
//  BookSectionsView.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import SwiftUI

struct ForYouGridView: View {
    let books: [Book]
    let memberSelectedGenres: [String]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    
    var filteredBooks: [Book] {
        if memberSelectedGenres.isEmpty {
            return books
        }
        return books.filter { book in
            if let genre = book.genre {
                return memberSelectedGenres.contains(genre)
            }
            return false
        }
    }

    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredBooks) { book in
                    NavigationLink {
                        UserBookDetailView(book: book)
                    } label: {
                        BookCard(book: book)
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("For You")
    }
}

struct BookSectionsView: View {
    let forYouBooks: [Book]
    let popularBooks: [Book]
    let booksByGenre: [String: [Book]]
    @Binding var selectedGenreFromCard: String?
    @Binding var selectedFilter: String?
    let userPreferredGenres: [String]
    @State private var showingForYouGrid = false
    @State private var showingPopularGrid = false
    @ObservedObject var viewModel: BookSearchViewModel
    
    var filteredForYouBooks: [Book] {
        print("Filtering For You books with genres: \(viewModel.memberSelectedGenres)")
        if viewModel.memberSelectedGenres.isEmpty {
            print("No selected genres, showing all For You books")
            return forYouBooks
        }
        let filtered = forYouBooks.filter { book in
            let matches = viewModel.memberSelectedGenres.contains(book.genre ?? "")
            if matches {
                print("Book '\(book.title)' matches genre: \(book.genre ?? "unknown")")
            }
            return matches
        }
        print("Found \(filtered.count) filtered For You books")
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // For You Section
            VStack(alignment: .leading) {
                HStack {
                    Text("For You")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if !filteredForYouBooks.isEmpty {
                        NavigationLink {
                            ForYouGridView(books: viewModel.allPreferredBooks, memberSelectedGenres: viewModel.memberSelectedGenres)
                        } label: {
                            HStack(spacing: 4) {
                                Text("See All")
                                    .font(.subheadline)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
                
                if filteredForYouBooks.isEmpty {
                    Text("Select your favorite genres to get personalized recommendations")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(filteredForYouBooks) { book in
                                NavigationLink {
                                    UserBookDetailView(book: book)
                                } label: {
                                    BookCard(book: book)
                                        .frame(width: 180)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
            
            // Popular Books Section
            VStack(alignment: .leading) {
                HStack {
                    Text("Popular Books")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    NavigationLink {
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                                ForEach(popularBooks) { book in
                                    NavigationLink {
                                        UserBookDetailView(book: book)
                                    } label: {
                                        BookCard(book: book)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 280)
                                    }
                                }
                            }
                            .padding()
                        }
                        .navigationTitle("Popular Books")
                    } label: {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(popularBooks) { book in
                            NavigationLink {
                                UserBookDetailView(book: book)
                            } label: {
                                BookCard(book: book)
                                    .frame(width: 180)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
            
            // Books by Genre Section
            VStack(alignment: .leading) {
                Text("Browse by Genre")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(booksByGenre.keys.sorted()), id: \.self) { genre in
                            NavigationLink {
                                GenreBooksView(genre: genre, books: booksByGenre[genre] ?? [])
                            } label: {
                                VStack(spacing: 6) {
                                    if let firstBook = booksByGenre[genre]?.first,
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
                                }
                                .frame(width: 120)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
