import SwiftUI
import Supabase

struct RequestBookView: View {
    @Environment(\.dismiss) var dismiss
    @State private var author = ""
    @State private var title = ""
    @State private var quantityString = ""
    @State private var reason = ""
    @State private var showQuantityError = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    var quantity: Int {
        return Int(quantityString) ?? 0
    }
    
    var isFormValid: Bool {
        !author.isEmpty && !title.isEmpty && !reason.isEmpty && quantity > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Author", text: $author)
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
                    HapticManager.lightImpact()
                    dismiss()
                },
                trailing: Button("Submit") {
                    HapticManager.mediumImpact()
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
                Button("OK") {
                    HapticManager.lightImpact()
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    HapticManager.success()
                    dismiss()
                }
            } message: {
                Text("Book request submitted successfully!")
            }
        }
        .onChange(of: quantityString) { newValue in
            if let number = Int(newValue) {
                showQuantityError = number <= 0
                if number <= 0 {
                    HapticManager.error()
                } else {
                    HapticManager.success()
                }
            }
        }
    }
    
    private func validateAndSubmit() {
        guard quantity > 0 else {
            showQuantityError = true
            HapticManager.error()
            return
        }
        
        isSubmitting = true
        HapticManager.mediumImpact()
        
        let request = BookRequest(
            Request_id: UUID(),
            author: author,
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
                    HapticManager.success()
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to submit request: \(error.localizedDescription)"
                    HapticManager.error()
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
