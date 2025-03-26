import SwiftUI

struct GenreBooksView: View {
    let genre: String
    let books: [Book]
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    @State private var selectedBook: Book?
    @State private var showingBookDetail = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(genre)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
            
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(books) { book in
                        BookCardView(book: book) {
                            selectedBook = book
                            showingBookDetail = true
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedBook) { book in
            NavigationView {
                BookDetailCard(book: book, isPresented: $showingBookDetail)
                    .navigationBarHidden(true)
            }
            .interactiveDismissDisabled()
        }

    }
} 
