import SwiftUI

struct AdminProfileView: View {
    @State private var showLogoutAlert = false
    @AppStorage("isAdminLoggedIn") private var isAdminLoggedIn = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.customButton)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Admin")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("ss0854850@gmail.com")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.6))
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Button(role: .destructive) {
                    showLogoutAlert = true
                } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.customBackground)
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                isAdminLoggedIn = false
                dismiss()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

#Preview {
    AdminProfileView()
        .environment(\.colorScheme, .light)
}
