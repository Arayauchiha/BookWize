import SwiftUI
import Supabase

// Add these near the top of the file, after the imports
private struct SupabaseClientKey: EnvironmentKey {
    static let defaultValue: SupabaseClient = SupabaseClient(
        supabaseURL: URL(string: "https://qjhfnprghpszprfhjzdl.supabase.coL")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqaGZucHJnaHBzenByZmhqemRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzNzE5NTAsImV4cCI6MjA1Nzk0Nzk1MH0.Bny2_LBt2fFjohwmzwCclnFNmrC_LZl3s3PVx-SOeNc"
    )
}

extension EnvironmentValues {
    var supabaseClient: SupabaseClient {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}

// MARK: - Book Cover View
private struct BookCoverView: View {
    let imageURL: String
    let scrollOffset: CGFloat
    let isFullScreen: Bool
    @Binding var isImageLoaded: Bool
    
    var body: some View {
        if let url = URL(string: imageURL) {
            GeometryReader { imageGeometry in
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .onAppear {
                                isImageLoaded = true
                            }
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .onAppear {
                                isImageLoaded = true
                            }
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(ProgressView())
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .onAppear {
                                isImageLoaded = true
                            }
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

// Add this class
class BookReservationViewModel: ObservableObject {
    private let supabase: SupabaseClient
    
    @Published var isReserving = false
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func reserveBook(book: Book) async throws {
        isReserving = true
        defer { isReserving = false }
        
        let reservation = BookReservation(
            id: UUID(),
            created_at: Date(),
            member_id: try await supabase.auth.session.user.id,
            book_id: book.id
        )
        
        let response: BookReservation = try await supabase.database
            .from("BookReservation")
            .insert(reservation)
            .single()
            .execute()
            .value
        
        try await supabase
            .from("Books")
            .update(["availableQuantity": book.availableQuantity - 1])
            .eq("id", value: book.id)
            .execute()
    }
}

// Modify ActionButtonsView to use the view model
private struct ActionButtonsView: View {
    let book: Book
    let supabase: SupabaseClient
    @Binding var isReserving: Bool
    @Binding var addedToWishlist: Bool
    @State private var showError = false
    @State private var errorMessage = ""
    
    private func reserveBook() async {
        isReserving = true
        
        do {
            // First get a valid member ID from the database
            let members: [MemberID] = try await supabase.database
                .from("Members")
                .select("id")
                .limit(1)
                .execute()
                .value
            
            guard let member = members.first else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No members found in the system"])
            }
            
            let reservation = BookReservation(
                id: UUID(),
                created_at: Date(),
                member_id: member.id,
                book_id: book.id
            )
            
            // Insert the reservation
            try await supabase.database
                .from("BookReservation")
                .insert(reservation)
                .execute()
            
            // Update book's available quantity
            if book.availableQuantity > 0 {
                try await supabase.database
                    .from("Books")
                    .update(["availableQuantity": book.availableQuantity - 1])
                    .eq("id", value: book.id)
                    .execute()
            }
            
            print("Book reserved successfully!")
            
        } catch {
            print("Error reserving book: \(error)")
            errorMessage = "Failed to reserve book. Please try again."
            showError = true
        }
        
        isReserving = false
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await reserveBook()
                }
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            
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

struct BookReservation: Codable {
    let id: UUID
    let created_at: Date
    let member_id: UUID
    let book_id: UUID
}

// Add a simple struct for member ID
private struct MemberID: Codable {
    let id: UUID
}

struct BookDetailCard: View {
    let book: Book
    let supabase: SupabaseClient
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
                                isFullScreen: isFullScreen,
                                isImageLoaded: $isImageLoaded
                            )
                        } else {
                            // Placeholder if no cover image
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(maxWidth: .infinity)
                                .frame(height: 400)
                                .cornerRadius(8)
                                .onAppear {
                                    isImageLoaded = true
                                }
                        }
                        
                        // Only show the rest of the content when image is loaded
                        if isImageLoaded {
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
                                supabase: supabase,
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
                        } else {
                            // Loading indicator while content is loading
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
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
        .onAppear {
            // Force image load status to true after a delay if it doesn't load
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if !isImageLoaded {
                    isImageLoaded = true
                }
            }
        }
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
