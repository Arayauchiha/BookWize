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
            .interactiveDismissDisabled(false)
        }
    }
}

struct BookSectionsView: View {
    let forYouBooks: [Book]
    let recentlyAddedBooks: [Book]
    let booksByGenre: [String: [Book]]
    let supabase: SupabaseClient
    @Binding var selectedGenreFromCard: String?
    @Binding var selectedFilter: String?
    @ObservedObject var viewModel: BookSearchViewModel
    @State private var selectedBook: Book?
    @State private var showingBookDetail = false
    @State private var refreshKey = UUID()

    var body: some View {
        VStack(spacing: 20) {
            ForYouSectionView(
                books: forYouBooks,
                supabase: supabase,
                viewModel: viewModel,
                selectedBook: $selectedBook,
                showingBookDetail: $showingBookDetail
            )
            .id("forYou-\(forYouBooks.count)-\(refreshKey)")

            RecentlyAddedSectionView(
                books: recentlyAddedBooks,
                selectedBook: $selectedBook,
                showingBookDetail: $showingBookDetail
            )
            .id("recentlyAdded-\(recentlyAddedBooks.count)-\(refreshKey)")

            BrowseByGenreSectionView(booksByGenre: booksByGenre, supabase: supabase)
            .id("browseByGenre-\(booksByGenre.count)-\(refreshKey)")
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("BookDataUpdated"))) { _ in
            refreshKey = UUID()
            print("BookSectionsView updating with new data")
        }
        .sheet(item: $selectedBook) { book in
            NavigationView {
                BookDetailCard(book: book, supabase: supabase, isPresented: $showingBookDetail)
                    .navigationBarHidden(true)
            }
            .interactiveDismissDisabled(false)
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

            if viewModel.isLoading && books.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if books.isEmpty {
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

struct RecentlyAddedSectionView: View {
    let books: [Book]
    @Binding var selectedBook: Book?
    @Binding var showingBookDetail: Bool
    @Environment(\.refresh) private var refresh
    @State private var isRefreshing = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Recently Added")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if !books.isEmpty {
                    NavigationLink {
                        ScrollView {
                            VStack(alignment: .leading) {
                                Text("Books added this week")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                
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
                        }
                        .navigationTitle("Recently Added")
                    } label: {
                        Text("See All")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal)

            if isRefreshing && books.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if books.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No new books in the last 7 days")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            
                        Text("Check back soon for new additions!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
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
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("BookDataUpdated"))) { _ in
            self.isRefreshing = false
        }
        .onAppear {
            self.isRefreshing = books.isEmpty
        }
    }
}

struct BrowseByGenreSectionView: View {
    let booksByGenre: [String: [Book]]
    let supabase: SupabaseClient
    @State private var isRefreshing = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Browse by Genre")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !booksByGenre.isEmpty {
                    NavigationLink {
                        GenreGridView(booksByGenre: booksByGenre, supabase: supabase)
                    } label: {
                        Text("See All")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal)

            if isRefreshing && booksByGenre.isEmpty {
                HStack {
                    Spacer()
                    VStack {
                        ProgressView()
                            .padding()
                        Text("Refreshing genres...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
            } else if booksByGenre.isEmpty {
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
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("BookDataUpdated"))) { _ in
            self.isRefreshing = false
        }
        .onAppear {
            self.isRefreshing = booksByGenre.isEmpty
        }
    }
}

struct GenreCardView: View {
    let genre: String
    let firstBook: Book
    let bookCount: Int

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
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
            VStack(spacing: 2) {
                Text(genre)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(bookCount) books")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
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

// Add a new view for displaying all genres in a grid
struct GenreGridView: View {
    let booksByGenre: [String: [Book]]
    let supabase: SupabaseClient
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(Array(booksByGenre.keys.sorted()), id: \.self) { genre in
                    if let firstBook = booksByGenre[genre]?.first {
                        NavigationLink {
                            GenreBooksView(genre: genre, books: booksByGenre[genre] ?? [], supabase: supabase)
                        } label: {
                            GenreCardView(genre: genre, firstBook: firstBook, bookCount: booksByGenre[genre]?.count ?? 0)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("All Genres")
    }
}
