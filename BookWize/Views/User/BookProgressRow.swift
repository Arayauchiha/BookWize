import SwiftUI
import Supabase

struct BookProgressRow: View {
    let book: Book
    let issuedBook: issueBooks
    let supabase: SupabaseClient
    
    @State private var pagesRead: Int
    @State private var showingReadingProgress = false
    @State private var isUpdating = false
    @State private var errorMessage: String?
    // Add a callback to notify parent when pages are updated
    var onPagesUpdated: ((Int) -> Void)?
    
    init(book: Book, issuedBook: issueBooks, supabase: SupabaseClient, onPagesUpdated: ((Int) -> Void)? = nil) {
        self.book = book
        self.issuedBook = issuedBook
        self.supabase = supabase
        self.onPagesUpdated = onPagesUpdated
        self._pagesRead = State(initialValue: issuedBook.pagesRead ?? 0)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Book Cover
            if let imageURL = book.imageURL, let url = URL(string: imageURL) {
                CachedAsyncImage(url: url)
                    .frame(width: 60, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(radius: 2)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Book Info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let pageCount = book.pageCount {
                    HStack(spacing: 8) {
                        // Progress Bar
                        ProgressView(value: Double(pagesRead), total: Double(pageCount))
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(height: 6)
                        
                        // Percentage
                        Text("\(Int(readingPercentage * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .trim(from: 0, to: readingPercentage)
                    .stroke(
                        readingPercentage >= 1.0 ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: readingPercentage >= 1.0 ? "checkmark" : "book")
                    .font(.system(size: 16))
                    .foregroundColor(readingPercentage >= 1.0 ? .green : .blue)
            }
            .onTapGesture {
                showingReadingProgress = true
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingReadingProgress) {
            updateReadingProgressView
        }
    }
    
    private var readingPercentage: Double {
        guard let pageCount = book.pageCount, pageCount > 0 else { return 0 }
        return min(Double(pagesRead) / Double(pageCount), 1.0)
    }
    
    private var updateReadingProgressView: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Book Information
                VStack(spacing: 8) {
                    if let imageURL = book.imageURL, let url = URL(string: imageURL) {
                        CachedAsyncImage(url: url)
                            .frame(width: 120, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 3)
                            .padding(.bottom, 8)
                    }
                    
                    Text(book.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(book.author)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Reading Progress
                VStack(spacing: 16) {
                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                            .frame(width: 160, height: 160)
                        
                        Circle()
                            .trim(from: 0, to: readingPercentage)
                            .stroke(
                                readingPercentage >= 1.0 ? Color.green : Color.blue,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 4) {
                            Text("\(Int(readingPercentage * 100))%")
                                .font(.system(size: 36, weight: .bold))
                            
                            if let pageCount = book.pageCount {
                                Text("\(pagesRead) of \(pageCount) pages")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    // Pages Read Input
                    VStack(spacing: 8) {
                        Text("Update your progress")
                            .font(.headline)
                        
                        HStack {
                            Text("Pages read:")
                                .foregroundColor(.secondary)
                            
                            TextField("0", value: $pagesRead, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 100)
                            
                            if let pageCount = book.pageCount {
                                Text("of \(pageCount)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: updateReadingProgress) {
                        HStack {
                            if isUpdating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            
                            Text("Save Progress")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isUpdating)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Reading Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingReadingProgress = false
                    }
                }
            }
        }
    }
    
    private func updateReadingProgress() {
        isUpdating = true
        errorMessage = nil
        
        // Validate the input
        guard let pageCount = book.pageCount else {
            errorMessage = "Could not find the total page count for this book"
            isUpdating = false
            return
        }
        
        if pagesRead < 0 {
            errorMessage = "Pages read cannot be negative"
            isUpdating = false
            return
        }
        
        if pagesRead > pageCount {
            errorMessage = "Pages read cannot exceed the total page count"
            isUpdating = false
            return
        }
        
        Task {
            do {
                try await supabase
                    .from("issuebooks")
                    .update(["pages_read": pagesRead])
                    .eq("id", value: issuedBook.id)
                    .execute()
                
                await MainActor.run {
                    // Call the callback to notify parent
                    onPagesUpdated?(pagesRead)
                    isUpdating = false
                    showingReadingProgress = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update reading progress: \(error.localizedDescription)"
                    isUpdating = false
                }
            }
        }
    }
} 