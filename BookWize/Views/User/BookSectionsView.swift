
import SwiftUI

struct ForYouGridView: View {
    let books: [Book]
    let memberSelectedGenres: [String]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    
    var filteredBooks: [Book] {
        if memberSelectedGenres.isEmpty {
            return books
        }
        return books.filter { book in
            memberSelectedGenres.contains(book.genre ?? "")
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredBooks) { book in
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
        .navigationTitle("For You")
    }
}

struct BookSectionsView: View {
    let forYouBooks: [Book]
    let popularBooks: [Book]
    let booksByGenre: [String: [Book]]
    @Binding var selectedGenreFromCard: String?
    @Binding var selectedFilter: String?
    let userPreferredGenres: [String]
    @ObservedObject var viewModel: BookSearchViewModel
    @State private var selectedBook: Book?
    @State private var showingBookDetail = false
    @State private var selectedSectionBooks: [Book] = []
    @State private var selectedIndex: Int = 0
    @State private var cardOffset: CGFloat = 0
    @State private var dragDirection: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // For You Section
            VStack(alignment: .leading) {
                HStack {
                    Text("For You")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if !viewModel.allPreferredBooks.isEmpty {
                        NavigationLink {
                            ForYouGridView(books: viewModel.allPreferredBooks, memberSelectedGenres: viewModel.memberSelectedGenres)
                        } label: {
                            HStack(spacing: 4) {
                                Text("See All")
                                    .font(.subheadline)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
                
                if viewModel.allPreferredBooks.isEmpty {
                    Text("Select your favorite genres to get personalized recommendations")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.allPreferredBooks) { book in
                                BookCardView(book: book) {
                                    selectedBook = book
                                    selectedSectionBooks = viewModel.allPreferredBooks
                                    if let index = selectedSectionBooks.firstIndex(where: { $0.id == book.id }) {
                                        selectedIndex = index
                                    }
                                    showingBookDetail = true
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
            
            // Popular Books Section
            VStack(alignment: .leading) {
                HStack {
                    Text("Popular Books")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    NavigationLink {
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                                ForEach(popularBooks) { book in
                                    BookCardView(book: book) {
                                        selectedBook = book
                                        selectedSectionBooks = popularBooks
                                        if let index = selectedSectionBooks.firstIndex(where: { $0.id == book.id }) {
                                            selectedIndex = index
                                        }
                                        showingBookDetail = true
                                    }
                                }
                            }
                            .padding()
                        }
                        .navigationTitle("Popular Books")
                    } label: {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(popularBooks) { book in
                            BookCardView(book: book) {
                                selectedBook = book
                                selectedSectionBooks = popularBooks
                                if let index = selectedSectionBooks.firstIndex(where: { $0.id == book.id }) {
                                    selectedIndex = index
                                }
                                showingBookDetail = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
            
            // Browse by Genre Section
            VStack(alignment: .leading) {
                Text("Browse by Genre")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(booksByGenre.keys.sorted()), id: \.self) { genre in
                            NavigationLink {
                                GenreBooksView(genre: genre, books: booksByGenre[genre] ?? [])
                            } label: {
                                VStack(spacing: 6) {
                                    if let firstBook = booksByGenre[genre]?.first,
                                       let imageURL = firstBook.imageURL,
                                       let url = URL(string: imageURL) {
                                        CachedAsyncImage(url: url)
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
        .sheet(isPresented: $showingBookDetail) {
            if let book = selectedBook {
                NavigationView {
                    GeometryReader { geometry in
                        ZStack {
                            // Previous book (preloaded)
                            if selectedIndex > 0 {
                                BookDetailCard(
                                    book: selectedSectionBooks[selectedIndex - 1],
                                    isPresented: $showingBookDetail
                                )
                                .offset(x: -geometry.size.width + cardOffset)
                            }
                            
                            // Current book
                            BookDetailCard(book: book, isPresented: $showingBookDetail)
                                .offset(x: cardOffset)
                            
                            // Next book (preloaded)
                            if selectedIndex < selectedSectionBooks.count - 1 {
                                BookDetailCard(
                                    book: selectedSectionBooks[selectedIndex + 1],
                                    isPresented: $showingBookDetail
                                )
                                .offset(x: geometry.size.width + cardOffset)
                            }
                        }
                    }
                    .navigationBarHidden(true)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragDirection = value.translation.width
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
                        }
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

struct BookCardView: View {
    let book: Book
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                if let imageURL = book.imageURL,
                   let url = URL(string: imageURL) {
                    CachedAsyncImage(url: url)
                        .frame(width: 180, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 4)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 180, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}
