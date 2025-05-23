import SwiftUI
import Supabase

struct GenreBooksView: View {
    let genre: String
    let books: [Book]
    let supabase: SupabaseClient
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
            
                if books.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No books found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("There are currently no books available in the \(genre) genre")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                } else {
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
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedBook) { book in
            NavigationView {
                BookDetailCard(book: book, supabase: supabase, isPresented: $showingBookDetail)
                    .navigationBarHidden(true)
            }
            .interactiveDismissDisabled(false)
        }

    }
}
