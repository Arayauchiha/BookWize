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
                case .reserved:
                    ReservedBookView()
                    
                }
            }
            .navigationTitle("Book Circulation")
        }
    }
}

enum CirculationTab: String, CaseIterable {
    case issue = "Issue Book"
    case returned = "Return Book"
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
