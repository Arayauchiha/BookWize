//
//  AdminLoginView.swift
//  BookWize
//
//  Created by Aditya Singh on 18/03/25.
//

import SwiftUI

struct AdminLoginView: View {
    @State private var email = "ss0854850@gmail.com"
    @State private var password = "admin@12345"
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isNewPasswordVisible = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var verificationCode = ""
    @FocusState private var focusedField: Field?
    
    @State private var showPasswordChange = false
    @State private var showVerification = false
    
    @AppStorage("isAdminLoggedIn") private var isAdminLoggedIn = false
    @AppStorage("isFirstAdminLogin") private var isFirstAdminLogin = true
    @AppStorage("adminEmail") private var adminEmail = "ss0854850@gmail.com"
    @AppStorage("adminPassword") private var adminPassword = "admin@12345"
    
    private enum Field {
        case email, password
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with greeting
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hello, Admin!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.adminColor)
                    
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
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                }
                
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundStyle(Color.customText.opacity(0.7))
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(CustomTextFieldStyle())
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onSubmit {
                            login()
                        }
                }
                
                // Error message if any
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Sign In Button
                Button(action: login) {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Spacer()
                        }
                    } else {
                        Text("Sign In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 15)
                .background(Color.customButton)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("library_logo") // Replace with your app's logo if available
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
            }
        }
        .background(Color.customBackground)
        .sheet(isPresented: $showPasswordChange) {
            PasswordResetView(
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isNewPasswordVisible: $isNewPasswordVisible,
                title: "Create New Password",
                message: "Please set a new password for your admin account",
                buttonTitle: "Set Password",
                onSave: {
                    if newPassword.isEmpty || confirmPassword.isEmpty {
                        errorMessage = "Passwords cannot be empty"
                        return
                    }
                    
                    if newPassword != confirmPassword {
                        errorMessage = "Passwords do not match"
                        return
                    }
                    
                    // Update admin password
                    adminPassword = newPassword
                    isFirstAdminLogin = false
                    showPasswordChange = false
                    
                    // Proceed to email verification
                    sendVerificationOTP()
                },
                onCancel: {
                    showPasswordChange = false
                }
            )
        }
        .sheet(isPresented: $showVerification) {
            OTPVerificationView(
                email: email,
                otp: $verificationCode,
                onVerify: {
                    verifyOTP()
                },
                onCancel: {
                    showVerification = false
                }
            )
        }
        .onAppear {
            focusedField = .email
        }
    }
    
    func login() {
        // Hide keyboard
        focusedField = nil
        
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please enter both email and password"
            return
        }
        
        isLoading = true
        
        // Validate admin credentials
        if email == adminEmail && password == adminPassword {
            if isFirstAdminLogin {
                // First login - require password change
                isLoading = false
                showPasswordChange = true
            } else {
                // Not first login - send verification OTP
                sendVerificationOTP()
            }
        } else {
            isLoading = false
            errorMessage = "Invalid credentials"
        }
    }
    
    func sendVerificationOTP() {
        Task {
            let success = await EmailService.shared.sendOTPEmail(to: email)
            
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    showVerification = true
                    errorMessage = ""
                } else {
                    errorMessage = "Failed to send verification code"
                }
            }
        }
    }
    
    func verifyOTP() {
        print("Admin verifying OTP: \(verificationCode)")
        
        if EmailService.shared.verifyOTP(email: email, code: verificationCode) {
            print("Admin OTP verified successfully")
            // Clear OTP from storage
            EmailService.shared.clearOTP(for: email)
            
            // Set admin logged in flag to true
            isAdminLoggedIn = true
            
            // Close verification sheet
            showVerification = false
        } else {
            print("Admin OTP verification failed")
            errorMessage = "Invalid verification code"
        }
    }
}

#Preview {
    NavigationView {
        AdminLoginView()
    }
}
