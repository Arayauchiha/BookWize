import SwiftUI

struct FinanceView: View {
    var body: some View {
        VStack {
            Text("Finance Features Coming Soon")
                .font(.title2)
                .foregroundStyle(Color.customText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.customBackground)
    }
}

#Preview {
    FinanceView()
        .environment(\.colorScheme, .light)
}

