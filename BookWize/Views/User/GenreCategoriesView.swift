//
//  GenreCategoriesView.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import SwiftUI

struct GenreCategoriesView: View {
    let genres: [String]
    @Binding var selectedFilter: String?
    @Binding var selectedGenreFromCard: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(genres, id: \.self) { genre in
                    Button(action: {
                        if selectedFilter == genre {
                            selectedFilter = nil
                        } else {
                            selectedFilter = genre
                            selectedGenreFromCard = nil
                        }
                    }) {
                        HStack {
                            Text(genre)
                            if selectedFilter == genre {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedFilter == genre ? Color.blue : Color.gray.opacity(0.1))
                        .foregroundColor(selectedFilter == genre ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}