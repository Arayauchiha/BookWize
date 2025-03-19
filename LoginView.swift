import SwiftUI

enum UserRole {
    case admin
    case librarian
    case member
    
    var title: String {
        switch self {
        case .admin: return "Admin"
        case .librarian: return "Librarian"
        case .member: return "Member"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .admin: return .adminColor
        case .librarian: return .librarianColor
        case .member: return .memberColor
        }
    }
    
    var showsCreateAccount: Bool {
        switch self {
        case .admin, .librarian: return false
        case .member: return true
        }
    }
    
    var requiresInitialPasswordReset: Bool {
        switch self {
        case .admin, .librarian: return true
        case .member: return false
        }
    }
}

struct LoginView: View {
    let userRole: UserRole
    
    // MARK: - States
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isAdminLoggedIn") private var isAdminLoggedIn = false
    @AppStorage("isLibrarianLoggedIn") private var isLibrarianLoggedIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    @State private var showPasswordChangeSheet = false
    @State private var isPasswordVisible = false
    @State private var navigateToApp = false
    @State private var showCreateAccount = false

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
    @State private var showPassword = false
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var showSignup = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Welcome section
                    VStack(spacing: 12) {
                        Text("Welcome, \(userRole.title)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.customText)

                        Text("Please sign in to continue")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.customText.opacity(0.6))
                    }
                    .padding(.top, 50)

                    // Login fields
                    VStack(spacing: 20) {
                        emailField
                        passwordField
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
                        .foregroundStyle(userRole.accentColor)
                        .padding(.top, 10)
                    }

                    // Login button
                    Button(action: handleLogin) {
                        Text("Login")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.customButton)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Add divider and create account section for members
                    if userRole == .member {
                        VStack(spacing: 16) {
                            HStack {
                                Rectangle()
                                    .fill(Color.customText.opacity(0.2))
                                    .frame(height: 1)
                                
                                Text("or")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.customText.opacity(0.6))
                                
                                Rectangle()
                                    .fill(Color.customText.opacity(0.2))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 20)
                            
                            NavigationLink {
                                SignupView()  // Replace with actual view
                            } label: {
                                Text("Create Account")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color.memberColor)
                            }
                        }
                        .padding(.top, 10)
                    }
                }
                
        }
            .padding()
            .sheet(isPresented: $showSignup) {
                SignupView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .background(Color.customBackground)
            .navigationDestination(isPresented: $navigateToApp) {
                switch userRole {
                case .admin: AdminDashboardView()
                case .librarian: Text("Librarian Dashboard") // Replace with actual view
                case .member: Text("Member Dashboard") // Replace with actual view
                }
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
    
    // MARK: - Components
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.subheadline)
                .foregroundStyle(Color.customText.opacity(0.6))

            TextField("Enter your email", text: $email)
                .textFieldStyle(CustomTextFieldStyle())
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.subheadline)
                .foregroundStyle(Color.customText.opacity(0.6))

            HStack {
                Group {
                    if isPasswordVisible {
                        TextField("Enter your password", text: $password)
                    } else {
                        SecureField("Enter your password", text: $password)
                    }
                }
                .textContentType(.password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(Color.customText.opacity(0.6))
                }
            }
            .padding(12)
            .background(Color.customInputBackground)
            .cornerRadius(8)
        }
    }

    // MARK: - Actions
    private func handleLogin() {
        if email.isEmpty || password.isEmpty {
            alertType = .error("Please fill in all fields")
            return
        }

        switch userRole {
        case .admin:
            handleAdminLogin()
        case .librarian:
            handleLibrarianLogin()
        case .member:
            handleMemberLogin()
        }
    }
    
    private func handleAdminLogin() {
        let defaultEmail = "ss0854850@gmail.com"
        let defaultPassword = "admin@12345"
        
        if email != defaultEmail {
            alertType = .error("Email not recognized")
            return
        }

        if !hasCustomPassword && password == defaultPassword {
            showPasswordChangeSheet = true
            return
        }

        if hasCustomPassword {
            isAdminLoggedIn = true
            dismiss()
            navigateToApp = true
            return
        }

        alertType = .error("Invalid credentials")
    }
    
    private func handleLibrarianLogin() {
        // Example credentials - in real app these would be verified against database
        if !hasCustomPassword && userRole.requiresInitialPasswordReset {
            showPasswordChangeSheet = true
            return
        }
        
        // Verify credentials here
        navigateToApp = true
    }

    private func handleMemberLogin() {
        // For members, just verify credentials and login
        // Example member verification - replace with actual verification
        if email == "member@example.com" && password == "memberpass" {
            navigateToApp = true
        } else {
            alertType = .error("Invalid credentials")
        }
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

        showOTPVerification = false
        showPasswordChangeSheet = true
    }
}

// MARK: - Supporting Types
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

//MARK: - Forget Password View
struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.title)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal)
                
                Button("Send Reset Link") {
                    // TODO: Implement password reset
                    dismiss()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

#Preview {
    LoginView(userRole: .admin)
        .environment(\.colorScheme, .light)
}
