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
    
    @AppStorage("isAdminLoggedIn") private var isAdminLoggedIn = false
    @AppStorage("isLibrarianLoggedIn") private var isLibrarianLoggedIn = false
    @AppStorage("isMemberLoggedIn") private var isMemberLoggedIn = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("\(roleTitle) Login")
                .font(.largeTitle)
                .fontWeight(.bold)
            
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
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(isLoading)
            
            if userRole == .member {
                HStack {
                    NavigationLink("Create Account") {
                        SignupView() // Fixed to match your actual view name
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button("Forgot Password?") {
                        // Handle password reset
                        if !email.isEmpty {
                            sendVerificationOTP()
                        } else {
                            errorMessage = "Please enter your email first"
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingOTPView) {
            // OTP verification sheet
            VStack(spacing: 20) {
                Text("Verify Your Email")
                    .font(.headline)
                
                Text("Enter the code sent to your email")
                    .font(.subheadline)
                
                TextField("Verification Code", text: $otpCode)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .keyboardType(.numberPad)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Verify") {
                    verifyOTP()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Resend Code") {
                    sendVerificationOTP()
                }
                .foregroundColor(.blue)
            }
            .padding()
        }
        .sheet(isPresented: $showingPasswordChangeView) {
            // Password change sheet for librarian first login
            VStack(spacing: 20) {
                Text("Create New Password")
                    .font(.headline)
                
                SecureField("New Password", text: $newPassword)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Set Password") {
                    if newPassword == confirmPassword && !newPassword.isEmpty {
                        // Update password would happen here
                        showingPasswordChangeView = false
                        // Send verification email
                        sendVerificationOTP()
                    } else {
                        errorMessage = "Passwords don't match or are empty"
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
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
            if email == "admin@example.com" && password == "admin123" {
                isAdminLoggedIn = true
            } else {
                errorMessage = "Invalid admin credentials"
            }
            
        case .librarian:
            // Simulate checking if this is first login
            isFirstLogin = (email == "librarian@example.com" && password == "temp123")
            
            if isFirstLogin {
                showingPasswordChangeView = true
            } else {
                // Send verification OTP
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
            let sent = await OTPManager.shared.sendOTPEmail(to: email) // Use the correct method
            
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
        if OTPManager.shared.verifyOTP(email: email, code: otpCode) {
            // OTP verified
            OTPManager.shared.clearOTP(for: email)
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
