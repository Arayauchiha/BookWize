import SwiftUI

struct GenreBooksView: View {
    let genre: String
    let books: [Book]
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(books) { book in
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
        .navigationTitle(genre)
        .navigationBarTitleDisplayMode(.inline)
    }
} 
