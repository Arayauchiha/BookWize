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
                    
                        // UNCOMMENT THIS AFTER SPRINT - 2
                case .returned:
                    ReturnBookView()
                case .renewed:
                    RenewBookView()
                case .reserved:
                    ReservedBookView()
                    
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
    // UNCOMMENT THIS AFTER SPRINT - 2
    case returned = "Return Book"
    case renewed = "Renewd Book"
    case reserved = "Reserved Book"
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
