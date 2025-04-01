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
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("Enter your password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        } else {
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(Color.gray)
                        }
                        .padding(.trailing, 8)
                    }
                    .background(Color.customInputBackground)
                    .cornerRadius(10)
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
                .background(!email.isEmpty && !password.isEmpty && isEmailValid ? Color.customButton : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isLoading || email.isEmpty || password.isEmpty || !isEmailValid)
                .padding(.top, 8)
                
                //                if userRole == .member {
                //                    HStack {
                //                        NavigationLink("Create Account") {
                //                            SignUp()
                //                        }
                //                        .foregroundColor(Color.customButton)
                //
                //                        Spacer()
                //
                //                        Button("Forgot Password?") {
                //                            // Handle password reset
                //                            if !email.isEmpty {
                //                                sendVerificationOTP()
                //                            } else {
                //                                errorMessage = "Please enter your email first"
                //                            }
                //                        }
                //                        .foregroundColor(Color.customButton)
                //                    }
                //                    .padding(.top, 12)
                //                }
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
        //        .background(Color.customBackground)
        //        .sheet(isPresented: $showingOTPView) {
        //            // Use the consistent OTP verification view
        //            OTPVerificationView(
        //                email: email,
        //                otp: $otpCode,
        //                onVerify: {
        //                    verifyOTP()
        //                },
        //                onCancel: {
        //                    showingOTPView = false
        //                }
        //            )
        //        }
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
        .sheet(isPresented: $showingOTPView) {
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
                            isLoading = false
                            showingPasswordChangeView = true
                        } else {
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
            isLibrarianLoggedIn = true
            UserDefaults.standard.set(email, forKey: "currentMemberEmail")
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
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(userRole: .librarian)
    }
}
