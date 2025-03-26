

import SwiftUI
import Supabase


struct SummaryView: View {
    @State private var bookRequests: [BookRequest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedRequest: BookRequest? // For navigating to detail view

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading requests...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if bookRequests.isEmpty {
                    Text("No book requests found.")
                        .font(.title2)
                        .foregroundStyle(Color.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(bookRequests) { request in
                        NavigationLink(
                            destination: RequestDetailView(
                                request: request,
                                onStatusUpdate: { updatedRequest in
                                    // Update the local list when the status changes
                                    if let index = bookRequests.firstIndex(where: { $0.id == updatedRequest.id }) {
                                        bookRequests[index] = updatedRequest
                                    }
                                }
                            ),
                            tag: request,
                            selection: $selectedRequest
                        ) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(request.title)
                                        .font(.headline)
                                        .foregroundStyle(Color.black)
                                    Text("Author: \(request.author)")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                    Text("Quantity: \(request.quantity)")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                }
                                Spacer()
                                // Display the status
                                Text(request.Request_status.rawValue.capitalized)
                                    .font(.caption)
                                    .padding(5)
                                    .background(statusColor(for: request.Request_status))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                // Removed the "View Detail" button
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Book Requests")
            .task {
                await fetchBookRequests()
            }
        }
    }

    private func fetchBookRequests() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let client = SupabaseManager.shared.client
            let response: [BookRequest] = try await client
                .from("BookRequest")
                .select()
                .execute()
                .value
            bookRequests = response.sorted { $0.createdAt > $1.createdAt } // Sort by creation date (newest first)
        } catch {
            errorMessage = "Failed to load requests: \(error.localizedDescription)"
        }
    }

    private func statusColor(for status: BookRequest.R_status) -> Color {
        switch status {
        case .pending:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        }
    }
}

struct RequestDetailView: View {
    let request: BookRequest
    let onStatusUpdate: (BookRequest) -> Void
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Request Details")
                .font(.title)
                .foregroundStyle(Color.black)

            // Display request details (non-editable) using the existing DetailRow
            Group {
                DetailRow(title: "Title", value: request.title)
                DetailRow(title: "Author", value: request.author)
                DetailRow(title: "Quantity", value: String(request.quantity))
                DetailRow(title: "Reason", value: request.reason)
                DetailRow(title: "Status", value: request.Request_status.rawValue.capitalized)
                DetailRow(title: "Created At", value: request.createdAt.formatted(date: .abbreviated, time: .shortened))
            }

            // Show Accept/Reject buttons only if the status is pending
            if request.Request_status == .pending {
                HStack(spacing: 20) {
                    Button(action: {
                        updateStatus(to: .approved)
                    }) {
                        Text("Accept")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isUpdating)

                    Button(action: {
                        updateStatus(to: .rejected)
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
        .navigationBarItems(leading: Button("Back") { dismiss() })
        .overlay {
            if isUpdating {
                ProgressView("Updating status...")
            }
        }
    }

    private func updateStatus(to newStatus: BookRequest.R_status) {
        isUpdating = true
        errorMessage = nil

        Task {
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

                // Update the status in Supabase
                try await client
                    .from("BookRequest")
                    .update(["Request_status": newStatus.rawValue])
                    .eq("Request_id", value: request.Request_id.uuidString)
                    .execute()

                // Notify the parent view of the updated request
                await MainActor.run {
                    onStatusUpdate(updatedRequest)
                    isUpdating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update status: \(error.localizedDescription)"
                    isUpdating = false
                }
            }
        }
    }
}

#Preview {
    SummaryView()
        .environment(\.colorScheme, .light)
}
