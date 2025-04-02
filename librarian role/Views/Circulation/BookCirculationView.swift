import SwiftUI
import UIKit

struct BookCirculationView: View {
    @StateObject private var circulationManager = IssuedBookManager.shared
    
    @State private var activeTab = CirculationTab.Issue
    @State private var showingScanner = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CustomSegmentedControl(
                    selection: $activeTab,
                    options: CirculationTab.allCases
                )
                .padding()
                .onChange(of: activeTab) { newValue in
                    HapticManager.lightImpact()
                }
                
                switch activeTab {
                case .Issue:
                    IssueBookView()
                case .Returned:
                    ReturnBookView()
                case .Reserved:
                    ReservedBookView()
                    
                }
            }
            .navigationTitle("Book Circulation")
        }
    }
}

enum CirculationTab: String, CaseIterable {
    case Issue = "Issue Book"
    case Returned = "Return Book"
    case Reserved = "Reserved Book"
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
