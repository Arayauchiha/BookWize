import SwiftUI
import Supabase
struct RequestBookView: View {
    @Environment(\.dismiss) var dismiss
    @State private var author = ""  // Changed from type to author
    @State private var title = ""
    @State private var quantityString = ""
    @State private var reason = ""
    @State private var showQuantityError = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var quantity: Int {
        return Int(quantityString) ?? 0
    }
    
    var isFormValid: Bool {
        !author.isEmpty && !title.isEmpty && !reason.isEmpty && quantity > 0  // Updated to check author
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Author", text: $author)  // Changed from Type to Author
                        .textContentType(.name)
                        .autocapitalization(.words)
                    
                    TextField("Title", text: $title)
                    
                    TextField("Quantity", text: $quantityString)
                        .keyboardType(.numberPad)
                    if showQuantityError {
                        Text("Quantity must be greater than 0")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section(header: Text("Additional information")) {
                    TextField("Reason for Addition", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Request Item")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Submit") {
                    validateAndSubmit()
                }
                .disabled(!isFormValid || isSubmitting)
            )
            .overlay {
                if isSubmitting {
                    ProgressView()
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
        .onChange(of: quantityString) { newValue in
            if let number = Int(newValue) {
                showQuantityError = number <= 0
            }
        }
    }
    
    private func validateAndSubmit() {
        guard quantity > 0 else {
            showQuantityError = true
            return
        }
        
        isSubmitting = true
        
        let request = BookRequest(
            Request_id: UUID(),
            author: author,  // Changed from type to author
            title: title,
            quantity: quantity,
            reason: reason,
            Request_status: .pending,
            createdAt: Date()
        )
        
        Task {
            do {
                try await saveRequestToSupabase(request)
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to submit request: \(error.localizedDescription)"
                    isSubmitting = false
                }
            }
        }
    }
    private func saveRequestToSupabase(_ request: BookRequest) async throws {
        let client = SupabaseManager.shared.client
        try await client
            .from("BookRequest")
            .insert(request)
            .execute()
    }
}
