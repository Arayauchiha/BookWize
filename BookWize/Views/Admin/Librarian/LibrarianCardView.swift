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
                        .foregroundStyle(Color.customText)
                    
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
                .foregroundStyle(Color.customText.opacity(0.6))
                
                // Date added
                Text("Added \(librarian.dateAdded.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.customText.opacity(0.4))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.customCardBackground)
            )
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
    @State private var isDeleting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Profile header
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.librarianColor)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Text(String(librarian.name.prefix(1).uppercased()))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(librarian.name)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            HStack {
                                Text("Librarian")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
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
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    // Contact information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact Information")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Label("Email", systemImage: "envelope")
                                    .frame(width: 100, alignment: .leading)
                                
                                Text(librarian.email)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Label("Phone", systemImage: "phone")
                                    .frame(width: 100, alignment: .leading)
                                
                                Text(formatPhoneNumber(librarian.phone))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Label("Age", systemImage: "person")
                                    .frame(width: 100, alignment: .leading)
                                
                                Text("\(librarian.age ?? 0)")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    // Account Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account Information")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Label("Added On", systemImage: "calendar")
                                    .frame(width: 100, alignment: .leading)
                                
                                Text(librarian.dateAdded.formatted(date: .long, time: .shortened))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Label("Status", systemImage: "circle.fill")
                                    .frame(width: 100, alignment: .leading)
                                
                                Text(librarian.status.rawValue.capitalized)
                                    .foregroundColor(librarian.status.color)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 30)
                    
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
                                Text("Delete Librarian")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(isDeleting)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
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
        }
    }
    
    private func deleteLibrarian() {
        isDeleting = true
        errorMessage = nil
        
        Task {
            do {
                // Delete the librarian from Supabase
                try await SupabaseManager.shared.client.database
                    .from("Users")
                    .delete()
                    .eq("email", value: librarian.email)
                    .execute()
                
                await MainActor.run {
                    isDeleting = false
                    onDelete()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = "Failed to delete: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func formatPhoneNumber(_ phone: String?) -> String {
        guard let phone = phone else { return "N/A" }
        // Use abs to ensure we don't have negative numbers with hyphens
        return phone // Format without commas and ensure positive
    }
}

