//
//import SwiftUI
//import Supabase
//
//struct SummaryView: View {
//    @Binding var bookRequests: [BookRequest]
//    @State private var isLoading = false
//    @State private var errorMessage: String?
//
//    var pendingRequests: [BookRequest] {
//        bookRequests.filter { $0.Request_status == .pending }
//    }
//
//    var body: some View {
//        NavigationStack {
//            VStack(alignment: .leading, spacing: 10) {
//                if isLoading {
//                    ProgressView("Loading requests...")
//                        .padding()
//                } else if let errorMessage = errorMessage {
//                    Text(errorMessage)
//                        .foregroundColor(.red)
//                        .padding()
//                } else if pendingRequests.isEmpty {
//                    Text("No pending requests found.")
//                        .font(.title2)
//                        .foregroundStyle(Color.gray)
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                } else {
//                    NavigationLink {
//                        AllPendingRequestsView(
//                            pendingRequests: pendingRequests,
//                            bookRequests: $bookRequests
//                        )
//                    } label: {
//                        SummaryCard(requestCount: pendingRequests.count)
//                            .padding(.horizontal)
//                    }
//                    Spacer()
//                }
//            }
//            .navigationTitle("Summary")
//        }
//    }
//}
//
//struct SummaryCard: View {
//    let requestCount: Int
//
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color.white)
//                .shadow(radius: 2)
//
//            HStack {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Pending Requests")
//                        .font(.headline)
//                        .foregroundStyle(Color.black)
//
//                    Text("You have \(requestCount) pending request\(requestCount == 1 ? "" : "s") to review.")
//                        .font(.subheadline)
//                        .foregroundStyle(Color.black.opacity(0.8))
//                        .lineLimit(2)
//                }
//                .padding(.leading, 15)
//                .padding(.vertical, 15)
//
//                Spacer()
//
//                Image(systemName: "chevron.right")
//                    .foregroundColor(.green)
//                    .font(.system(size: 16, weight: .bold))
//                    .padding(.trailing, 15)
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: 100)
//    }
//}
//
//struct AllPendingRequestsView: View {
//    let pendingRequests: [BookRequest]
//    @Binding var bookRequests: [BookRequest]
//    @State private var showHistory = false
//
//    var historyRequests: [BookRequest] {
//        bookRequests.filter { $0.Request_status != .pending }
//    }
//
//    var body: some View {
//        VStack {
//            if pendingRequests.isEmpty {
//                Text("No pending requests found.")
//                    .font(.title2)
//                    .foregroundStyle(Color.gray)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else {
//                ScrollView {
//                    LazyVStack(spacing: 10) {
//                        ForEach(pendingRequests) { request in
//                            NavigationLink {
//                                RequestDetailView(
//                                    request: request,
//                                    onStatusUpdate: { updatedRequest in
//                                        DispatchQueue.main.async {
//                                            if let index = bookRequests.firstIndex(where: { $0.id == updatedRequest.id }) {
//                                                bookRequests[index] = updatedRequest
//                                            }
//                                        }
//                                    }
//                                )
//                            } label: {
//                                RequestCard(request: request)
//                            }
//                        }
//                    }
//                    .padding()
//                }
//            }
//        }
//        .navigationTitle("Pending Requests")
//        .navigationBarTitleDisplayMode(.large)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button(action: {
//                    print("Show History")
//                    showHistory = true
//                }) {
//                    Image(systemName: "clock.arrow.circlepath")
//                        .font(.system(size: 20))
//                        .foregroundColor(.blue)
//                }
//            }
//        }
//        .sheet(isPresented: $showHistory) {
//            NavigationStack {
//                HistoryView(historyRequests: historyRequests)
//                    .navigationTitle("Request History")
//                    .navigationBarTitleDisplayMode(.inline)
//                    .toolbar {
//                        ToolbarItem(placement: .navigationBarTrailing) {
//                            Button("Done") {
//                                print("Dismiss History")
//                                showHistory = false
//                            }
//                        }
//                    }
//            }
//        }
//    }
//}
//
//struct RequestCard: View {
//    let request: BookRequest
//
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 8) {
//                Text(request.title)
//                    .font(Font.headline)
//                    .foregroundStyle(Color.black)
//                    .lineLimit(1)
//
//                Text("Author: \(request.author)")
//                    .font(Font.subheadline)
//                    .foregroundStyle(.gray)
//
//                Text("Quantity: \(request.quantity)")
//                    .font(Font.subheadline)
//                    .foregroundStyle(.gray)
//            }
//            .padding(.leading, 15)
//
//            Spacer()
//
//            Text(request.Request_status.rawValue.capitalized)
//                .font(Font.caption)
//                .padding(8)
//                .background(statusColor(for: request.Request_status))
//                .foregroundColor(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 5))
//                .padding(.trailing, 15)
//        }
//        .padding(.vertical, 15)
//        .background(
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color.white)
//                .shadow(radius: 3, x: 0, y: 2)
//        )
//    }
//
//    private func statusColor(for status: BookRequest.R_status) -> Color {
//        switch status {
//        case .pending:
//            return .orange
//        case .approved:
//            return .green
//        case .rejected:
//            return .red
//        }
//    }
//}
//
//struct RequestDetailView: View {
//    let request: BookRequest
//    let onStatusUpdate: (BookRequest) -> Void
//    @State private var isUpdating = false
//    @State private var errorMessage: String?
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            Text("Request Details")
//                .font(.title)
//                .foregroundStyle(Color.black)
//
//            Group {
//                DetailRow(title: "Title", value: request.title)
//                DetailRow(title: "Author", value: request.author)
//                DetailRow(title: "Quantity", value: String(request.quantity))
//                DetailRow(title: "Reason", value: request.reason)
//                DetailRow(title: "Status", value: request.Request_status.rawValue.capitalized)
//                DetailRow(title: "Created At", value: request.createdAt.formatted(date: .abbreviated, time: .shortened))
//            }
//
//            if request.Request_status == .pending {
//                HStack(spacing: 20) {
//                    Button(action: {
//                        print("Accept tapped for \(request.Request_id)")
//                        Task {
//                            await updateStatus(to: .approved)
//                        }
//                    }) {
//                        Text("Accept")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.green)
//                            .foregroundColor(.white)
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                    }
//                    .disabled(isUpdating)
//
//                    Button(action: {
//                        print("Reject tapped for \(request.Request_id)")
//                        Task {
//                            await updateStatus(to: .rejected)
//                        }
//                    }) {
//                        Text("Reject")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.red)
//                            .foregroundColor(.white)
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                    }
//                    .disabled(isUpdating)
//                }
//                .padding(.top, 20)
//            }
//
//            if let errorMessage = errorMessage {
//                Text(errorMessage)
//                    .foregroundColor(.red)
//                    .padding(.top, 10)
//            }
//
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Request Details")
//        .navigationBarTitleDisplayMode(.inline)
//        .overlay {
//            if isUpdating {
//                ProgressView("Updating status...")
//                    .progressViewStyle(CircularProgressViewStyle())
//            }
//        }
//    }
//
//    private func updateStatus(to newStatus: BookRequest.R_status) async {
//        print("Starting updateStatus for \(request.Request_id) to \(newStatus.rawValue)")
//        await MainActor.run {
//            isUpdating = true
//            errorMessage = nil
//        }
//
//        do {
//            let client = SupabaseManager.shared.client
//            let updatedRequest = BookRequest(
//                Request_id: request.Request_id,
//                author: request.author,
//                title: request.title,
//                quantity: request.quantity,
//                reason: request.reason,
//                Request_status: newStatus,
//                createdAt: request.createdAt
//            )
//
//            try await Task.detached(priority: .userInitiated) {
//                print("Executing Supabase update for \(request.Request_id)")
//                try await client
//                    .from("BookRequest")
//                    .update(["Request_status": newStatus.rawValue])
//                    .eq("Request_id", value: request.Request_id.uuidString)
//                    .execute()
//                print("Supabase update completed for \(request.Request_id)")
//            }.value
//
//            await MainActor.run {
//                print("Updating UI for \(request.Request_id)")
//                onStatusUpdate(updatedRequest)
//                isUpdating = false
//            }
//        } catch {
//            await MainActor.run {
//                errorMessage = "Failed to update status: \(error.localizedDescription)"
//                isUpdating = false
//                print("Update failed for \(request.Request_id): \(error)")
//            }
//        }
//    }
//}
//
//struct HistoryView: View {
//    let historyRequests: [BookRequest]
//
//    var body: some View {
//        VStack {
//            if historyRequests.isEmpty {
//                Text("No history available.")
//                    .font(.title2)
//                    .foregroundStyle(Color.gray)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else {
//                ScrollView {
//                    LazyVStack(spacing: 10) {
//                        ForEach(historyRequests) { request in
//                            NavigationLink {
//                                HistoryDetailView(request: request)
//                            } label: {
//                                HistoryCard(request: request)
//                            }
//                        }
//                    }
//                    .padding()
//                }
//            }
//        }
//    }
//}
//
//struct HistoryCard: View {
//    let request: BookRequest
//
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 5) {
//                Text(request.title)
//                    .font(.headline)
//                    .foregroundStyle(Color.black)
//                Text("Author: \(request.author)")
//                    .font(.subheadline)
//                    .foregroundStyle(.gray)
//                Text("Quantity: \(request.quantity)")
//                    .font(.subheadline)
//                    .foregroundStyle(.gray)
//            }
//            Spacer()
//            Text(request.Request_status.rawValue.capitalized)
//                .font(.caption)
//                .padding(5)
//                .background(statusColor(for: request.Request_status))
//                .foregroundColor(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 5))
//        }
//        .padding(.vertical, 5)
//        .padding(.horizontal)
//        .background(
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color.white)
//                .shadow(radius: 3)
//        )
//    }
//
//    private func statusColor(for status: BookRequest.R_status) -> Color {
//        switch status {
//        case .pending:
//            return .orange
//        case .approved:
//            return .green
//        case .rejected:
//            return .red
//        }
//    }
//}
//
//struct HistoryDetailView: View {
//    let request: BookRequest
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            Text("Request Details")
//                .font(.title)
//                .foregroundStyle(Color.black)
//
//            Group {
//                DetailRow(title: "Title", value: request.title)
//                DetailRow(title: "Author", value: request.author)
//                DetailRow(title: "Quantity", value: String(request.quantity))
//                DetailRow(title: "Reason", value: request.reason)
//                DetailRow(title: "Status", value: request.Request_status.rawValue.capitalized)
//                DetailRow(title: "Created At", value: request.createdAt.formatted(date: .abbreviated, time: .shortened))
//            }
//
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Request Details")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
//
//#Preview {
//    SummaryView(bookRequests: .constant([]))
//        .environment(\.colorScheme, .light)
//}






















// MARK: show details format

//import SwiftUI
//import Supabase
//
//struct SummaryView: View {
//    @Binding var bookRequests: [BookRequest]
//    @State private var isLoading = false
//    @State private var errorMessage: String?
//
//    var pendingRequests: [BookRequest] {
//        bookRequests.filter { $0.Request_status == .pending }
//    }
//
//    var body: some View {
//        NavigationStack {
//            VStack(alignment: .leading, spacing: 10) {
//                if isLoading {
//                    ProgressView("Loading requests...")
//                        .padding()
//                } else if let errorMessage = errorMessage {
//                    Text(errorMessage)
//                        .foregroundColor(.red)
//                        .padding()
//                } else if pendingRequests.isEmpty {
//                    Text("No pending requests found.")
//                        .font(.title2)
//                        .foregroundStyle(Color.gray)
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                } else {
//                    NavigationLink {
//                        AllPendingRequestsView(
//                            pendingRequests: pendingRequests,
//                            bookRequests: $bookRequests
//                        )
//                    } label: {
//                        SummaryCard(requestCount: pendingRequests.count)
//                            .padding(.horizontal)
//                    }
//                    Spacer()
//                }
//            }
//            .navigationTitle("Summary")
//        }
//    }
//}
//
//struct SummaryCard: View {
//    let requestCount: Int
//
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color.white)
//                .shadow(radius: 2)
//
//            HStack {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Pending Requests")
//                        .font(.headline)
//                        .foregroundStyle(Color.black)
//
//                    Text("You have \(requestCount) pending request\(requestCount == 1 ? "" : "s") to review.")
//                        .font(.subheadline)
//                        .foregroundStyle(Color.black.opacity(0.8))
//                        .lineLimit(2)
//                }
//                .padding(.leading, 15)
//                .padding(.vertical, 15)
//
//                Spacer()
//
//                Image(systemName: "chevron.right")
//                    .foregroundColor(.green)
//                    .font(.system(size: 16, weight: .bold))
//                    .padding(.trailing, 15)
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: 100)
//    }
//}
//
//struct AllPendingRequestsView: View {
//    let pendingRequests: [BookRequest]
//    @Binding var bookRequests: [BookRequest]
//    @State private var showHistory = false
//
//    var historyRequests: [BookRequest] {
//        bookRequests.filter { $0.Request_status != .pending }
//    }
//
//    var body: some View {
//        VStack {
//            if pendingRequests.isEmpty {
//                Text("No pending requests found.")
//                    .font(.title2)
//                    .foregroundStyle(Color.gray)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else {
//                ScrollView {
//                    LazyVStack(spacing: 10) {
//                        ForEach(pendingRequests) { request in
//                            NavigationLink {
//                                RequestDetailView(
//                                    request: request,
//                                    onStatusUpdate: { updatedRequest in
//                                        DispatchQueue.main.async {
//                                            if let index = bookRequests.firstIndex(where: { $0.id == updatedRequest.id }) {
//                                                bookRequests[index] = updatedRequest
//                                            }
//                                        }
//                                    }
//                                )
//                            } label: {
//                                RequestCard(request: request)
//                            }
//                        }
//                    }
//                    .padding()
//                }
//            }
//        }
//        .navigationTitle("Pending Requests")
//        .navigationBarTitleDisplayMode(.large)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                NavigationLink {
//                    HistoryView(historyRequests: historyRequests)
//                } label: {
//                    Image(systemName: "clock.arrow.circlepath")
//                        .font(.system(size: 20))
//                        .foregroundColor(.blue)
//                }
//            }
//        }
//    }
//}
//
//struct RequestCard: View {
//    let request: BookRequest
//
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 8) {
//                Text(request.title)
//                    .font(Font.headline)
//                    .foregroundStyle(Color.black)
//                    .lineLimit(1)
//
//                Text("Author: \(request.author)")
//                    .font(Font.subheadline)
//                    .foregroundStyle(.gray)
//
//                Text("Quantity: \(request.quantity)")
//                    .font(Font.subheadline)
//                    .foregroundStyle(.gray)
//            }
//            .padding(.leading, 15)
//
//            Spacer()
//
//            Text(request.Request_status.rawValue.capitalized)
//                .font(Font.caption)
//                .padding(8)
//                .background(statusColor(for: request.Request_status))
//                .foregroundColor(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 5))
//                .padding(.trailing, 15)
//        }
//        .padding(.vertical, 15)
//        .background(
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color.white)
//                .shadow(radius: 3, x: 0, y: 2)
//        )
//    }
//
//    private func statusColor(for status: BookRequest.R_status) -> Color {
//        switch status {
//        case .pending:
//            return .orange
//        case .approved:
//            return .green
//        case .rejected:
//            return .red
//        }
//    }
//}
//
//struct RequestDetailView: View {
//    let request: BookRequest
//    let onStatusUpdate: (BookRequest) -> Void
//    @State private var isUpdating = false
//    @State private var errorMessage: String?
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            Text("Request Details")
//                .font(.title)
//                .foregroundStyle(Color.black)
//
//            Group {
//                DetailRow(title: "Title", value: request.title)
//                DetailRow(title: "Author", value: request.author)
//                DetailRow(title: "Quantity", value: String(request.quantity))
//                DetailRow(title: "Reason", value: request.reason)
//                DetailRow(title: "Status", value: request.Request_status.rawValue.capitalized)
//                DetailRow(title: "Created At", value: request.createdAt.formatted(date: .abbreviated, time: .shortened))
//            }
//
//            if request.Request_status == .pending {
//                HStack(spacing: 20) {
//                    Button(action: {
//                        print("Accept tapped for \(request.Request_id)")
//                        Task {
//                            await updateStatus(to: .approved)
//                        }
//                    }) {
//                        Text("Accept")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.green)
//                            .foregroundColor(.white)
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                    }
//                    .disabled(isUpdating)
//
//                    Button(action: {
//                        print("Reject tapped for \(request.Request_id)")
//                        Task {
//                            await updateStatus(to: .rejected)
//                        }
//                    }) {
//                        Text("Reject")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.red)
//                            .foregroundColor(.white)
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                    }
//                    .disabled(isUpdating)
//                }
//                .padding(.top, 20)
//            }
//
//            if let errorMessage = errorMessage {
//                Text(errorMessage)
//                    .foregroundColor(.red)
//                    .padding(.top, 10)
//            }
//
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Request Details")
//        .navigationBarTitleDisplayMode(.inline)
//        .overlay {
//            if isUpdating {
//                ProgressView("Updating status...")
//                    .progressViewStyle(CircularProgressViewStyle())
//            }
//        }
//    }
//
//    private func updateStatus(to newStatus: BookRequest.R_status) async {
//        print("Starting updateStatus for \(request.Request_id) to \(newStatus.rawValue)")
//        await MainActor.run {
//            isUpdating = true
//            errorMessage = nil
//        }
//
//        do {
//            let client = SupabaseManager.shared.client
//            let updatedRequest = BookRequest(
//                Request_id: request.Request_id,
//                author: request.author,
//                title: request.title,
//                quantity: request.quantity,
//                reason: request.reason,
//                Request_status: newStatus,
//                createdAt: request.createdAt
//            )
//
//            try await Task.detached(priority: .userInitiated) {
//                print("Executing Supabase update for \(request.Request_id)")
//                try await client
//                    .from("BookRequest")
//                    .update(["Request_status": newStatus.rawValue])
//                    .eq("Request_id", value: request.Request_id.uuidString)
//                    .execute()
//                print("Supabase update completed for \(request.Request_id)")
//            }.value
//
//            await MainActor.run {
//                print("Updating UI for \(request.Request_id)")
//                onStatusUpdate(updatedRequest)
//                isUpdating = false
//            }
//        } catch {
//            await MainActor.run {
//                errorMessage = "Failed to update status: \(error.localizedDescription)"
//                isUpdating = false
//                print("Update failed for \(request.Request_id): \(error)")
//            }
//        }
//    }
//}
//
//struct HistoryView: View {
//    let historyRequests: [BookRequest]
//
//    var body: some View {
//        VStack {
//            if historyRequests.isEmpty {
//                Text("No history available.")
//                    .font(.title2)
//                    .foregroundStyle(Color.gray)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else {
//                ScrollView {
//                    LazyVStack(spacing: 10) {
//                        ForEach(historyRequests) { request in
//                            NavigationLink {
//                                HistoryDetailView(request: request)
//                            } label: {
//                                HistoryCard(request: request)
//                            }
//                        }
//                    }
//                    .padding()
//                }
//            }
//        }
//        .navigationTitle("Request History")
//        .navigationBarTitleDisplayMode(.large)
//    }
//}
//
//struct HistoryCard: View {
//    let request: BookRequest
//
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 5) {
//                Text(request.title)
//                    .font(.headline)
//                    .foregroundStyle(Color.black)
//                Text("Author: \(request.author)")
//                    .font(.subheadline)
//                    .foregroundStyle(.gray)
//                Text("Quantity: \(request.quantity)")
//                    .font(.subheadline)
//                    .foregroundStyle(.gray)
//            }
//            Spacer()
//            Text(request.Request_status.rawValue.capitalized)
//                .font(.caption)
//                .padding(5)
//                .background(statusColor(for: request.Request_status))
//                .foregroundColor(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 5))
//        }
//        .padding(.vertical, 5)
//        .padding(.horizontal)
//        .background(
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color.white)
//                .shadow(radius: 3)
//        )
//    }
//
//    private func statusColor(for status: BookRequest.R_status) -> Color {
//        switch status {
//        case .pending:
//            return .orange
//        case .approved:
//            return .green
//        case .rejected:
//            return .red
//        }
//    }
//}
//
//struct HistoryDetailView: View {
//    let request: BookRequest
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            Text("Request Details")
//                .font(.title)
//                .foregroundStyle(Color.black)
//
//            Group {
//                DetailRow(title: "Title", value: request.title)
//                DetailRow(title: "Author", value: request.author)
//                DetailRow(title: "Quantity", value: String(request.quantity))
//                DetailRow(title: "Reason", value: request.reason)
//                DetailRow(title: "Status", value: request.Request_status.rawValue.capitalized)
//                DetailRow(title: "Created At", value: request.createdAt.formatted(date: .abbreviated, time: .shortened))
//            }
//
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Request Details")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
//
//#Preview {
//    SummaryView(bookRequests: .constant([]))
//        .environment(\.colorScheme, .light)
//}


























//MARK: PResent modally
//
//import SwiftUI
//import Supabase
//
//struct SummaryView: View {
//    @Binding var bookRequests: [BookRequest]
//    @State private var isLoading = false
//    @State private var errorMessage: String?
//
//    var pendingRequests: [BookRequest] {
//        bookRequests.filter { $0.Request_status == .pending }
//    }
//
//    var body: some View {
//        NavigationStack {
//            VStack(alignment: .leading, spacing: 10) {
//                if isLoading {
//                    ProgressView("Loading requests...")
//                        .padding()
//                } else if let errorMessage = errorMessage {
//                    Text(errorMessage)
//                        .foregroundColor(.red)
//                        .padding()
//                } else if pendingRequests.isEmpty {
//                    Text("No pending requests found.")
//                        .font(.title2)
//                        .foregroundStyle(Color.gray)
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                } else {
//                    NavigationLink {
//                        AllPendingRequestsView(
//                            pendingRequests: pendingRequests,
//                            bookRequests: $bookRequests
//                        )
//                    } label: {
//                        SummaryCard(requestCount: pendingRequests.count)
//                            .padding(.horizontal)
//                    }
//                    Spacer()
//                }
//            }
//            .navigationTitle("Summary")
//        }
//    }
//}
//
//struct SummaryCard: View {
//    let requestCount: Int
//
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color.white)
//                .shadow(radius: 2)
//
//            HStack {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Pending Requests")
//                        .font(.headline)
//                        .foregroundStyle(Color.black)
//
//                    Text("You have \(requestCount) pending request\(requestCount == 1 ? "" : "s") to review.")
//                        .font(.subheadline)
//                        .foregroundStyle(Color.black.opacity(0.8))
//                        .lineLimit(2)
//                }
//                .padding(.leading, 15)
//                .padding(.vertical, 15)
//
//                Spacer()
//
//                Image(systemName: "chevron.right")
//                    .foregroundColor(.green)
//                    .font(.system(size: 16, weight: .bold))
//                    .padding(.trailing, 15)
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: 100)
//    }
//}
//
//struct AllPendingRequestsView: View {
//    let pendingRequests: [BookRequest]
//    @Binding var bookRequests: [BookRequest]
//    @State private var showHistory = false
//
//    var historyRequests: [BookRequest] {
//        bookRequests.filter { $0.Request_status != .pending }
//    }
//
//    var body: some View {
//        VStack {
//            if pendingRequests.isEmpty {
//                Text("No pending requests found.")
//                    .font(.title2)
//                    .foregroundStyle(Color.gray)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else {
//                ScrollView {
//                    LazyVStack(spacing: 10) {
//                        ForEach(pendingRequests) { request in
//                            NavigationLink {
//                                RequestDetailView(
//                                    request: request,
//                                    onStatusUpdate: { updatedRequest in
//                                        DispatchQueue.main.async {
//                                            if let index = bookRequests.firstIndex(where: { $0.id == updatedRequest.id }) {
//                                                bookRequests[index] = updatedRequest
//                                            }
//                                        }
//                                    }
//                                )
//                            } label: {
//                                RequestCard(request: request)
//                            }
//                        }
//                    }
//                    .padding()
//                }
//            }
//        }
//        .navigationTitle("Pending Requests")
//        .navigationBarTitleDisplayMode(.large)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button(action: {
//                    print("Show History")
//                    showHistory = true
//                }) {
//                    Image(systemName: "clock.arrow.circlepath")
//                        .font(.system(size: 20))
//                        .foregroundColor(.blue)
//                }
//            }
//        }
//        .sheet(isPresented: $showHistory) {
//            NavigationStack {
//                HistoryView(historyRequests: historyRequests)
//                    .navigationTitle("Request History")
//                    .navigationBarTitleDisplayMode(.inline)
//                    .toolbar {
//                        ToolbarItem(placement: .navigationBarTrailing) {
//                            Button("Done") {
//                                print("Dismiss History")
//                                showHistory = false
//                            }
//                        }
//                    }
//            }
//        }
//    }
//}
//
//struct RequestCard: View {
//    let request: BookRequest
//
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 8) {
//                Text(request.title)
//                    .font(Font.headline)
//                    .foregroundStyle(Color.black)
//                    .lineLimit(1)
//
//                Text("Author: \(request.author)")
//                    .font(Font.subheadline)
//                    .foregroundStyle(.gray)
//
//                Text("Quantity: \(request.quantity)")
//                    .font(Font.subheadline)
//                    .foregroundStyle(.gray)
//            }
//            .padding(.leading, 15)
//
//            Spacer()
//
//            Text(request.Request_status.rawValue.capitalized)
//                .font(Font.caption)
//                .padding(8)
//                .background(statusColor(for: request.Request_status))
//                .foregroundColor(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 5))
//                .padding(.trailing, 15)
//        }
//        .padding(.vertical, 15)
//        .background(
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color.white)
//                .shadow(radius: 3, x: 0, y: 2)
//        )
//    }
//
//    private func statusColor(for status: BookRequest.R_status) -> Color {
//        switch status {
//        case .pending:
//            return .orange
//        case .approved:
//            return .green
//        case .rejected:
//            return .red
//        }
//    }
//}
//
//struct RequestDetailView: View {
//    let request: BookRequest
//    let onStatusUpdate: (BookRequest) -> Void
//    @State private var isUpdating = false
//    @State private var errorMessage: String?
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            Text("Request Details")
//                .font(.title)
//                .foregroundStyle(Color.black)
//
//            Group {
//                DetailRow(title: "Title", value: request.title)
//                DetailRow(title: "Author", value: request.author)
//                DetailRow(title: "Quantity", value: String(request.quantity))
//                DetailRow(title: "Reason", value: request.reason)
//                DetailRow(title: "Status", value: request.Request_status.rawValue.capitalized)
//                DetailRow(title: "Created At", value: request.createdAt.formatted(date: .abbreviated, time: .shortened))
//            }
//
//            if request.Request_status == .pending {
//                HStack(spacing: 20) {
//                    Button(action: {
//                        print("Accept tapped for \(request.Request_id)")
//                        Task {
//                            await updateStatus(to: .approved)
//                        }
//                    }) {
//                        Text("Accept")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.green)
//                            .foregroundColor(.white)
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                    }
//                    .disabled(isUpdating)
//
//                    Button(action: {
//                        print("Reject tapped for \(request.Request_id)")
//                        Task {
//                            await updateStatus(to: .rejected)
//                        }
//                    }) {
//                        Text("Reject")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.red)
//                            .foregroundColor(.white)
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                    }
//                    .disabled(isUpdating)
//                }
//                .padding(.top, 20)
//            }
//
//            if let errorMessage = errorMessage {
//                Text(errorMessage)
//                    .foregroundColor(.red)
//                    .padding(.top, 10)
//            }
//
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Request Details")
//        .navigationBarTitleDisplayMode(.inline)
//        .overlay {
//            if isUpdating {
//                ProgressView("Updating status...")
//                    .progressViewStyle(CircularProgressViewStyle())
//            }
//        }
//    }
//
//    private func updateStatus(to newStatus: BookRequest.R_status) async {
//        print("Starting updateStatus for \(request.Request_id) to \(newStatus.rawValue)")
//        await MainActor.run {
//            isUpdating = true
//            errorMessage = nil
//        }
//
//        do {
//            let client = SupabaseManager.shared.client
//            let updatedRequest = BookRequest(
//                Request_id: request.Request_id,
//                author: request.author,
//                title: request.title,
//                quantity: request.quantity,
//                reason: request.reason,
//                Request_status: newStatus,
//                createdAt: request.createdAt
//            )
//
//            try await Task.detached(priority: .userInitiated) {
//                print("Executing Supabase update for \(request.Request_id)")
//                try await client
//                    .from("BookRequest")
//                    .update(["Request_status": newStatus.rawValue])
//                    .eq("Request_id", value: request.Request_id.uuidString)
//                    .execute()
//                print("Supabase update completed for \(request.Request_id)")
//            }.value
//
//            await MainActor.run {
//                print("Updating UI for \(request.Request_id)")
//                onStatusUpdate(updatedRequest)
//                isUpdating = false
//            }
//        } catch {
//            await MainActor.run {
//                errorMessage = "Failed to update status: \(error.localizedDescription)"
//                isUpdating = false
//                print("Update failed for \(request.Request_id): \(error)")
//            }
//        }
//    }
//}
//
//struct HistoryView: View {
//    let historyRequests: [BookRequest]
//
//    var body: some View {
//        VStack {
//            if historyRequests.isEmpty {
//                Text("No history available.")
//                    .font(.title2)
//                    .foregroundStyle(Color.gray)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else {
//                ScrollView {
//                    LazyVStack(spacing: 10) {
//                        ForEach(historyRequests) { request in
//                            NavigationLink {
//                                HistoryDetailView(request: request)
//                            } label: {
//                                HistoryCard(request: request)
//                            }
//                        }
//                    }
//                    .padding()
//                }
//            }
//        }
//    }
//}
//
//struct HistoryCard: View {
//    let request: BookRequest
//
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 5) {
//                Text(request.title)
//                    .font(.headline)
//                    .foregroundStyle(Color.black)
//                Text("Author: \(request.author)")
//                    .font(.subheadline)
//                    .foregroundStyle(.gray)
//                Text("Quantity: \(request.quantity)")
//                    .font(.subheadline)
//                    .foregroundStyle(.gray)
//            }
//            Spacer()
//            Text(request.Request_status.rawValue.capitalized)
//                .font(.caption)
//                .padding(5)
//                .background(statusColor(for: request.Request_status))
//                .foregroundColor(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 5))
//        }
//        .padding(.vertical, 5)
//        .padding(.horizontal)
//        .background(
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color.white)
//                .shadow(radius: 3)
//        )
//    }
//
//    private func statusColor(for status: BookRequest.R_status) -> Color {
//        switch status {
//        case .pending:
//            return .orange
//        case .approved:
//            return .green
//        case .rejected:
//            return .red
//        }
//    }
//}
//
//struct HistoryDetailView: View {
//    let request: BookRequest
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            Text("Request Details")
//                .font(.title)
//                .foregroundStyle(Color.black)
//
//            Group {
//                DetailRow(title: "Title", value: request.title)
//                DetailRow(title: "Author", value: request.author)
//                DetailRow(title: "Quantity", value: String(request.quantity))
//                DetailRow(title: "Reason", value: request.reason)
//                DetailRow(title: "Status", value: request.Request_status.rawValue.capitalized)
//                DetailRow(title: "Created At", value: request.createdAt.formatted(date: .abbreviated, time: .shortened))
//            }
//
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Request Details")
//        .navigationBarTitleDisplayMode(.inline)
//        .navigationBarBackButtonHidden(true) // Hide the back button
//    }
//}
//
//#Preview {
//    SummaryView(bookRequests: .constant([]))
//        .environment(\.colorScheme, .light)
//}















//MARK: with some good animation

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
            VStack(alignment: .leading, spacing: 10) {
                if isLoading {
                    ProgressView("Loading requests...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if pendingRequests.isEmpty {
                    Text("No pending requests found.")
                        .font(.title2)
                        .foregroundStyle(Color.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    NavigationLink {
                        AllPendingRequestsView(
                            pendingRequests: pendingRequests,
                            bookRequests: $bookRequests
                        )
                    } label: {
                        SummaryCard(requestCount: pendingRequests.count)
                            .padding(.horizontal)
                    }
                    .transition(.opacity.combined(with: .slide)) // Smooth fade + slide transition
                    Spacer()
                }
            }
            .navigationTitle("Summary")
            .animation(.easeInOut(duration: 0.5), value: pendingRequests) // Smooth animation for view updates
        }
    }
}

struct SummaryCard: View {
    let requestCount: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 2)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pending Requests")
                        .font(.headline)
                        .foregroundStyle(Color.black)

                    Text("You have \(requestCount) pending request\(requestCount == 1 ? "" : "s") to review.")
                        .font(.subheadline)
                        .foregroundStyle(Color.black.opacity(0.8))
                        .lineLimit(2)
                }
                .padding(.leading, 15)
                .padding(.vertical, 15)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .bold))
                    .padding(.trailing, 15)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 100)
    }
}

struct AllPendingRequestsView: View {
    let pendingRequests: [BookRequest]
    @Binding var bookRequests: [BookRequest]
    @State private var showHistory = false

    var historyRequests: [BookRequest] {
        bookRequests.filter { $0.Request_status != .pending }
    }

    var body: some View {
        VStack {
            if pendingRequests.isEmpty {
                Text("No pending requests found.")
                    .font(.title2)
                    .foregroundStyle(Color.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(pendingRequests) { request in
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
                            .transition(.opacity.combined(with: .slide)) // Smooth fade + slide transition
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Pending Requests")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    print("Show History")
                    showHistory = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showHistory) {
            NavigationStack {
                HistoryView(historyRequests: historyRequests)
                    .navigationTitle("Request History")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                print("Dismiss History")
                                showHistory = false
                            }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.5), value: showHistory) // Soothing sheet animation
    }
}

struct RequestCard: View {
    let request: BookRequest

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(request.title)
                    .font(Font.headline)
                    .foregroundStyle(Color.black)
                    .lineLimit(1)

                Text("Author: \(request.author)")
                    .font(Font.subheadline)
                    .foregroundStyle(.gray)

                Text("Quantity: \(request.quantity)")
                    .font(Font.subheadline)
                    .foregroundStyle(.gray)
            }
            .padding(.leading, 15)

            Spacer()

            Text(request.Request_status.rawValue.capitalized)
                .font(Font.caption)
                .padding(8)
                .background(statusColor(for: request.Request_status))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.trailing, 15)
        }
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 3, x: 0, y: 2)
        )
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

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Request Details")
                .font(.title)
                .foregroundStyle(Color.black)

            Group {
                DetailRow(title: "Title", value: request.title)
                DetailRow(title: "Author", value: request.author)
                DetailRow(title: "Quantity", value: String(request.quantity))
                DetailRow(title: "Reason", value: request.reason)
                DetailRow(title: "Status", value: request.Request_status.rawValue.capitalized)
                DetailRow(title: "Created At", value: request.createdAt.formatted(date: .abbreviated, time: .shortened))
            }

            if request.Request_status == .pending {
                HStack(spacing: 20) {
                    Button(action: {
                        print("Accept tapped for \(request.Request_id)")
                        Task {
                            await updateStatus(to: .approved)
                        }
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
                        print("Reject tapped for \(request.Request_id)")
                        Task {
                            await updateStatus(to: .rejected)
                        }
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

struct HistoryView: View {
    let historyRequests: [BookRequest]

    var body: some View {
        VStack {
            if historyRequests.isEmpty {
                Text("No history available.")
                    .font(.title2)
                    .foregroundStyle(Color.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(historyRequests) { request in
                            NavigationLink {
                                HistoryDetailView(request: request)
                            } label: {
                                HistoryCard(request: request)
                            }
                            .transition(.opacity.combined(with: .slide)) // Smooth fade + slide transition
                        }
                    }
                    .padding()
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: historyRequests) // Smooth animation for history items
    }
}

struct HistoryCard: View {
    let request: BookRequest

    var body: some View {
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
            Text(request.Request_status.rawValue.capitalized)
                .font(.caption)
                .padding(5)
                .background(statusColor(for: request.Request_status))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .padding(.vertical, 5)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 3)
        )
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

struct HistoryDetailView: View {
    let request: BookRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Request Details")
                .font(.title)
                .foregroundStyle(Color.black)

            Group {
                DetailRow(title: "Title", value: request.title)
                DetailRow(title: "Author", value: request.author)
                DetailRow(title: "Quantity", value: String(request.quantity))
                DetailRow(title: "Reason", value: request.reason)
                DetailRow(title: "Status", value: request.Request_status.rawValue.capitalized)
                DetailRow(title: "Created At", value: request.createdAt.formatted(date: .abbreviated, time: .shortened))
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Request Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // Hide the back button
    }
}

#Preview {
    SummaryView(bookRequests: .constant([]))
        .environment(\.colorScheme, .light)
}
