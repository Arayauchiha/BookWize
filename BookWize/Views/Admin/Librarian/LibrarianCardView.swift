import SwiftUI

struct LibrarianCardView: View {
    let librarian: Librarian
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with name and status
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
                Label(librarian.phone, systemImage: "phone.fill")
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

#Preview {
    LibrarianCardView(
        librarian: Librarian(
            name: "John Doe",
            age: 30,
            email: "john@example.com",
            phone: "+1 234 567 8900",
            status: .pending
        )
    )
    .padding()
    .background(Color.customBackground)
}

