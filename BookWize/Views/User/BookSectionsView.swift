import SwiftUI

struct ForYouGridView: View {
    let books: [Book]
    let memberSelectedGenres: [String]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    @State private var selectedBook: Book?
    @State private var showingBookDetail = false
    
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
                    BookCardView(book: book) {
                        selectedBook = book
                        showingBookDetail = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("For You")
        .sheet(item: $selectedBook) { book in
            NavigationView {
                BookDetailCard(book: book, isPresented: $showingBookDetail)
                    .navigationBarHidden(true)
            }
            .interactiveDismissDisabled()
        }

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
                            ForEach(forYouBooks) { book in
                                BookCardView(book: book) {
                                    selectedBook = book
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
                
                if booksByGenre.isEmpty {
                    HStack {
                        Spacer()
                        VStack {
                            ProgressView()
                                .padding()
                            Text("Loading genres...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(booksByGenre.keys.sorted()), id: \.self) { genre in
                                NavigationLink {
                                    GenreBooksView(genre: genre, books: booksByGenre[genre] ?? [])
                                } label: {
                                    if let firstBook = booksByGenre[genre]?.first {
                                        VStack(alignment: .center, spacing: 8) {
                                            if let imageURL = firstBook.imageURL,
                                               let url = URL(string: imageURL) {
                                                CachedAsyncImage(url: url)
                                                    .frame(width: 180, height: 240)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    .shadow(radius: 4)
                                            } else {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 180, height: 240)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            
                                            VStack(spacing: 2) {
                                                Text(genre)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                
                                                Text("\(booksByGenre[genre]?.count ?? 0) books")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.top, 4)
                                        }
                                        .frame(width: 180)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(item: $selectedBook) { book in
            NavigationView {
                BookDetailCard(book: book, isPresented: $showingBookDetail)
                    .navigationBarHidden(true)
            }
            .interactiveDismissDisabled()
        }

    }
}

struct BookCardView: View {
    let book: Book
    let action: () -> Void
    @State private var isImageLoaded = false
    
    var body: some View {
        Button(action: {
            // Only trigger action if image is loaded
            if isImageLoaded || book.imageURL == nil {
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                if let imageURL = book.imageURL,
                   let url = URL(string: imageURL) {
                    CachedAsyncImage(url: url)
                        .frame(width: 180, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 4)
                        .onAppear {
                            // Slight delay to ensure image is fetched
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isImageLoaded = true
                            }
                        }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 180, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onAppear {
                            isImageLoaded = true
                        }
                }
            }
        }
    }
}
