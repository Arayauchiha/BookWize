import SwiftUI

// MARK: - Book Cover View
private struct BookCoverView: View {
    let imageURL: String
    let scrollOffset: CGFloat
    let isFullScreen: Bool
    
    var body: some View {
        if let url = URL(string: imageURL) {
            GeometryReader { imageGeometry in
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: max(400 - scrollOffset, 200))
                .cornerRadius(8)
                .shadow(radius: 5)
                .scaleEffect(isFullScreen ? 1 : min(1, max(0.8, 1 - scrollOffset / 400)))
                .opacity(isFullScreen ? 1 : min(1, max(0.5, 1 - scrollOffset / 400)))
            }
            .frame(height: 400)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Book Info View
private struct BookInfoView: View {
    let book: Book
    
    var body: some View {
        VStack(spacing: 8) {
            Text(book.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(book.author)
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .id("titleSection")
    }
}

// MARK: - Action Buttons View
private struct ActionButtonsView: View {
    let book: Book
    @Binding var isReserving: Bool
    @Binding var addedToWishlist: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Reservation logic removed as requested
            }) {
                HStack {
                    if isReserving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Reserve")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(book.isAvailable ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(!book.isAvailable || isReserving)
            
            Button(action: {
                addedToWishlist.toggle()
            }) {
                HStack {
                    Image(systemName: addedToWishlist ? "heart.fill" : "heart")
                    Text("Add to Wishlist")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
}

struct BookDetailCard: View {
    let book: Book
    @Binding var isPresented: Bool
    @State private var cardOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var scrollOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    @State private var isReserving = false
    @State private var addedToWishlist = false
    @State private var isFullScreen = false
    @State private var isImageLoaded = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // Book Cover
                        if let imageURL = book.imageURL {
                            BookCoverView(
                                imageURL: imageURL,
                                scrollOffset: scrollOffset,
                                isFullScreen: isFullScreen
                            )
                        }
                        
                        // Book Info
                        BookInfoView(book: book)
                        
                        // Availability Status
                        HStack {
                            Image(systemName: book.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(book.isAvailable ? .green : .red)
                            Text(book.isAvailable ? "Available" : "Unavailable")
                                .foregroundColor(book.isAvailable ? .green : .red)
                        }
                        
                        // Action Buttons
                        ActionButtonsView(
                            book: book,
                            isReserving: $isReserving,
                            addedToWishlist: $addedToWishlist
                        )
                        
                        // Book Description
                        if let description = book.description {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Book Details Grid
                        HStack(spacing: 0) {
                            BookDetailItem(
                                icon: "book.closed",
                                title: "Genre",
                                value: book.genre ?? "Unknown"
                            )
                            
                            Divider()
                                .frame(height: 40)
                            
                            BookDetailItem(
                                icon: "calendar",
                                title: "Released",
                                value: book.publishedDate ?? "Unknown"
                            )
                            
                            Divider()
                                .frame(height: 40)
                            
                            BookDetailItem(
                                icon: "text.justify",
                                title: "Length",
                                value: "\(book.pageCount ?? 0) pages"
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                    .background(GeometryReader { proxy in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: proxy.frame(in: .named("scroll")).minY
                        )
                    })
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = -value
                    isFullScreen = scrollOffset > 50
                }
            }
            .background(Color(.systemBackground))
        }
        .overlay(
            Button(action: {
                isPresented = false
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.gray)
                    .padding()
            }
            .opacity(isDragging || scrollOffset > 50 ? 0 : 1),
            alignment: .topTrailing
        )
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.height > 0 && scrollOffset <= 0 {
                        state = value.translation.height
                    }
                }
                .onChanged { _ in
                    isDragging = true
                }
                .onEnded { value in
                    isDragging = false
                    if value.translation.height > 100 && scrollOffset <= 0 {
                        dismiss()
                    }
                }
        )
        .offset(y: dragOffset)
    }
}

struct BookDetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.gray)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
} 