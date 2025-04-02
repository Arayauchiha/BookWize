import SwiftUI

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
    @State private var user: FetchAdmin?
    
    private func fetchMember() async {
        do {
            // Get email from UserDefaults
            guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail") else {
                print("No email found in UserDefaults")
                return
            }
            
            print("Fetching member with email: \(userEmail)")
            
            let response: [FetchAdmin] = try await SupabaseManager.shared.client
                .from("Users")
                .select("*")
                .eq("email", value: userEmail)  // Use email instead of id
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
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
            
                        
                        VStack(alignment: .leading) {
                            Text(user?.name ?? "Librarian")
                                .font(.headline)
                            Text(user?.email ?? "Librarian@example.com")
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
            .task {
                await fetchMember()
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
    @State private var isNewPasswordVisible = false
    @FocusState private var focusedField: Field?
    
    // Password validation state
    @State private var passwordValidation = ValidationUtils.PasswordValidation(
        hasMinLength: false,
        hasUppercase: false,
        hasLowercase: false,
        hasNumber: false,
        hasSpecialChar: false
    )
    
    private enum Field {
        case currentPassword
        case newPassword
        case confirmPassword
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Password")) {
                    SecureField("Enter current password", text: $currentPassword)
                        .focused($focusedField, equals: .currentPassword)
                }
                
                Section(header: Text("New Password")) {
                    HStack {
                        Group {
                            if isNewPasswordVisible {
                                TextField("Enter new password", text: $newPassword)
                                    .textContentType(.newPassword)
                                    .textInputAutocapitalization(.never)
                                    .focused($focusedField, equals: .newPassword)
                                    .onChange(of: newPassword) { newValue in
                                        passwordValidation = ValidationUtils.validatePassword(newValue)
                                    }
                            } else {
                                SecureField("Enter new password", text: $newPassword)
                                    .textContentType(.newPassword)
                                    .textInputAutocapitalization(.never)
                                    .focused($focusedField, equals: .newPassword)
                                    .onChange(of: newPassword) { newValue in
                                        passwordValidation = ValidationUtils.validatePassword(newValue)
                                    }
                            }
                        }
                        
                        Button(action: { isNewPasswordVisible.toggle() }) {
                            Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    
                    // Password requirements
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password Requirements")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        
                        HStack {
                            Image(systemName: passwordValidation.hasMinLength ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(passwordValidation.hasMinLength ? .green : .gray)
                            Text("At least 8 characters")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        
                        HStack {
                            Image(systemName: passwordValidation.hasUppercase ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(passwordValidation.hasUppercase ? .green : .gray)
                            Text("One uppercase letter")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        
                        HStack {
                            Image(systemName: passwordValidation.hasLowercase ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(passwordValidation.hasLowercase ? .green : .gray)
                            Text("One lowercase letter")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        
                        HStack {
                            Image(systemName: passwordValidation.hasNumber ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(passwordValidation.hasNumber ? .green : .gray)
                            Text("One number")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        
                        HStack {
                            Image(systemName: passwordValidation.hasSpecialChar ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(passwordValidation.hasSpecialChar ? .green : .gray)
                            Text("One special character (@$!%*?&)")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .padding(.top, 8)
                }
                
                Section(header: Text("Confirm New Password")) {
                    SecureField("Confirm new password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .confirmPassword)
                }
                
                Section {
                    Button("Update Password") {
                        updatePassword()
                    }
                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || !passwordValidation.isValid || newPassword != confirmPassword)
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
            .onAppear {
                focusedField = .currentPassword
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
        
        // Validate password requirements
        guard passwordValidation.isValid else {
            errorMessage = "New password does not meet requirements"
            showingError = true
            return
        }
        
        // Get current user email
        guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail") else {
            errorMessage = "User email not found"
            showingError = true
            return
        }
        
        // Update password in Supabase
        Task {
            do {
                let userData = ["email": userEmail, "password": newPassword]
                let response = try await SupabaseManager.shared.client
                    .from("Users")
                    .update(userData)
                    .eq("email", value: userEmail)
                    .execute()
                
                DispatchQueue.main.async {
                    showingSuccess = true
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to update password: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}
