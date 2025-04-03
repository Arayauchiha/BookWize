import SwiftUI

struct BookCirculationView: View {
    @State private var selectedTab = 0
    private let tabs = ["Issue", "Return", "Reserved"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header with segmented control
            Picker("", selection: $selectedTab) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Text(tabs[index])
                        .tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content area
            TabView(selection: $selectedTab) {
                IssueBookView()
                    .tag(0)
                
                ReturnBookView()
                    .tag(1)
                
                ReservedBookView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.customBackground)
    }
}

#Preview {
    BookCirculationView()
}
