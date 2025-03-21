import SwiftUI

struct MemberLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showingOTPView = false
    @State private var otpCode = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var showPasswordReset = false
    @State private var passwordResetOTP = ""
    @FocusState private var focusedField: Field?
    
    // For password reset
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isNewPasswordVisible = false
    
    // Reference to the email service
    private let emailService = EmailService.shared
    
    @AppStorage("isMemberLoggedIn") private var isMemberLoggedIn = false
    @Environment(\.colorScheme) private var colorScheme
    
    private enum Field {
        case email, password
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section with greeting
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.customText)
                    
                    Text("Sign in to continue your reading journey")
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
                    
                    TextField("your.email@example.com", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
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
                    
                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(CustomTextFieldStyle())
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onSubmit {
                            attemptLogin()
                        }
                }
                
                // Error message if any
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Sign In Button
                Button(action: attemptLogin) {
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
                
                // Forgot password and sign up links
                HStack {
                    Button("Forgot Password?") {
                        resetEmail = email // Pre-fill with current email if available
                        showForgotPassword = true
                    }
                    .foregroundColor(Color.customButton)
                    .font(.subheadline)
                    
                    Spacer()
                    
                    NavigationLink(destination: SignUp()) {
                        HStack(spacing: 4) {
                            Text("New user?")
                                .foregroundStyle(Color.customText.opacity(0.7))
                                .font(.subheadline)
                            
                            Text("Create Account")
                                .foregroundColor(Color.customButton)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.top, 12)
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
        .sheet(isPresented: $showForgotPassword) {
            PasswordResetRequestView(
                email: $resetEmail,
                passwordResetOTP: $passwordResetOTP,
                onRequestReset: handleForgotPassword,
                onVerifyOTP: {
                    // When OTP is verified, close this sheet and show password reset sheet
                    showForgotPassword = false
                    // Small delay to ensure smooth transition between sheets
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPasswordReset = true
                    }
                }
            )
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView(
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isNewPasswordVisible: $isNewPasswordVisible,
                title: "Reset Password",
                message: "Please enter your new password",
                buttonTitle: "Reset Password",
                onSave: {
                    // Validation
                    if newPassword.isEmpty || confirmPassword.isEmpty {
                        errorMessage = "Please enter a new password"
                        return
                    }
                    
                    if newPassword != confirmPassword {
                        errorMessage = "Passwords don't match"
                        return
                    }
                    
                    // Update password in Supabase
                    Task {
                        do {
                            let client = SupabaseManager.shared.client
                            
                            let response = try await client.database
                                .from("Members")
                                .update(["password": newPassword])
                                .eq("email", value: resetEmail)
                                .execute()
                            
                            DispatchQueue.main.async {
                                showPasswordReset = false
                                password = newPassword
                                errorMessage = "Password reset successful. Please sign in."
                            }
                        } catch {
                            DispatchQueue.main.async {
                                errorMessage = "Failed to reset password: \(error.localizedDescription)"
                            }
                        }
                    }
                },
                onCancel: {
                    showPasswordReset = false
                }
            )
        }
        .onAppear {
            focusedField = .email
        }
    }
    
    private func attemptLogin() {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please enter both email and password"
            return
        }
        
        // Hide keyboard
        focusedField = nil
        
        isLoading = true
        print("Attempting login for email: \(email)")
        
        // Check credentials in Supabase
        Task {
            do {
                let client = SupabaseManager.shared.client
                
                let response = try await client.database
                    .from("Members")
                    .select()
                    .eq("email", value: email)
                    .single()
                    .execute()
                
                print("Supabase response data: \(String(describing: response.data))")
                
                if let jsonString = String(data: response.data, encoding: .utf8) {
                    print("JSON String: \(jsonString)")
                    
                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            let member = try JSONDecoder().decode(MemberResponse.self, from: jsonData)
                            print("Successfully decoded member: \(member)")
                            
                            DispatchQueue.main.async {
                                // Check if password matches
                                if member.password == self.password {
                                    // Password matches, proceed with OTP verification
                                    Task {
                                        await self.sendVerificationEmail()
                                    }
                                } else {
                                    self.isLoading = false
                                    self.errorMessage = "Invalid email or password"
                                }
                            }
                        } catch {
                            print("JSON Decoding error: \(error)")
                            DispatchQueue.main.async {
                                self.isLoading = false
                                self.errorMessage = "Error decoding user data"
                            }
                        }
                    } else {
                        print("Failed to convert JSON string to data")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessage = "Error processing response"
                        }
                    }
                } else {
                    print("Failed to convert response data to string")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "No account found with this email"
                    }
                }
            } catch {
                print("Login error: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Login failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func sendVerificationEmail() async {
        isLoading = true
        let sent = await emailService.sendOTPEmail(to: email)
        
        DispatchQueue.main.async {
            self.isLoading = false
            if sent {
                self.showingOTPView = true
                self.errorMessage = ""
            } else {
                self.errorMessage = "Failed to send verification code"
            }
        }
    }
    
    private func verifyOTP() {
        print("Verifying OTP: \(otpCode) for email: \(email)")
        
        if emailService.verifyOTP(email: email, code: otpCode) {
            print("OTP verified successfully for member: \(email)")
            emailService.clearOTP(for: email)
            
            // Set member logged in flag to true
            isMemberLoggedIn = true
            
            // Dismiss the OTP sheet
            showingOTPView = false
        } else {
            print("OTP verification failed: \(otpCode)")
            errorMessage = "Invalid verification code"
        }
    }
    
    private func handleForgotPassword() {
        if !resetEmail.isEmpty {
            // Send password reset OTP email
            Task {
                let (sent, resetCode) = await emailService.sendPasswordResetOTP(to: resetEmail)
                
                DispatchQueue.main.async {
                    if sent {
                        print("Password reset OTP sent: \(resetCode)")
                        // Don't dismiss the sheet here - let the user enter the OTP
                        self.email = self.resetEmail // Set the login email to match reset email
                    } else {
                        self.errorMessage = "Failed to send verification code"
                    }
                }
            }
        }
    }
}

// Password Reset Request View
struct PasswordResetRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var email: String
    @Binding var passwordResetOTP: String
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var otpSent = false
    @State private var verifyingOTP = false
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isOTPFocused: Bool
    
    // Reference to the email service
    private let emailService = EmailService.shared
    
    let onRequestReset: () -> Void
    let onVerifyOTP: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 70))
                    .foregroundStyle(Color.customButton)
                    .padding(.bottom, 10)
                
                Text(otpSent ? "Verify Code" : "Reset Password")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !otpSent {
                    Text("Enter your email address and we'll send you a verification code to reset your password")
                        .font(.subheadline)
                        .foregroundStyle(Color.customText.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                    
                    TextField("Email address", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($isEmailFocused)
                } else {
                    Text("Enter the verification code sent to \(email)")
                        .font(.subheadline)
                        .foregroundStyle(Color.customText.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                    
                    TextField("Verification code", text: $passwordResetOTP)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.numberPad)
                        .focused($isOTPFocused)
                        .onChange(of: passwordResetOTP) { newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                passwordResetOTP = String(newValue.prefix(6))
                            }
                            // Allow only digits
                            passwordResetOTP = newValue.filter { $0.isNumber }
                        }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(Color.red)
                        .font(.caption)
                }
                
                Button(action: {
                    if otpSent {
                        // Verify OTP
                        verifyingOTP = true
                        if emailService.verifyOTP(email: email, code: passwordResetOTP) {
                            // OTP verified, proceed to password reset
                            emailService.clearOTP(for: email)
                            onVerifyOTP()
                        } else {
                            // Invalid OTP
                            errorMessage = "Invalid verification code"
                            verifyingOTP = false
                        }
                    } else {
                        // Request reset email
                        if email.isEmpty {
                            errorMessage = "Please enter your email address"
                            return
                        }
                        
                        isLoading = true
                        onRequestReset()
                        
                        // After sending email
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isLoading = false
                            otpSent = true
                            isOTPFocused = true
                        }
                    }
                }) {
                    if isLoading || verifyingOTP {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(otpSent ? "Verify" : "Send Verification Code")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 15)
                .background(Color.customButton)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isLoading || verifyingOTP || (!otpSent && email.isEmpty) || (otpSent && passwordResetOTP.isEmpty))
                
                if otpSent {
                    Button("Resend Code") {
                        passwordResetOTP = ""
                        onRequestReset()
                    }
                    .foregroundColor(Color.customButton)
                    .font(.subheadline)
                    .padding(.top, 8)
                    .disabled(isLoading)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .background(Color.customBackground)
            .navigationTitle(otpSent ? "Verify Code" : "Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isEmailFocused = true
            }
        }
    }
}

// Add Member struct for decoding response
private struct MemberResponse: Codable {
    let email: String
    let password: String
    let name: String
    let gender: String
    
    private enum CodingKeys: String, CodingKey {
        case email, password, name, gender
    }
}

#Preview {
    NavigationView {
        MemberLoginView()
    }
}
