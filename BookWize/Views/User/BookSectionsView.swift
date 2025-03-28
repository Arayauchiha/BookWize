import SwiftUI
import Supabase

struct ForYouGridView: View {
    let books: [Book]
    let memberSelectedGenres: [String]
    let supabase: SupabaseClient
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
                BookDetailCard(book: book, supabase: supabase, isPresented: $showingBookDetail)
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
    let supabase: SupabaseClient
    @Binding var selectedGenreFromCard: String?
    @Binding var selectedFilter: String?
    @ObservedObject var viewModel: BookSearchViewModel
    @State private var selectedBook: Book?
    @State private var showingBookDetail = false

    var body: some View {
        VStack(spacing: 20) {
            ForYouSectionView(
                books: forYouBooks,
                supabase: supabase,
                viewModel: viewModel,
                selectedBook: $selectedBook,
                showingBookDetail: $showingBookDetail
            )

            PopularBooksSectionView(
                books: popularBooks,
                selectedBook: $selectedBook,
                showingBookDetail: $showingBookDetail
            )

            BrowseByGenreSectionView(booksByGenre: booksByGenre, supabase: supabase)
        }
        .sheet(item: $selectedBook) { book in
            NavigationView {
                BookDetailCard(book: book, supabase: supabase, isPresented: $showingBookDetail)
                    .navigationBarHidden(true)
            }
            .interactiveDismissDisabled()
        }

    }
}

struct ForYouSectionView: View {
    let books: [Book]
    let supabase : SupabaseClient
    @ObservedObject var viewModel: BookSearchViewModel
    @Binding var selectedBook: Book?
    @Binding var showingBookDetail: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("For You")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if !viewModel.allPreferredBooks.isEmpty {
                    NavigationLink {
                        ForYouGridView(
                            books: viewModel.allPreferredBooks,
                            memberSelectedGenres: viewModel.memberSelectedGenres,
                            supabase: supabase
                        )
                    } label: {
                        Text("See All")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal)

            if books.isEmpty {
                Text("Select your favorite genres to get personalized recommendations")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
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
        }
        .padding(.vertical, 8)
    }
}

    
    struct PopularBooksSectionView: View {
        let books: [Book]
        @Binding var selectedBook: Book?
        @Binding var showingBookDetail: Bool

        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text("Popular Books")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    NavigationLink {
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                                ForEach(books) { book in
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
                        Text("See All")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
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
            .padding(.vertical, 8)
        }
    }

    struct BrowseByGenreSectionView: View {
        let booksByGenre: [String: [Book]]
        let supabase: SupabaseClient

        var body: some View {
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
                                    GenreBooksView(genre: genre, books: booksByGenre[genre] ?? [], supabase: supabase)
                                } label: {
                                    if let firstBook = booksByGenre[genre]?.first {
                                        GenreCardView(genre: genre, firstBook: firstBook, bookCount: booksByGenre[genre]?.count ?? 0)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    struct GenreCardView: View {
        let genre: String
        let firstBook: Book
        let bookCount: Int

        var body: some View {
            VStack(alignment: .center, spacing: 8) {
                ZStack(alignment: .bottom) {
                    if let imageURL = firstBook.imageURL, let url = URL(string: imageURL) {
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
                    
                    // Genre overlay at the bottom of the card
                    VStack(alignment: .leading, spacing: 0) {
                        Text(genre)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("\(bookCount) books")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(width: 180, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                    )
                }
            }
            .frame(width: 180)
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
            ZStack(alignment: .bottom) {
                // Book cover image or placeholder
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
                
                // Title overlay at the bottom of the card
                VStack(alignment: .leading, spacing: 0) {
                    Text(book.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                }
                .frame(width: 180, alignment: .leading)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 8,
                        style: .continuous
                    )
                )
            }
        }
    }
}
