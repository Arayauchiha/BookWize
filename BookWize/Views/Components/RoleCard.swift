// Create this new file for RoleCard
import SwiftUI

struct RoleCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let cardColor: Color
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(Color.iconBackgroundOpacity))
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.customText)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(Color.customText.opacity(Color.secondaryIconOpacity))
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardColor)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

// Preview
#Preview {
    RoleCard(
        title: "Admin",
        icon: "gear",
        iconColor: Color.adminColor,
        cardColor: Color.customCardBackground
    )
}

// End of file
