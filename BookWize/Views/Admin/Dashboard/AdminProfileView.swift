import SwiftUI

struct FetchAdmin:Codable{
    var id:UUID
    var email:String
    var name:String
}

struct AdminProfileView: View {
    @State private var showLogoutAlert = false
    @State private var showPasswordReset = false
    @AppStorage("isAdminLoggedIn") private var isAdminLoggedIn = false
    @Environment(\.dismiss) private var dismiss
    @State private var user: FetchAdmin?
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isNewPasswordVisible = false
    
    private func fetchMember() async {
        do {
            guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail") else {
                print("No email found in UserDefaults")
                return
            }
            
            print("Fetching member with email: \(userEmail)")
            
            let response: [FetchAdmin] = try await SupabaseManager.shared.client
                .from("Users")
                .select("*")
                .eq("email", value: userEmail)
                .execute()
                .value
            
            DispatchQueue.main.async {
                if let fetchedUser = response.first {
                    self.user = fetchedUser
                    print("Successfully fetched user: \(fetchedUser.name)")
                } else {
                    print("No user found with email: \(userEmail)")
                }
            }
        } catch {
            print("Error fetching member: \(error)")
        }
    }
    
    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.customButton)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user?.name ?? "Admin")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(user?.email ?? "ss0854850@gmail.com")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.6))
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Button(action: { showPasswordReset = true }) {
                    Label("Change Password", systemImage: "lock")
                }
                
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
        .sheet(isPresented: $showPasswordReset) {
            AdminPasswordResetView(
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isNewPasswordVisible: $isNewPasswordVisible,
                email: user?.email ?? "",
                title: "Change Password",
                message: "Enter your new password below",
                buttonTitle: "Update Password",
                onSave: {
                    showPasswordReset = false
                    newPassword = ""
                    confirmPassword = ""
                },
                onCancel: {
                    showPasswordReset = false
                    newPassword = ""
                    confirmPassword = ""
                }
            )
        }
        .task {
            await fetchMember()
        }
    }
}

#Preview {
    AdminProfileView()
        .environment(\.colorScheme, .light)
}
