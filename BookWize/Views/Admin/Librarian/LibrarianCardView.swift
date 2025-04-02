import SwiftUI

struct LibrarianCardView: View {
    let librarian: LibrarianData
    var onDelete: () -> Void
    @State private var showDetail = false
    
    var body: some View {
        Button(action: {
            showDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(librarian.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
                    
                    Text(librarian.status.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(librarian.status.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(librarian.status.color.opacity(0.15))
                        )
                }
                
                // Contact info
                VStack(alignment: .leading, spacing: 8) {
                    Label(librarian.email, systemImage: "envelope.fill")
//                    Label(formatPhoneNumber(librarian.phone), systemImage: "phone.fill")
                    Text(formatPhoneNumber(librarian.phone))
                }
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                
                // Date added
                Text("Added \(librarian.dateAdded.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            LibrarianDetailView(librarian: librarian, onDelete: {
                showDetail = false
                onDelete()
            })
        }
    }
    
    private func formatPhoneNumber(_ phone: String?) -> String {
        guard let phone = phone else { return "N/A" }
        // Use abs to ensure we don't have negative numbers with hyphens
        return phone // Format without commas and ensure positive
    }
}

struct LibrarianDetailView: View {
    let librarian: LibrarianData
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showSuccessAlert = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile header
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.librarianColor)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(librarian.name.prefix(1).uppercased()))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(spacing: 4) {
                            Text(librarian.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                
                            Text("Librarian")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(librarian.status.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(librarian.status.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(librarian.status.color.opacity(0.15))
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    
                    // Contact information section
                    Text("Contact Information")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        DetailsRow(icon: "envelope", title: "Email", value: librarian.email)
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        DetailsRow(icon: "phone", title: "Phone", value: formatPhoneNumber(librarian.phone))
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        DetailsRow(icon: "person", title: "Age", value: "\(librarian.age ?? 0)")
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    
                    // Account Information section
                    Text("Account Information")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        DetailsRow(icon: "calendar", title: "Added On", value: librarian.dateAdded.formatted(date: .long, time: .shortened))
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        DetailsRow(icon: "circle.fill", title: "Status", value: librarian.status.rawValue.capitalized, valueColor: librarian.status.color)
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    
                    // Delete button
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            if isDeleting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                Text("Delete Librarian")
                                    .font(.system(size: 17, weight: .regular))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isDeleting)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Librarian Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Delete Librarian", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteLibrarian()
                }
            } message: {
                Text("Are you sure you want to delete \(librarian.name)? This action cannot be undone.")
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                    onDelete()
                }
            } message: {
                Text("Librarian \(librarian.name) has been deleted successfully.")
            }
        }
    }
    
    private func formatPhoneNumber(_ phone: String?) -> String {
        guard let phone = phone else { return "N/A" }
        return phone
    }
    
    private func deleteLibrarian() {
        isDeleting = true
        
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("Users")
                    .delete()
                    .eq("email", value: librarian.email)
                    .execute()
                
                await MainActor.run {
                    isDeleting = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = "Failed to delete librarian: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct DetailsRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .frame(width: 28, height: 28)
                .padding(.leading, 16)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(valueColor)
                .padding(.trailing, 16)
        }
        .padding(.vertical, 12)
    }
}
