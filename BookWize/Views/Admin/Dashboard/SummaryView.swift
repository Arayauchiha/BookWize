import SwiftUI

struct SummaryView: View {
    var body: some View {
        VStack {
            Text("Summary Coming Soon")
                .font(.title2)
                .foregroundStyle(Color.customText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.customBackground)
    }
}

#Preview {
    SummaryView()
        .environment(\.colorScheme, .light)
}

