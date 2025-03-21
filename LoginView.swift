//
//  LoginView.swift
//  BookWize
//
//  Created by Aditya Singh on 18/03/25.
//

import SwiftUI

enum UserRole {
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
    
    // For first-time librarian login
    @State private var isFirstLogin = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingPasswordChangeView = false
    @State private var isNewPasswordVisible = false
    
    @AppStorage("isAdminLoggedIn") private var isAdminLoggedIn = false
    @AppStorage("isLibrarianLoggedIn") private var isLibrarianLoggedIn = false
    @AppStorage("isMemberLoggedIn") private var isMemberLoggedIn = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("\(roleTitle) Login")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(roleColor)
            
            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                login()
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color.customButton)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(isLoading)
            
            if userRole == .member {
                HStack {
                    NavigationLink("Create Account") {
                        SignUp()
                    }
                    .foregroundColor(Color.customButton)
                    
                    Spacer()
                    
                    Button("Forgot Password?") {
                        // Handle password reset
                        if !email.isEmpty {
                            sendVerificationOTP()
                        } else {
                            errorMessage = "Please enter your email first"
                        }
                    }
                    .foregroundColor(Color.customButton)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingOTPView) {
            // Use the consistent OTP verification view
            OTPVerificationView(
                email: email,
                otp: $otpCode,
                onVerify: {
                    verifyOTP()
                },
                onCancel: {
                    showingOTPView = false
                }
            )
        }
        .sheet(isPresented: $showingPasswordChangeView) {
            // Password change sheet for librarian first login
            PasswordResetView(
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isNewPasswordVisible: $isNewPasswordVisible,
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
                    
                    // Update password would happen here in a real app
                    password = newPassword
                    showingPasswordChangeView = false
                    
                    // Send verification email after password change
                    sendVerificationOTP()
                },
                onCancel: {
                    showingPasswordChangeView = false
                }
            )
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
    
    func login() {
        isLoading = true
        
        // Simple validation
        if email.isEmpty || password.isEmpty {
            isLoading = false
            errorMessage = "Please enter both email and password"
            return
        }
        
        // For demo, we'll use simple logic
        switch userRole {
        case .admin:
            // Redirect to AdminLoginView
            if email == "ss0854850@gmail.com" && password == "admin@12345" {
                isAdminLoggedIn = true
            } else {
                errorMessage = "Invalid admin credentials"
            }
            
        case .librarian:
            // Simulate checking if this is first login by checking for temp password pattern
            isFirstLogin = (email == "librarian@example.com" && password == "temp123") || 
                           password.hasPrefix("temp") || 
                           password.count < 10 // Assuming temporary passwords are shorter
            
            if isFirstLogin {
                // Show password change view for first login
                showingPasswordChangeView = true
            } else {
                // Regular login flow - send verification OTP
                sendVerificationOTP()
            }
            
        case .member:
            // For members, always send verification OTP
            sendVerificationOTP()
        }
        
        isLoading = false
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
            showingOTPView = false
            
            // Set login state based on role
            switch userRole {
            case .admin:
                isAdminLoggedIn = true
            case .librarian:
                isLibrarianLoggedIn = true
            case .member:
                isMemberLoggedIn = true
            }
        } else {
            errorMessage = "Invalid verification code"
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(userRole: .member)
    }
}
