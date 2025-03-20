//
//  BookSectionsView.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import SwiftUI

struct BookSectionsView: View {
    let forYouBooks: [Book]
    let popularBooks: [Book]
    let booksByGenre: [String: [Book]]
    @Binding var selectedGenreFromCard: String?
    @Binding var selectedFilter: String?
    @State private var selectedBook: Book?
    
    var body: some View {
        VStack(spacing: 20) {
            // For You Section
            VStack(alignment: .leading) {
                Text("For You")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(forYouBooks) { book in
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
                                    .frame(width: 180)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
            
            // Popular Books Section
            VStack(alignment: .leading) {
                Text("Popular Books")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(popularBooks) { book in
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
                            Button(action: {
                                selectedGenreFromCard = genre
                                selectedFilter = nil
                            }) {
                                VStack(spacing: 6) {
                                    if let firstBook = booksByGenre[genre]?.first,
                                       let imageURL = firstBook.imageURL,
                                       let url = URL(string: imageURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.gray.opacity(0.2)
                                        }
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