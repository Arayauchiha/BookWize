import SwiftUI

struct AdminLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    @State private var showPasswordChangeSheet = false
    @State private var showError = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isPasswordVisible = false
    
    // Password change states
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isNewPasswordVisible = false
    
    // OTP states
    @State private var showOTPVerification = false
    @State private var otp = ""
    
    // Mock user state (in real app, this would be in UserDefaults/Backend)
    @State private var hasCustomPassword = false
    
    // Constants
    private let defaultEmail = "ss0854850@gmail.com"
    private let defaultPassword = "admin@12345"
    private let buttonColor = Color(hex: "2C1810")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Welcome section
                VStack(spacing: 12) {
                    Text("Welcome, Admin")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("Please sign in to continue")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 50)
                
                // Login fields
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // Password field with visibility toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            if isPasswordVisible {
                                TextField("Enter your password", text: $password)
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("Enter your password", text: $password)
                                    .textContentType(.password)
                            }
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(buttonColor.opacity(0.6))
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                
                // Show forgot password only if user has set custom password
                if hasCustomPassword {
                    Button("Forgot Password?") {
                        if email.isEmpty {
                            errorMessage = "Please enter your email first"
                            showError = true
                            return
                        }
                        showOTPVerification = true
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(buttonColor)
                    .padding(.top, 10)
                }
                
                // Login button with darker color
                Button(action: handleLogin) {
                    Text("Login")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(buttonColor)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .background(Color(hex: "F5EBE0"))
        
        // Sheet for first-time password change or regular password reset
        .sheet(isPresented: $showPasswordChangeSheet) {
            PasswordResetView(
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isNewPasswordVisible: $isNewPasswordVisible,
                title: hasCustomPassword ? "Reset Password" : "Set New Password",
                message: hasCustomPassword ? "Enter your new password" : "Please change the default password for security",
                buttonTitle: hasCustomPassword ? "Reset Password" : "Set Password",
                buttonColor: buttonColor,
                onSave: handlePasswordChange,
                onCancel: { showPasswordChangeSheet = false }
            )
            .background(Color(hex: "F5EBE0"))
            .interactiveDismissDisabled()
        }
        
        // Sheet for OTP verification
        .sheet(isPresented: $showOTPVerification) {
            OTPVerificationView(
                email: email,
                otp: $otp,
                buttonColor: buttonColor,
                onVerify: handleOTPVerification,
                onCancel: { showOTPVerification = false }
            )
            .background(Color(hex: "F5EBE0"))
            .interactiveDismissDisabled()
        }
        
        // Error alert
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        
        // Success alert
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
    }
    
    private func handleLogin() {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        if email != defaultEmail {
            errorMessage = "Email not recognized"
            showError = true
            return
        }
        
        // First time login with default password
        if !hasCustomPassword && password == defaultPassword {
            showPasswordChangeSheet = true
            return
        }
        
        // Login with custom password
        if hasCustomPassword {
            // Here you would validate against stored password
            // For demo, assume login successful
            successMessage = "Login successful"
            showSuccess = true
            return
        }
        
        errorMessage = "Invalid credentials"
        showError = true
    }
    
    private func handlePasswordChange() {
        if newPassword.count < 8 {
            errorMessage = "Password must be at least 8 characters"
            showError = true
            return
        }
        
        if newPassword != confirmPassword {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        // Here you would update password in backend
        hasCustomPassword = true
        password = newPassword
        showPasswordChangeSheet = false
        successMessage = "Password updated successfully"
        showSuccess = true
        newPassword = ""
        confirmPassword = ""
    }
    
    private func handleOTPVerification() {
        if otp.count != 6 {
            errorMessage = "Please enter a valid 6-digit OTP"
            showError = true
            return
        }
        
        // Here you would verify OTP with backend
        showOTPVerification = false
        showPasswordChangeSheet = true
    }
}

// Custom text field style for consistent look
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)
    }
}

// Update PasswordResetView
struct PasswordResetView: View {
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isNewPasswordVisible: Bool
    let title: String
    let message: String
    let buttonTitle: String
    let buttonColor: Color
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 16) {
                    // New password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            if isNewPasswordVisible {
                                TextField("Enter new password", text: $newPassword)
                                    .textContentType(.newPassword)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Enter new password", text: $newPassword)
                                    .textContentType(.newPassword)
                            }
                            
                            Button(action: { isNewPasswordVisible.toggle() }) {
                                Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    
                    // Confirm password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            if isNewPasswordVisible {
                                TextField("Confirm new password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Confirm new password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                
                Button(action: onSave) {
                    Text(buttonTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(buttonColor)
                        )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "F5EBE0"))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(buttonColor)
                }
            }
        }
    }
}

// Add OTP verification view
struct OTPVerificationView: View {
    let email: String
    @Binding var otp: String
    let buttonColor: Color
    let onVerify: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter the verification code sent to\n\(email)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                // OTP field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verification Code")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField("Enter 6-digit code", text: $otp)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                Button(action: onVerify) {
                    Text("Verify")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(buttonColor)
                        )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "F5EBE0"))
            .navigationTitle("Verify OTP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(buttonColor)
                }
            }
        }
    }
}

#Preview {
    AdminLoginView()
}
