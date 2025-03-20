//
//  SearchSuggestionsView.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import SwiftUI

struct SearchSuggestionsView: View {
    let books: [Book]
    @Binding var showingSuggestions: Bool
    @Binding var selectedBook: Book?
    @Binding var selectedAuthor: String?
    @Binding var selectedFilter: String?
    @Binding var searchText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(books) { book in
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        selectedBook = book
                        showingSuggestions = false
                        searchText = ""
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.title)
                                    .foregroundColor(.primary)
                                    .font(.body)
                                Text("Song • \(book.author)")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                            Spacer()
                            Image(systemName: "ellipsis")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                    }
                    Divider()
                        .padding(.leading)
                }
            }
        }
        .background(Color(.systemBackground))
    }
}