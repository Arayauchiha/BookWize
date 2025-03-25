import SwiftUI
import BookWize  // Import to access NavigationUtil

struct AccountView: View {
    @Binding var isLoggedIn: Bool
    @State private var showingLogoutAlert = false
    @State private var showingChangePassword = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingPasswordError = false
    @AppStorage("isLibrarianLoggedIn") private var isLibrarianLoggedIn = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
            
                        
                        VStack(alignment: .leading) {
                            Text("Librarian")
                                .font(.headline)
                            Text("Admin")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account Settings") {
                    Button {
                        showingChangePassword = true
                    } label: {
                        Label("Change Password", systemImage: "lock.fill")
                    }
                    
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Account")
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordView()
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    // Reset login state
                    isLoggedIn = false
                    isLibrarianLoggedIn = false
                    
                    // Navigate to role selection screen
                    NavigationUtil.popToRootView()
                    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                    let window = windowScene?.windows.first
                    window?.rootViewController = UIHostingController(rootView: ContentView())
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Password")) {
                    SecureField("Enter current password", text: $currentPassword)
                }
                
                Section(header: Text("New Password")) {
                    SecureField("Enter new password", text: $newPassword)
                    SecureField("Confirm new password", text: $confirmPassword)
                }
                
                Section {
                    Button("Update Password") {
                        updatePassword()
                    }
                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Password has been updated successfully")
            }
        }
    }
    
    private func updatePassword() {
        // Validate passwords match
        guard newPassword == confirmPassword else {
            errorMessage = "New passwords do not match"
            showingError = true
            return
        }
        
        // Validate new password is different
        guard newPassword != currentPassword else {
            errorMessage = "New password must be different from current password"
            showingError = true
            return
        }
        
        // Update password
        if UserDefaultsManager.shared.updatePassword(currentPassword: currentPassword, newPassword: newPassword) {
            showingSuccess = true
        } else {
            errorMessage = "Current password is incorrect"
            showingError = true
        }
    }
}
