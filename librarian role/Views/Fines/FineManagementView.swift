import SwiftUI

//struct FineManagementView: View {
//    @StateObject private var fineManager = FineManager()
//    @StateObject private var userManager = UserManager()
//    @State private var showingPaymentSheet = false
//    @State private var selectedMember: Member?
//    @State private var selectedRecord: CirculationRecord?
//    @State private var searchText = ""
//
//    private var filteredOverdueBooks: [CirculationRecord] {
//        if searchText.isEmpty {
//            return fineManager.overdueBooks
//        }
//        return fineManager.overdueBooks.filter { record in
//            if let member = userManager.getMember(record.memberId) {
//                return member.name.localizedCaseInsensitiveContains(searchText) ||
//                       member.membershipNumber.localizedCaseInsensitiveContains(searchText)
//            }
//            return false
//        }
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // Summary Card
//            CardView {
//                VStack(alignment: .leading, spacing: AppTheme.smallPadding) {
//                    Text("Overdue Summary")
//                        .font(.headline)
//                        .foregroundColor(AppTheme.textColor)
//
//                    HStack {
//                        SummaryItem(
//                            title: "Total Overdue",
//                            value: "\(filteredOverdueBooks.count)",
//                            icon: "exclamationmark.triangle.fill",
//                            color: AppTheme.accentColor
//                        )
//
//                        Divider()
//
//                        SummaryItem(
//                            title: "Total Fine",
//                            value: "$\(calculateTotalFine())",
//                            icon: "dollarsign.circle.fill",
//                            color: AppTheme.secondaryColor
//                        )
//                    }
//                }
//            }
//            .padding()
//
//            // Search Bar
//            SearchBar(text: $searchText, placeholder: "Search by member name or ID")
//                .padding(.horizontal)
//
//            // Overdue Books List
//            List {
//                if filteredOverdueBooks.isEmpty {
//                    EmptyStateView(
//                        icon: "checkmark.circle.fill",
//                        title: "No Overdue Books",
//                        message: "All books are returned on time"
//                    )
//                } else {
//                    ForEach(filteredOverdueBooks) { record in
//                        if let member = userManager.getMember(record.memberId) {
//                            OverdueFineRow(record: record)
//                                .swipeActions {
//                                    Button {
//                                        selectedMember = member
//                                        selectedRecord = record
//                                        showingPaymentSheet = true
//                                    } label: {
//                                        Label("Collect", systemImage: "dollarsign.circle")
//                                    }
//                                    .tint(.green)
//                                }
//                        }
//                    }
//                }
//            }
//            .listStyle(.plain)
//        }
//        .navigationTitle("Fine Management")
//        .sheet(isPresented: $showingPaymentSheet) {
//            if let member = selectedMember, let record = selectedRecord {
//                CollectFineView(
//                    member: member,
//                    record: record,
//                    fineManager: fineManager
//                )
//            }
//        }
//    }
//
//    // MARK: - Function to calculate total fines
//    private func calculateTotalFine() -> Double {
//        return fineManager.overdueBooks.reduce(0) { total, record in
//            total + record.fineAmount
//        }
//    }
//    }
//// MARK: - SummaryItem Component
//struct SummaryItem: View {
//    var title: String
//    var value: String
//    var icon: String
//    var color: Color
//
//    var body: some View {
//        VStack(spacing: 8) {
//            Image(systemName: icon)
//                .font(.title2)
//                .foregroundColor(color)
//            
//            Text(value)
//                .font(.headline)
//                .foregroundColor(AppTheme.textColor)
//            
//            Text(title)
//                .font(.caption)
//                .foregroundColor(AppTheme.secondaryTextColor)
//        }
//        .frame(maxWidth: .infinity)
//    }
//}
//
//// MARK: - SearchBar Component
//struct SearchBar: View {
//    @Binding var text: String
//    var placeholder: String
//
//    var body: some View {
//        HStack {
//            Image(systemName: "magnifyingglass")
//                .foregroundColor(AppTheme.secondaryTextColor)
//            
//            TextField(placeholder, text: $text)
//                .textFieldStyle(.plain)
//                .autocapitalization(.none)
//            
//            if !text.isEmpty {
//                Button(action: { text = "" }) {
//                    Image(systemName: "xmark.circle.fill")
//                        .foregroundColor(AppTheme.secondaryTextColor)
//                }
//            }
//        }
//        .padding(12)
//        .background(Color(.systemGray6))
//        .cornerRadius(10)
//    }
//}
//
//// MARK: - EmptyStateView Component
struct EmptyStateView: View {
    var icon: String
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(AppTheme.secondaryTextColor)
            
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
