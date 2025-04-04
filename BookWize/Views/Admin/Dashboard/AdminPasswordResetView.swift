import SwiftUI

struct AdminPasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isNewPasswordVisible: Bool
    @State private var currentPassword = ""
    @FocusState private var focusedField: Field?
    
    let email: String
    let title: String
    let message: String
    let buttonTitle: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    // Password validation state
    @State private var passwordValidation = ValidationUtils.PasswordValidation(
        hasMinLength: false,
        hasUppercase: false,
        hasLowercase: false,
        hasNumber: false,
        hasSpecialChar: false
    )
    
    // Add state for showing error alert
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    private enum Field {
        case currentPassword
        case newPassword
        case confirmPassword
    }
    
    struct FetchData: Codable {
        var email: String
        var password: String
    }
    
    // Add update password function
    private func updatePassword() async {
        print("Attempting to update password for admin email: \(email)")
        
        // First verify current password
        do {
            let data: [FetchData] = try await SupabaseManager.shared.client
                .from("Users")
                .select("*")
                .eq("email", value: email)
                .eq("password", value: currentPassword)
                .eq("roleFetched", value: "admin")
                .execute()
                .value
            
            if data.isEmpty {
                DispatchQueue.main.async {
                    HapticManager.error()
                    errorMessage = "Current password is incorrect"
                    showError = true
                }
                return
            }
        } catch {
            print("Error verifying current password:", error)
            DispatchQueue.main.async {
                HapticManager.error()
                errorMessage = "Failed to verify current password: \(error.localizedDescription)"
                showError = true
            }
            return
        }
        
        // Validate passwords match
        guard newPassword == confirmPassword else {
            HapticManager.error()
            errorMessage = "New passwords do not match"
            showError = true
            return
        }
        
        // Validate new password is different
        guard newPassword != currentPassword else {
            HapticManager.error()
            errorMessage = "New password must be different from current password"
            showError = true
            return
        }
        
        // Validate password requirements
        guard passwordValidation.isValid else {
            HapticManager.error()
            errorMessage = "New password does not meet requirements"
            showError = true
            return
        }
        
        do {
            let userData = FetchData(email: email, password: newPassword)
            print("Sending update request to Users table with data:", userData)
            
            let response = try await SupabaseManager.shared.client
                .from("Users")
                .update(userData)
                .eq("email", value: email)
                .execute()
            
            print("Password update response:", response)
            
            DispatchQueue.main.async {
                print("Password successfully updated for admin:", email)
                HapticManager.success()
                showSuccess = true
            }
        } catch {
            print("Error updating password:", error)
            DispatchQueue.main.async {
                HapticManager.error()
                errorMessage = "Failed to update password: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.customText.opacity(0.6))
                    .padding(.top, 20)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Current password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Password")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.6))
                        
                        SecureField("Enter current password", text: $currentPassword)
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .currentPassword)
                            .padding()
                            .background(Color.customInputBackground)
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 8)
                    
                    // New password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.6))
                        
                        HStack {
                            Group {
                                if isNewPasswordVisible {
                                    TextField("Enter new password", text: $newPassword)
                                        .textContentType(.newPassword)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .newPassword)
                                        .onChange(of: newPassword) { _, newValue in
                                            let oldValidation = passwordValidation
                                            passwordValidation = ValidationUtils.validatePassword(newValue)
                                            // Provide haptic feedback when password requirements are met
                                            if !oldValidation.isValid && passwordValidation.isValid {
                                                HapticManager.success()
                                            }
                                        }
                                } else {
                                    SecureField("Enter new password", text: $newPassword)
                                        .textContentType(.newPassword)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .newPassword)
                                        .onChange(of: newPassword) { _, newValue in
                                            let oldValidation = passwordValidation
                                            passwordValidation = ValidationUtils.validatePassword(newValue)
                                            // Provide haptic feedback when password requirements are met
                                            if !oldValidation.isValid && passwordValidation.isValid {
                                                HapticManager.success()
                                            }
                                        }
                                }
                            }
                            
                            Button(action: {
                                HapticManager.lightImpact()
                                isNewPasswordVisible.toggle()
                            }) {
                                Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(Color.customButton.opacity(Color.secondaryIconOpacity))
                            }
                        }
                        .padding()
                        .background(Color.customInputBackground)
                        .cornerRadius(8)
                    }
                    .padding(.bottom, 8)

                    // Password requirements
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password Requirements")
                            .font(.caption)
                            .foregroundStyle(Color.customText.opacity(0.7))
                        
                        HStack {
                            Image(systemName: passwordValidation.hasMinLength ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(passwordValidation.hasMinLength ? .green : .gray)
                            Text("At least 8 characters")
                                .font(.caption)
                                .foregroundStyle(Color.customText.opacity(0.7))
                        }
                        
                        HStack {
                            Image(systemName: passwordValidation.hasUppercase ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(passwordValidation.hasUppercase ? .green : .gray)
                            Text("One uppercase letter")
                                .font(.caption)
                                .foregroundStyle(Color.customText.opacity(0.7))
                        }
                        
                        HStack {
                            Image(systemName: passwordValidation.hasLowercase ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(passwordValidation.hasLowercase ? .green : .gray)
                            Text("One lowercase letter")
                                .font(.caption)
                                .foregroundStyle(Color.customText.opacity(0.7))
                        }
                        
                        HStack {
                            Image(systemName: passwordValidation.hasNumber ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(passwordValidation.hasNumber ? .green : .gray)
                            Text("One number")
                                .font(.caption)
                                .foregroundStyle(Color.customText.opacity(0.7))
                        }
                        
                        HStack {
                            Image(systemName: passwordValidation.hasSpecialChar ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(passwordValidation.hasSpecialChar ? .green : .gray)
                            Text("One special character (@$!%*?&)")
                                .font(.caption)
                                .foregroundStyle(Color.customText.opacity(0.7))
                        }
                    }
                    .padding(.leading, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.6))
                        
                        HStack {
                            Group {
                                if isNewPasswordVisible {
                                    TextField("Confirm new password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .onChange(of: confirmPassword) { _, newValue in
                                            if !newValue.isEmpty && newValue == newPassword {
                                                HapticManager.success()
                                            }
                                        }
                                } else {
                                    SecureField("Confirm new password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .onChange(of: confirmPassword) { _, newValue in
                                            if !newValue.isEmpty && newValue == newPassword {
                                                HapticManager.success()
                                            }
                                        }
                                }
                            }
                        }
                        .padding()
                        .background(Color.customInputBackground)
                        .cornerRadius(8)
                        
                        // Password matching validation
                        HStack {
                            Image(systemName: !confirmPassword.isEmpty && newPassword == confirmPassword ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(!confirmPassword.isEmpty && newPassword == confirmPassword ? .green : .gray)
                            Text("Passwords match")
                                .font(.caption)
                                .foregroundStyle(Color.customText.opacity(0.7))
                        }
                        .padding(.leading, 4)
                    }
                    
                    Button(action: {
                        HapticManager.mediumImpact()
                        print("Update password button tapped for email:", email)
                        Task {
                            await updatePassword()
                        }
                    }) {
                        Text(buttonTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.customButton)
                    )
                    .padding(.top, 16)
                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || !passwordValidation.isValid || newPassword != confirmPassword)
                    .opacity(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || !passwordValidation.isValid || newPassword != confirmPassword ? 0.7 : 1)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.customBackground)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: {
                        HapticManager.lightImpact()
                        onCancel()
                    })
                        .foregroundStyle(Color.customButton)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    HapticManager.error()
                    showError = false
                }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    HapticManager.success()
                    onSave()
                }
            } message: {
                Text("Your password has been updated successfully")
            }
            .onAppear {
                focusedField = .currentPassword
                print("AdminPasswordResetView appeared for email:", email)
            }
        }
    }
}
