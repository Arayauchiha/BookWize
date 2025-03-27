import SwiftUI

struct BookCirculationView: View {
    @StateObject private var circulationManager = IssuedBookManager.shared
    
    @State private var activeTab = CirculationTab.issue
    @State private var showingScanner = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CustomSegmentedControl(
                    selection: $activeTab,
                    options: CirculationTab.allCases
                )
                .padding()
                
                switch activeTab {
                case .issue:
                    IssueBookView()
                case .returned:
                    ReturnBookView()
                case .renew:
                    RenewBookView()
                }
            }
            .navigationTitle("Book Circulation")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                ISBNScannerView { scannedISBN in
                    // Handle scanned ISBN
                }
            }
        }
    }
}

enum CirculationTab: String, CaseIterable {
    case issue = "Issue Book"
    case returned = "Return Book"
    case renew = "Renew Book"
}

struct CustomSegmentedControl<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(String(describing: option)).tag(option)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

//struct IssueBookView: View {
//    let circulationManager: CirculationManager
//    @State private var searchText = ""
//    @State private var showingMemberSearch = false
//    
//    var body: some View {
//        VStack {
//            if circulationManager.currentTransactions.isEmpty {
//                EmptyStateView(
//                    icon: "book.closed",
//                    title: "No Active Circulations",
//                    message: "Start by scanning a book or searching for a member"
//                )
//            } else {
//                List {
//                    ForEach(circulationManager.currentTransactions) { transaction in
//                        CirculationRowView(transaction: transaction)
//                    }
//                }
//            }
//            
//            Button {
//                showingMemberSearch = true
//            } label: {
//                Label("Issue New Book", systemImage: "plus.circle.fill")
//                    .font(.headline)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(AppTheme.primaryColor)
//                    .foregroundColor(.white)
//                    .cornerRadius(12)
//            }
//            .padding()
//        }
//        .searchable(text: $searchText, prompt: "Search transactions...")
//    }
//}

//struct ReturnBookView: View {
//    let circulationManager: CirculationManager
//    @State private var searchText = ""
//    
//    var body: some View {
//        VStack {
//            if circulationManager.currentTransactions.isEmpty {
//                EmptyStateView(
//                    icon: "arrow.left.circle",
//                    title: "No Books to Return",
//                    message: "There are no books currently checked out"
//                )
//            } else {
//                List {
//                    ForEach(circulationManager.currentTransactions.filter { $0.returnDate == nil }) { transaction in
//                        CirculationRowView(transaction: transaction)
//                            .swipeActions {
//                                Button {
//                                    try? circulationManager.returnBook(transaction)
//                                } label: {
//                                    Label("Return", systemImage: "arrow.left")
//                                }
//                                .tint(.green)
//                            }
//                    }
//                }
//            }
//        }
//        .searchable(text: $searchText, prompt: "Search books to return...")
//    }
//}

//struct RenewBookView: View {
//    let circulationManager: CirculationManager
//    @State private var searchText = ""
//    
//    var body: some View {
//        VStack {
//            if circulationManager.currentTransactions.isEmpty {
//                EmptyStateView(
//                    icon: "arrow.clockwise.circle",
//                    title: "No Books to Renew",
//                    message: "There are no books eligible for renewal"
//                )
//            } else {
//                List {
//                    ForEach(circulationManager.currentTransactions.filter { $0.returnDate == nil }) { transaction in
//                        CirculationRowView(transaction: transaction)
//                            .swipeActions {
//                                Button {
//                                    try? circulationManager.renewBook(transaction)
//                                } label: {
//                                    Label("Renew", systemImage: "arrow.clockwise")
//                                }
//                                .tint(.blue)
//                            }
//                    }
//                }
//            }
//        }
//        .searchable(text: $searchText, prompt: "Search books to renew...")
//    }
//}

//struct CirculationRowView: View {
//    let transaction: CirculationRecord
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Text("Book ID: \(transaction.bookId.uuidString)")
//                    .font(.headline)
//                Spacer()
//                StatusBadge(status: transaction.status)
//            }
//            
//            Text("Member ID: \(transaction.memberId.uuidString)")
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//            
//            HStack {
//                Label(transaction.issueDate.formatted(date: .abbreviated, time: .omitted),
//                      systemImage: "calendar")
//                Spacer()
//                Label(transaction.dueDate.formatted(date: .abbreviated, time: .omitted),
//                      systemImage: "calendar.badge.clock")
//                    .foregroundColor(transaction.isOverdue ? .red : .primary)
//            }
//            .font(.caption)
//        }
//        .padding(.vertical, 4)
//    }
//}

//struct StatusBadge: View {
//    let status: CirculationStatus
//    
//    var body: some View {
//        Text(status.rawValue.capitalized)
//            .font(.caption)
//            .padding(.horizontal, 8)
//            .padding(.vertical, 4)
//            .background(backgroundColor)
//            .foregroundColor(.white)
//            .cornerRadius(8)
//    }
//    
//    private var backgroundColor: Color {
//        switch status {
//        case .issued:
//            return .blue
//        case .returned:
//            return .green
//        case .renewed:
//            return .orange
//        case .overdue:
//            return .red
//        }
//    }
//}
