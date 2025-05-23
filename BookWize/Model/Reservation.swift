// Reservation.swift
// This file is intentionally left empty 
// Reservation.swift
// This file is intentionally left empty

import SwiftUI
import Supabase

struct ReservedMember: Codable {
    let id: UUID
    let email: String
    let name: String
    let gender: String
    let selectedLibrary: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case gender
        case selectedLibrary = "selectedLibrary"
    }
}

struct ReservedBook: Codable {
    let id: UUID
    let isbn: String?
    let title: String
    let author: String
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let genre: String?
    let imageURL: String?
    let quantity: Int
    let availableQuantity: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case isbn
        case title
        case author
        case publisher
        case publishedDate
        case description
        case pageCount
        case genre
        case imageURL
        case quantity
        case availableQuantity
    }
}

struct ReservationRecord: Identifiable, Codable {
    let id: UUID
    let created_at: Date
    let member_id: UUID
    let book_id: UUID
    var member: ReservedMember?
    var book: ReservedBook?
    
    enum CodingKeys: String, CodingKey {
        case id
        case created_at
        case member_id
        case book_id
        case member
        case book
    }
}

// MARK: - View Components
struct ReservationCard: View {
    let reservation: ReservationRecord
    let issueAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Book Cover and Basic Info
            HStack(alignment: .top, spacing: 16) {
                // Book Cover
                if let imageURL = reservation.book?.imageURL,
                   let url = URL(string: imageURL) {
                    CachedAsyncImage(url: url)
                        .frame(width: 100, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 2)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 100, height: 150)
                        .overlay(
                            Image(systemName: "book.closed")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                
                // Book and Member Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(reservation.book?.title ?? "Unknown Book")
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(reservation.book?.author ?? "Unknown Author")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Member Info
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                        Text(reservation.member?.name ?? "Unknown Member")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Reservation Date
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                        Text(reservation.created_at.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Action Button
            Button(action: issueAction){
                Text("Issue Book")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.top, 12)
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct ReservationDetailSheet: View {
    let reservation: ReservationRecord
    let issueAction: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Book Cover
                    if let imageURL = reservation.book?.imageURL,
                       let url = URL(string: imageURL) {
                        CachedAsyncImage(url: url)
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 4)
                    }
                    
                    // Book Details
                    DetailSection(title: "Book Information") {
                        DetailItem(title: "Title", value: reservation.book?.title ?? "N/A")
                        DetailItem(title: "Author", value: reservation.book?.author ?? "N/A")
                        if let isbn = reservation.book?.isbn {
                            DetailItem(title: "ISBN", value: isbn)
                        }
                        if let genre = reservation.book?.genre {
                            DetailItem(title: "Genre", value: genre)
                        }
                    }
                    
                    // Member Details
                    DetailSection(title: "Member Information") {
                        DetailItem(title: "Name", value: reservation.member?.name ?? "N/A")
                        DetailItem(title: "Email", value: reservation.member?.email ?? "N/A")
                        DetailItem(title: "Library", value: reservation.member?.selectedLibrary ?? "N/A")
                    }
                    
                    // Reservation Details
                    DetailSection(title: "Reservation Information") {
                        DetailItem(
                            title: "Reserved On",
                            value: reservation.created_at.formatted(date: .long, time: .shortened)
                        )
                        DetailItem(
                            title: "Status",
                            value: "Reserved",
                            valueColor: .blue
                        )
                    }
                    
                    // Action Button
                    Button(action: issueAction) {
                        Text("Issue Book")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Reservation Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
}

struct DetailItem: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundColor(valueColor)
        }
        .font(.subheadline)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            Text("Loading reservations...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}
