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
    @State private var selectedSectionBooks: [Book] = []
    @State private var selectedIndex: Int = 0
    @State private var cardOffset: CGFloat = 0
    
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
                            selectedSectionBooks = books
                            if let index = selectedSectionBooks.firstIndex(where: { $0.id == book.id }) {
                                selectedIndex = index
                            }
                            showingBookDetail = true
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingBookDetail) {
            if let book = selectedBook {
                NavigationView {
                    GeometryReader { geometry in
                        ZStack {
                            // Current book (always show)
                            BookDetailCard(
                                book: book,
                                supabase: supabase, isPresented: $showingBookDetail
                            )
                            .offset(x: cardOffset)
                            
                            // Only show previous/next for multiple books
                            if selectedSectionBooks.count > 1 {
                                // Previous book (preloaded)
                                if selectedIndex > 0 {
                                    BookDetailCard(
                                        book: selectedSectionBooks[selectedIndex - 1],
                                        supabase: supabase, isPresented: $showingBookDetail
                                    )
                                    .offset(x: -geometry.size.width + cardOffset)
                                }
                                
                                // Next book (preloaded)
                                if selectedIndex < selectedSectionBooks.count - 1 {
                                    BookDetailCard(
                                        book: selectedSectionBooks[selectedIndex + 1],
                                        supabase: supabase, isPresented: $showingBookDetail
                                    )
                                    .offset(x: geometry.size.width + cardOffset)
                                }
                            }
                        }
                    }
                    .navigationBarHidden(true)
                }
                .gesture(
                    // Only enable swiping gesture for multiple books
                    selectedSectionBooks.count > 1 ?
                    DragGesture()
                        .onChanged { value in
                            withAnimation(.interactiveSpring()) {
                                cardOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if value.translation.width > threshold && selectedIndex > 0 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedIndex -= 1
                                }
                            } else if value.translation.width < -threshold && selectedIndex < selectedSectionBooks.count - 1 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedIndex += 1
                                }
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                cardOffset = 0
                            }
                        } : nil
                )
                .interactiveDismissDisabled()
            }
        }
        .onChange(of: selectedIndex) { oldValue, newValue in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedBook = selectedSectionBooks[newValue]
                cardOffset = 0
            }
        }
    }
} 
