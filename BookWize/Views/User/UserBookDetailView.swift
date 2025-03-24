////
////  BookDetailView.swift
////  Search&Browse
////
////  Created by Devashish Upadhyay on 19/03/25.
////
//
//import SwiftUI
//
//struct UserBookDetailView: View {
//    let book: Book
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 24) {
//                
//                if let imageURL = book.imageURL,
//                   let url = URL(string: imageURL) {
//                    AsyncImage(url: url) { image in
//                        image
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                    } placeholder: {
//                        Rectangle()
//                            .fill(Color.gray.opacity(0.2))
//                    }
//                    .frame(height: 400)
//                    .clipShape(RoundedRectangle(cornerRadius: 15))
//                    .shadow(radius: 5)
//                }
//                
//                VStack(spacing: 16) {
//                    Text(book.title)
//                        .font(.title)
//                        .fontWeight(.bold)
//                        .multilineTextAlignment(.center)
//                    
//                    Text("by \(book.author)")
//                        .font(.title2)
//                        .foregroundColor(.secondary)
//                    
//                    HStack(spacing: 12) {
//                        Text(book.genre ?? "")
//                            .font(.headline)
//                            .padding(.horizontal, 16)
//                            .padding(.vertical, 8)
//                            .background(Color.blue.opacity(0.1))
//                            .cornerRadius(20)
//                        
//                        Text(String(book.publishedDate ?? ""))
//                            .font(.headline)
//                            .foregroundColor(.secondary)
//                            .padding(.horizontal, 16)
//                            .padding(.vertical, 8)
//                            .background(Color.gray.opacity(0.1))
//                            .cornerRadius(20)
//                    }
//                    
//                    if !book.isbn.isEmpty {
//                        Text("ISBN: \(book.isbn)")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .padding(.top, 4)
//                    }
//                    
//                    HStack {
//                        Image(systemName: book.availability == .available ? "checkmark.circle.fill" : "xmark.circle.fill")
//                            .foregroundColor(book.availability == .available ? .green : .red)
//                            .font(.title2)
//                        Text(book.availability.rawValue.capitalized)
//                            .font(.headline)
//                            .foregroundColor(book.availability == .available ? .green : .red)
//                    }
//                    .padding(.vertical, 12)
//                    .padding(.horizontal, 24)
//                    .background(book.availability == .available ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
//                    .cornerRadius(25)
//                }
//                .padding(.horizontal)
//                .padding(.bottom, 32)
//            }
//        }
//        .background(Color(UIColor.systemBackground))
//    }
//    
//    }
//
//    
//

import SwiftUI

struct UserBookDetailView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                bookCoverImage
                bookDetailsSection
            }
        }
        .background(Color(UIColor.systemBackground))
    }
    
    // Break down the image view into a separate computed property
    private var bookCoverImage: some View {
        Group {
            if let imageURL = book.imageURL, let url = URL(string: imageURL) {
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
        }
    }
    
    // Break down the book details into a separate computed property
    private var bookDetailsSection: some View {
        VStack(spacing: 16) {
            Text(book.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("by \(book.author)")
                .font(.title2)
                .foregroundColor(.secondary)
            
            genreAndDateView
            
            isbnView
            
            availabilityView
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
    
    // Further breakdown of components
    private var genreAndDateView: some View {
        HStack(spacing: 12) {
            if let genre = book.genre {
                Text(genre)
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
            }
            
            if let publishedDate = book.publishedDate {
                Text(publishedDate)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
            }
        }
    }
    
    private var isbnView: some View {
        Group {
            if !book.isbn.isEmpty {
                Text("ISBN: \(book.isbn)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
    
    private var availabilityView: some View {
        HStack {
            Image(systemName: book.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(book.isAvailable ? .green : .red)
                .font(.title2)
            Text(book.isAvailable ? "Available" : "Unavailable")
                .font(.headline)
                .foregroundColor(book.isAvailable ? .green : .red)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(book.isAvailable ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(25)
    }
}
