//
//  AdminLoginView.swift
//  BookWize
//
//  Created by Aditya Singh on 18/03/25.
//

import SwiftUI

struct AdminLoginView: View {
    @State private var email = "admin@example.com"
    @State private var password = "admin123"
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingOTPView = false
    @State private var otpCode = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    @AppStorage("isAdminLoggedIn") private var isAdminLoggedIn = false
    @AppStorage("isFirstLogin") private var isFirstLogin = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Admin Login")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            
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
            .background(Color.adminColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(isLoading)
        }
        .padding()
        .sheet(isPresented: $isFirstLogin) {
            // First login password change sheet
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
                        password = newPassword
                        isFirstLogin = false
                        // Send verification email
                        sendVerificationOTP()
                    } else {
                        errorMessage = "Passwords don't match or are empty"
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.adminColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
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
                .background(Color.adminColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Resend Code") {
                    sendVerificationOTP()
                }
                .foregroundColor(.adminColor)
            }
            .padding()
        }
    }
    
    func login() {
        isLoading = true
        
        // Hardcoded admin credentials check
        if email == "admin@example.com" && password == "admin123" {
            if isFirstLogin {
                isLoading = false
                // Show password change view
                errorMessage = ""
            } else {
                // Send verification OTP
                sendVerificationOTP()
            }
        } else {
            isLoading = false
            errorMessage = "Invalid credentials"
        }
    }
    
    func sendVerificationOTP() {
        Task {
            isLoading = true
            let sent = await OTPManager.shared.sendOTPEmail(to: email)
            
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
            isAdminLoggedIn = true
        } else {
            errorMessage = "Invalid verification code"
        }
    }
}

#Preview {
    AdminLoginView()
}
