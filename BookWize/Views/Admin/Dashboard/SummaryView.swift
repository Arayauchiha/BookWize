

import SwiftUI
import Supabase

struct SummaryView: View {
    @Binding var bookRequests: [BookRequest]
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var pendingRequests: [BookRequest] {
        bookRequests.filter { $0.Request_status == .pending }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    ProgressView("Loading requests...")
                        .padding()
                        .tint(Color.customButton)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // Section header for Inventory Requests
                    Text("Inventory Requests")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.customText)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    NavigationLink {
                        AllRequestsView(bookRequests: $bookRequests)
                    } label: {
                        SummaryCard(requestCount: pendingRequests.count)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Summary")
            .background(Color.customBackground)
        }
    }
}

struct SummaryCard: View {
    let requestCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pending Requests")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.customText)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.customButton.opacity(Color.secondaryIconOpacity))
                    .font(.system(size: 14))
            }
            
            Text("\(requestCount)")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(Color.customText)
            
            Text("request\(requestCount == 1 ? "" : "s") to review")
                .font(.system(size: 17))
                .foregroundColor(Color.customText.opacity(Color.secondaryIconOpacity))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.customCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.customText.opacity(0.2), lineWidth: 1)
        )
    }
}

struct AllRequestsView: View {
    @Binding var bookRequests: [BookRequest]
    @State private var selectedSegment = 0 // 0: Pending, 1: Approved, 2: Rejected
    
    var filteredRequests: [BookRequest] {
        switch selectedSegment {
        case 0: return bookRequests.filter { $0.Request_status == .pending }
        case 1: return bookRequests.filter { $0.Request_status == .approved }
        case 2: return bookRequests.filter { $0.Request_status == .rejected }
        default: return []
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Status", selection: $selectedSegment) {
                Text("Pending").tag(0)
                Text("Approved").tag(1)
                Text("Rejected").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .tint(Color.customButton)
            
            if filteredRequests.isEmpty {
                Text("No \(statusTitle) requests found.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.customText.opacity(Color.secondaryIconOpacity))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredRequests) { request in
                            NavigationLink {
                                RequestDetailView(
                                    request: request,
                                    onStatusUpdate: { updatedRequest in
                                        DispatchQueue.main.async {
                                            if let index = bookRequests.firstIndex(where: { $0.id == updatedRequest.id }) {
                                                bookRequests[index] = updatedRequest
                                            }
                                        }
                                    }
                                )
                            } label: {
                                RequestCard(request: request)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle("Requests")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.customBackground)
    }
    
    private var statusTitle: String {
        switch selectedSegment {
        case 0: return "pending"
        case 1: return "approved"
        case 2: return "rejected"
        default: return ""
        }
    }
}

struct RequestCard: View {
    let request: BookRequest

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(request.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.customText)
                    .lineLimit(1)

                Text("Author: \(request.author)")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.customText.opacity(Color.secondaryIconOpacity))

                Text("Quantity: \(request.quantity)")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.customText.opacity(Color.secondaryIconOpacity))
            }
            .padding(.leading, 16)

            Spacer()

            Text(request.Request_status.rawValue.capitalized)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(statusColor(for: request.Request_status))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding(.trailing, 16)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.customCardBackground)
        )
    }

    private func statusColor(for status: BookRequest.R_status) -> Color {
        switch status {
        case .pending:
            return .orange
        case .approved:
            return Color.librarianColor
        case .rejected:
            return .red
        }
    }
}

struct RequestDetailView: View {
    let request: BookRequest
    let onStatusUpdate: (BookRequest) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var showAcceptConfirmation = false
    @State private var showRejectConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Request Details")
                .font(.title)
                .foregroundStyle(Color.customText)
            
            Group {
                DetailRow(title: "Title", value: request.title)
                DetailRow(title: "Author", value: request.author)
                DetailRow(title: "Quantity", value: String(request.quantity))
                DetailRow(title: "Reason", value: request.reason)
                DetailRow(title: "Status", value: request.Request_status.rawValue.capitalized)
                DetailRow(title: "Created At", value: request.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
            .foregroundStyle(Color.customText)
            
            if request.Request_status == .pending {
                HStack(spacing: 20) {
                    Button(action: {
                        showAcceptConfirmation = true
                    }) {
                        Text("Accept")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.librarianColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isUpdating)
                    
                    Button(action: {
                        showRejectConfirmation = true
                    }) {
                        Text("Reject")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isUpdating)
                }
                .padding(.top, 20)
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Request Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.customBackground)
        .overlay {
            if isUpdating {
                ProgressView("Updating status...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .tint(Color.customButton)
            }
        }
        .alert("Confirm Accept", isPresented: $showAcceptConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Accept") {
                Task {
                    await updateStatus(to: .approved)
                }
            }
        } message: {
            Text("Are you sure you want to accept this request for \"\(request.title)\"?")
        }
        .alert("Confirm Reject", isPresented: $showRejectConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reject", role: .destructive) {
                Task {
                    await updateStatus(to: .rejected)
                }
            }
        } message: {
            Text("Are you sure you want to reject this request for \"\(request.title)\"?")
        }
    }
    
    private func updateStatus(to newStatus: BookRequest.R_status) async {
        print("Starting updateStatus for \(request.Request_id) to \(newStatus.rawValue)")
        await MainActor.run {
            isUpdating = true
            errorMessage = nil
        }
        
        do {
            let client = SupabaseManager.shared.client
            let updatedRequest = BookRequest(
                Request_id: request.Request_id,
                author: request.author,
                title: request.title,
                quantity: request.quantity,
                reason: request.reason,
                Request_status: newStatus,
                createdAt: request.createdAt
            )
            
            try await Task.detached(priority: .userInitiated) {
                print("Executing Supabase update for \(request.Request_id)")
                try await client
                    .from("BookRequest")
                    .update(["Request_status": newStatus.rawValue])
                    .eq("Request_id", value: request.Request_id.uuidString)
                    .execute()
                print("Supabase update completed for \(request.Request_id)")
            }.value
            
            await MainActor.run {
                print("Updating UI for \(request.Request_id)")
                onStatusUpdate(updatedRequest)
                isUpdating = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update status: \(error.localizedDescription)"
                isUpdating = false
                print("Update failed for \(request.Request_id): \(error)")
            }
        }
    }
}

#Preview {
    SummaryView(bookRequests: .constant([]))
        .environment(\.colorScheme, .light)
}
