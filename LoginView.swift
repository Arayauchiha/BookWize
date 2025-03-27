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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section with greeting
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(roleTitle) Login")
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
                }
                
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundStyle(Color.customText.opacity(0.7))
                    
                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
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
                .background(!email.isEmpty && !password.isEmpty ? Color.customButton : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.top, 8)
                
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
                    .padding(.top, 12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("library_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
            }
        }
        .background(Color.customBackground)
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
            
            let data: [FetchData] = try! await SupabaseManager.shared.client
                .from("Users")
                .select("*")
                .eq("email", value: email)
                .eq("password", value: password)
                .execute()
                .value
            
            if !data.isEmpty {
                let fetchedData = data[0]
                if fetchedData.vis {
                    sendVerificationOTP()
                } else {
                    showingPasswordChangeView = true
                }
            } else {
                isLoading = false
                errorMessage = "Invalid email or password"
                return
            }
            
            isLoading = false
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
        // OTP verified
        EmailService.shared.clearOTP(for: email)
        showingOTPView = false
        
        // Set login state based on role
        switch userRole {
        case .admin:
            isAdminLoggedIn = true
        case .librarian:
            Task {
                try! await SupabaseManager.shared.client
                    .from("Users")
                    .update(["status": "working"])
                    .eq("email", value: email)
                    .execute()
            }
            isLibrarianLoggedIn = true
        case .member:
            isMemberLoggedIn = true
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(userRole: .member)
    }
}
