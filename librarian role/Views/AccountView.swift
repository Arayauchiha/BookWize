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
        List {
            // Profile Section
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user?.name ?? "Librarian")
                            .font(.headline)
                        Text(user?.email ?? "Librarian@example.com")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Account Settings Section
            Section {
                Button(action: {
                    showingChangePassword = true
                }) {
                    HStack {
                        Label("Change Password", systemImage: "lock.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                    }
                }
                
                Button(role: .destructive, action: {
                    showingLogoutAlert = true
                }) {
                    HStack {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        Spacer()
                    }
                }
            } header: {
                Text("Account Settings")
                    .textCase(.uppercase)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
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

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var isNewPasswordVisible = false
    @State private var isCurrentPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
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
            ScrollView {
                VStack(spacing: 24) {
                    // Current Password Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Password")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.7))
                        
                        ZStack(alignment: .trailing) {
                            Group {
                                if isCurrentPasswordVisible {
                                    TextField("Enter current password", text: $currentPassword)
                                        .textContentType(.password)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .currentPassword)
                                } else {
                                    SecureField("Enter current password", text: $currentPassword)
                                        .textContentType(.password)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .currentPassword)
                                }
                            }
                            .padding()
                            .background(.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                            
                            Button(action: { isCurrentPasswordVisible.toggle() }) {
                                Image(systemName: isCurrentPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(Color.blue.opacity(0.6))
                                    .padding(.trailing, 12)
                            }
                        }
                    }
                    
                    // New Password Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.7))
                        
                        ZStack(alignment: .trailing) {
                            Group {
                                if isNewPasswordVisible {
                                    TextField("Enter new password", text: $newPassword)
                                        .textContentType(.newPassword)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .newPassword)
                                        .onChange(of: newPassword) { _, newValue in
                                            passwordValidation = ValidationUtils.validatePassword(newValue)
                                        }
                                } else {
                                    SecureField("Enter new password", text: $newPassword)
                                        .textContentType(.newPassword)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .newPassword)
                                        .onChange(of: newPassword) { _, newValue in
                                            passwordValidation = ValidationUtils.validatePassword(newValue)
                                        }
                                }
                            }
                            .padding()
                            .background(.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                            
                            Button(action: { isNewPasswordVisible.toggle() }) {
                                Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(Color.blue.opacity(0.6))
                                    .padding(.trailing, 12)
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
                    
                    // Confirm Password Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm New Password")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.7))
                        
                        ZStack(alignment: .trailing) {
                            Group {
                                if isConfirmPasswordVisible {
                                    TextField("Confirm new password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .confirmPassword)
                                } else {
                                    SecureField("Confirm new password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .confirmPassword)
                                }
                            }
                            .padding()
                            .background(.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                            
                            Button(action: { isConfirmPasswordVisible.toggle() }) {
                                Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(Color.blue.opacity(0.6))
                                    .padding(.trailing, 12)
                            }
                        }
                    }
                    
                    // Update Password Button
                    Button(action: updatePassword) {
                        Text("Update Password")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isFormValid ? Color.librarianColor : Color.gray)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .background(Color.customBackground)
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
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty && 
        !newPassword.isEmpty && 
        !confirmPassword.isEmpty && 
        passwordValidation.isValid && 
        newPassword == confirmPassword
    }
    
    private func updatePassword() {
        // Get current user email
        guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail") else {
            errorMessage = "User email not found"
            showingError = true
            return
        }
        
        // First verify current password
        Task {
            do {
                // First verify the current password
                let data: [FetchAdmin] = try await SupabaseManager.shared.client
                    .from("Users")
                    .select("*")
                    .eq("email", value: userEmail)
                    .eq("password", value: currentPassword)
                    .eq("roleFetched", value: "librarian")
                    .execute()
                    .value
                
                if data.isEmpty {
                    DispatchQueue.main.async {
                        errorMessage = "Current password is incorrect"
                        showingError = true
                    }
                    return
                }
                
                // Validate passwords match
                guard newPassword == confirmPassword else {
                    DispatchQueue.main.async {
                        errorMessage = "New passwords do not match"
                        showingError = true
                    }
                    return
                }
                
                // Validate new password is different
                guard newPassword != currentPassword else {
                    DispatchQueue.main.async {
                        errorMessage = "New password must be different from current password"
                        showingError = true
                    }
                    return
                }
                
                // Validate password requirements
                guard passwordValidation.isValid else {
                    DispatchQueue.main.async {
                        errorMessage = "New password does not meet requirements"
                        showingError = true
                    }
                    return
                }
                
                // Update password in Supabase
                let userData = ["email": userEmail, "password": newPassword]
                _ = try await SupabaseManager.shared.client
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
