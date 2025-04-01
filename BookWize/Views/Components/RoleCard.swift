import SwiftUI

struct RoleCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let cardColor: Color
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon Container
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            // Title
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.customText)
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.customText.opacity(0.3))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

#Preview {
    VStack(spacing: 12) {
        RoleCard(
            title: "Member",
            icon: "person.fill",
            iconColor: Color.memberColor,
            cardColor: Color.customCardBackground
        )
        
        RoleCard(
            title: "Librarian",
            icon: "books.vertical.fill",
            iconColor: Color.librarianColor,
            cardColor: Color.customCardBackground
        )
        
        RoleCard(
            title: "Admin",
            icon: "gear",
            iconColor: Color.adminColor,
            cardColor: Color.customCardBackground
        )
    }
    .padding()
    .background(Color.customBackground)
}

