import SwiftUI

struct AdminLoginView: View {

    // MARK: Internal

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Welcome section
                    VStack(spacing: 12) {
                        Text("Welcome, Admin")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.customText)

                        Text("Please sign in to continue")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.customText.opacity(0.6))
                    }
                    .padding(.top, 50)

                    // Login fields
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundStyle(Color.customText.opacity(0.6))

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
                                .foregroundStyle(Color.customText.opacity(0.6))

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
                                        .foregroundStyle(Color.customText.opacity(0.6))
                                }
                            }
                            .padding(12)
                            .background(Color.customInputBackground)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Show forgot password only if user has set custom password
                    if hasCustomPassword {
                        Button("Forgot Password?") {
                            if email.isEmpty {
                                alertType = .error("Please enter your email first")
                                return
                            }
                            showOTPVerification = true
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.customButton)
                        .padding(.top, 10)
                    }

                    // Login button with darker color
                    Button(action: handleLogin) {
                        Text("Login")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.customInputBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.customButton)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .background(Color.customBackground)
            .navigationDestination(isPresented: $navigateToAdminDashboard) {
                AdminDashboardView()
            }
            .sheet(isPresented: $showPasswordChangeSheet) {
                PasswordResetView(
                    newPassword: $newPassword,
                    confirmPassword: $confirmPassword,
                    isNewPasswordVisible: $isNewPasswordVisible,
                    title: hasCustomPassword ? "Reset Password" : "Set New Password",
                    message: hasCustomPassword ? "Enter your new password" : "Please change the default password for security",
                    buttonTitle: hasCustomPassword ? "Reset Password" : "Set Password",
                    onSave: handlePasswordChange,
                    onCancel: { showPasswordChangeSheet = false }
                )
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showOTPVerification) {
                OTPVerificationView(
                    email: email,
                    otp: $otp,
                    onVerify: handleOTPVerification,
                    onCancel: { showOTPVerification = false }
                )
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
            }
            .alert(alertType?.title ?? "", isPresented: .constant(alertType != nil)) {
                Button("OK") { alertType = nil }
            } message: {
                Text(alertType?.message ?? "")
            }
        }
    }

    // MARK: Private

    @Environment(\.dismiss) private var dismiss
    @AppStorage("isAdminLoggedIn") private var isAdminLoggedIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    @State private var showPasswordChangeSheet = false
    @State private var isPasswordVisible = false
    @State private var navigateToAdminDashboard = false

    // Password change states
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isNewPasswordVisible = false

    // OTP states
    @State private var showOTPVerification = false
    @State private var otp = ""

    // Mock user state (in real app, this would be in UserDefaults/Backend)
    @State private var hasCustomPassword = false
    @State private var alertType: AlertType?

    // Constants
    private let defaultEmail = "ss0854850@gmail.com"
    private let defaultPassword = "admin@12345"

    private enum Field {
        case email
        case password
    }

    private enum AlertType: Identifiable {
        case error(String)
        case success(String)

        var id: String {
            switch self {
            case .error: return "error"
            case .success: return "success"
            }
        }

        var title: String {
            switch self {
            case .error: return "Error"
            case .success: return "Success"
            }
        }

        var message: String {
            switch self {
            case .error(let message), .success(let message): return message
            }
        }
    }

    private func handleLogin() {
        if email.isEmpty || password.isEmpty {
            alertType = .error("Please fill in all fields")
            return
        }

        if email != defaultEmail {
            alertType = .error("Email not recognized")
            return
        }

        // First time login with default password
        if !hasCustomPassword && password == defaultPassword {
            showPasswordChangeSheet = true
            return
        }

        // Login with custom password
        if hasCustomPassword {
            isAdminLoggedIn = true
            dismiss()
            navigateToAdminDashboard = true
            return
        }

        alertType = .error("Invalid credentials")
    }

    private func handlePasswordChange() {
        if newPassword.count < 8 {
            alertType = .error("Password must be at least 8 characters")
            return
        }

        if newPassword != confirmPassword {
            alertType = .error("Passwords do not match")
            return
        }

        // Here you would update password in backend
        hasCustomPassword = true
        password = newPassword
        showPasswordChangeSheet = false
        alertType = .success("Password updated successfully")
        newPassword = ""
        confirmPassword = ""
    }

    private func handleOTPVerification() {
        if otp.count != 6 {
            alertType = .error("Please enter a valid 6-digit OTP")
            return
        }

        // Here you would verify OTP with backend
        showOTPVerification = false
        showPasswordChangeSheet = true
    }
}

#Preview {
    AdminLoginView()
        .environment(\.colorScheme, .light)
}
