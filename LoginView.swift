//
//  LoginView.swift
//  BookWize
//
//  Created by Aditya Singh on 18/03/25.
//

import SwiftUI

enum UserRole: String, Codable {
    case admin
    case librarian
    case member
}

struct LoginView: View {
    let userRole: UserRole
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingOTPView = false
    @State private var otpCode = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var emailError: String?
    @State private var showingForgotPassword = false
    @FocusState private var focusedField: Field?
    
    // For first-time librarian login
    @State private var isFirstLogin = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingPasswordChangeView = false
    @State private var isNewPasswordVisible = false
    
    @AppStorage("isAdminLoggedIn") private var isAdminLoggedIn = false
    @AppStorage("isLibrarianLoggedIn") private var isLibrarianLoggedIn = false
    private enum Field {
        case email, password
    }
    @AppStorage("isMemberLoggedIn") private var isMemberLoggedIn = false
    
    @State private var isPasswordVisible = false
    
    private var isEmailValid: Bool {
        ValidationUtils.isValidEmail(email)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section with greeting
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hello, Librarian!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(roleColor)
                    
                    Text("Sign in to manage your library system")
                        .font(.subheadline)
                        .foregroundStyle(Color.customText.opacity(0.7))
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
                
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline)
                        .foregroundStyle(Color.customText.opacity(0.7))
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .customTextField()
                        .onChange(of: email) { newValue in
                            if !newValue.isEmpty && !isEmailValid {
                                emailError = "Please enter a valid email address"
                            } else {
                                emailError = nil
                            }
                        }
                    
                    if let error = emailError {
                        Text(error)
                            .foregroundStyle(Color.red)
                            .font(.caption)
                    }
                }
                
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundStyle(Color.customText.opacity(0.7))
                    
                    ZStack(alignment: .trailing) {
                        Group {
                            if isPasswordVisible {
                                TextField("Enter your password", text: $password)
                                    .textContentType(.password)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("Enter your password", text: $password)
                                    .textContentType(.password)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
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
                        
                        Button(action: { isPasswordVisible.toggle() }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(Color.blue.opacity(0.6))
                                .padding(.trailing, 12)
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(Color.red)
                        .font(.caption)
                }
                
                Button(action: login) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isFormValid ? roleColor : Color.gray)
                .foregroundStyle(.white)
                .cornerRadius(12)
                .disabled(!isFormValid || isLoading)
                
                if userRole == .librarian {
                    Button("Forgot Password?") {
                        if !email.isEmpty && isEmailValid {
                            // Send OTP and show OTP view first
                            showingForgotPassword = true
                            sendVerificationOTP()
                            showingOTPView = true
                        } else {
                            errorMessage = "Please enter a valid email address first"
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.customButton)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
        }
        .background(Color.customBackground)
        .sheet(isPresented: $showingPasswordChangeView) {
            // Password change sheet for librarian first login
            PasswordResetView(
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isNewPasswordVisible: $isNewPasswordVisible,
                email: email,
                title: "Create New Password",
                message: "Please set a new password for your account",
                buttonTitle: "Set Password",
                onSave: {
                    if newPassword.isEmpty || confirmPassword.isEmpty {
                        errorMessage = "Passwords cannot be empty"
                        return
                    }
                    
                    if newPassword != confirmPassword {
                        errorMessage = "Passwords don't match"
                        return
                    }
                    
                    // Update password in Supabase
                    Task {
                        do {
                            let userData: [String: String] = ["password": newPassword, "vis": "true"]
                            try await SupabaseManager.shared.client
                                .from("Users")
                                .update(userData)
                                .eq("email", value: email)
                                .execute()
                            
                            // Update status to working after password reset
                            let statusData: [String: String] = ["status": "working"]
                            try await SupabaseManager.shared.client
                                .from("Users")
                                .update(statusData)
                                .eq("email", value: email)
                                .execute()
                            
                            DispatchQueue.main.async {
                                password = newPassword
                                showingPasswordChangeView = false
                                isLibrarianLoggedIn = true
                                UserDefaults.standard.set(email, forKey: "currentMemberEmail")
                            }
                        } catch {
                            DispatchQueue.main.async {
                                errorMessage = "Failed to update password: \(error.localizedDescription)"
                            }
                        }
                    }
                },
                onCancel: {
                    showingPasswordChangeView = false
                }
            )
        }
        .sheet(isPresented: $showingOTPView) {
            OTPVerificationView(
                email: email,
                otp: $otpCode,
                onVerify: {
                    if showingForgotPassword {
                        // For forgot password flow
                        verifyOTP()
                    } else {
                        // For normal login flow
                        verifyOTP()
                    }
                },
                onCancel: {
                    showingOTPView = false
                    if showingForgotPassword {
                        showingForgotPassword = false
                    }
                }
            )
        }
        .sheet(isPresented: $showingForgotPassword) {
            PasswordResetView(
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isNewPasswordVisible: $isNewPasswordVisible,
                email: email,
                title: "Reset Password",
                message: "Please enter a new password for your account",
                buttonTitle: "Reset Password",
                onSave: {
                    if newPassword.isEmpty || confirmPassword.isEmpty {
                        errorMessage = "Passwords cannot be empty"
                        return
                    }
                    
                    if newPassword != confirmPassword {
                        errorMessage = "Passwords don't match"
                        return
                    }
                    
                    // Update password in Supabase
                    Task {
                        do {
                            let userData: [String: String] = ["password": newPassword]
                            try await SupabaseManager.shared.client
                                .from("Users")
                                .update(userData)
                                .eq("email", value: email)
                                .execute()
                            
                            DispatchQueue.main.async {
                                showingForgotPassword = false
                                errorMessage = "Password has been reset successfully. Please login with your new password."
                                password = ""
                            }
                        } catch {
                            DispatchQueue.main.async {
                                errorMessage = "Failed to reset password: \(error.localizedDescription)"
                            }
                        }
                    }
                },
                onCancel: {
                    showingForgotPassword = false
                }
            )
        }
        .onAppear {
            focusedField = .email
        }
    }
    
    var roleColor: Color {
        switch userRole {
        case .admin:
            return Color.adminColor
        case .librarian:
            return Color.librarianColor
        case .member:
            return Color.memberColor
        }
    }
    
    var roleTitle: String {
        switch userRole {
        case .admin:
            return "Admin"
        case .librarian:
            return "Librarian"
        case .member:
            return "Member"
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    func login() {
        Task {
            isLoading = true
            
            // Simple validation
            if email.isEmpty || password.isEmpty {
                isLoading = false
                errorMessage = "Please enter both email and password"
                return
            }
            do {
                let data: [FetchData] = try await SupabaseManager.shared.client
                    .from("Users")
                    .select("*")
                    .eq("email", value: email)
                    .eq("password", value: password)
                    .eq("roleFetched", value: "librarian")
                    .execute()
                    .value
                
                DispatchQueue.main.async {
                    if data.isEmpty {
                        isLoading = false
                        errorMessage = "Invalid email or password"
                    } else {
                        let fetchedData = data[0]
                        if !fetchedData.vis {
                            // Only show password change for first-time login
                            isLoading = false
                            showingPasswordChangeView = true
                        } else {
                            // For normal login, proceed with OTP verification
                            sendVerificationOTP()
                        }
                    }
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Invalid email or password"
                }
            }
        }
    }
    
    func sendVerificationOTP() {
        Task {
            isLoading = true
            let sent = await EmailService.shared.sendOTPEmail(to: email)
            
            DispatchQueue.main.async {
                isLoading = false
                if sent {
                    showingOTPView = true
                    errorMessage = ""
                } else {
                    errorMessage = "Failed to send verification code"
                }
            }
        }
    }
    
    func verifyOTP() {
        if EmailService.shared.verifyOTP(email: email, code: otpCode) {
            // OTP verified
            EmailService.shared.clearOTP(for: email)
            
            // Set login state based on role
            switch userRole {
            case .admin:
                isAdminLoggedIn = true
                showingOTPView = false
            case .librarian:
                if showingForgotPassword {
                    // For forgot password flow, show password reset view
                    showingOTPView = false
                    showingForgotPassword = true
                } else {
                    // For normal login, just set logged in state
                    isLibrarianLoggedIn = true
                    UserDefaults.standard.set(email, forKey: "currentMemberEmail")
                    showingOTPView = false
                }
            case .member:
                isMemberLoggedIn = true
                showingOTPView = false
            }
        } else {
            errorMessage = "Invalid verification code"
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(userRole: .librarian)
    }
}
