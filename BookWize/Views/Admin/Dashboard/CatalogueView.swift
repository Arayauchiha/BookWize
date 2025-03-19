import SwiftUI

struct CatalogueView: View {
    var body: some View {
        VStack {
            Text("Catalogue Features Coming Soon")
                .font(.title2)
                .foregroundStyle(Color.customText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.customBackground)
    }
}

#Preview {
    CatalogueView()
        .environment(\.colorScheme, .light)
}

