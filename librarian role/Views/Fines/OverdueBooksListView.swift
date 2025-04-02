import SwiftUI

struct OverdueBooksListView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
    
//    //@StateObject private var fineManager = FineManager()
//    @StateObject private var userManager = LibrarianDashboardManager()
//    @State private var searchText = ""
//    @State private var showingPaymentSheet = false
//    //@State private var selectedMember: Member?
//    @State private var selectedRecord: CirculationRecord?
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
//        VStack(spacing: 16) {
//            // Search Bar
//            SearchBar(text: $searchText, placeholder: "Search by member name or ID")
//                .padding(.horizontal)
//            
//            // List of overdue books
//            if filteredOverdueBooks.isEmpty {
//                EmptyStateView(
//                    icon: "checkmark.circle.fill",
//                    title: "No Overdue Books",
//                    message: "All books are returned on time"
//                )
//            } else {
//                List {
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
//                .listStyle(.plain)
//            }
//        }
//        .navigationTitle("Overdue Books")
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
}
