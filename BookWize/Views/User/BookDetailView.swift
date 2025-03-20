//
//  BookDetailView.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import SwiftUI

struct BookDetailView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                if let imageURL = book.imageURL,
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 5)
                }
                
                VStack(spacing: 16) {
                    Text(book.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("by \(book.author)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Text(book.genre)
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(20)
                        
                        Text(String(book.publicationYear))
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                    }
                    
                    if !book.isbn.isEmpty {
                        Text("ISBN: \(book.isbn)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    
                    HStack {
                        Image(systemName: book.availability == .available ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(book.availability == .available ? .green : .red)
                            .font(.title2)
                        Text(book.availability.rawValue.capitalized)
                            .font(.headline)
                            .foregroundColor(book.availability == .available ? .green : .red)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(book.availability == .available ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .cornerRadius(25)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}