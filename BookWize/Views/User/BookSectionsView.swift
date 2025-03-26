import SwiftUI
import Supabase

struct ForYouGridView: View {
    let books: [Book]
    let memberSelectedGenres: [String]
    let supabase: SupabaseClient
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    @State private var selectedBook: Book?
    @State private var showingBookDetail = false
    @State private var selectedSectionBooks: [Book] = []
    @State private var selectedIndex: Int = 0
    @State private var cardOffset: CGFloat = 0
    
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
                        selectedSectionBooks = filteredBooks
                        if let index = selectedSectionBooks.firstIndex(where: { $0.id == book.id }) {
                            selectedIndex = index
                        }
                        showingBookDetail = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("For You")
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

struct BookSectionsView: View {
    let forYouBooks: [Book]
    let popularBooks: [Book]
    let booksByGenre: [String: [Book]]
    let supabase: SupabaseClient
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
                            ForYouGridView(
                                books: viewModel.allPreferredBooks,
                                memberSelectedGenres: viewModel.memberSelectedGenres,
                                supabase: supabase
                            )
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
                    HStack(spacing: 16) {
                        ForEach(Array(booksByGenre.keys.sorted()), id: \.self) { genre in
                            NavigationLink {
                                GenreBooksView(
                                    genre: genre,
                                    books: booksByGenre[genre] ?? [],
                                    supabase: supabase
                                )
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
                    .padding(.horizontal)
                }
            }
        }
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
