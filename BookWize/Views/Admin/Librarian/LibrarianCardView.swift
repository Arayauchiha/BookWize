import SwiftUI

struct LibrarianCardView: View {
    let librarian: LibrarianData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text(librarian.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.customText)
                
                Spacer()
                
                Text(librarian.status.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(librarian.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(librarian.status.color.opacity(0.15))
                    )
            }
            
            // Contact info
            VStack(alignment: .leading, spacing: 8) {
                Label(librarian.email, systemImage: "envelope.fill")
                Label(String(librarian.phone ?? 0), systemImage: "phone.fill")
            }
            .font(.system(size: 15))
            .foregroundStyle(Color.customText.opacity(0.6))
            
            // Date added
            Text("Added \(librarian.dateAdded.formatted(date: .abbreviated, time: .shortened))")
                .font(.system(size: 13))
                .foregroundStyle(Color.customText.opacity(0.4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.customCardBackground)
        )
    }
}

