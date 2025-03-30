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
    @State private var isPasswordVisible = false
    @State private var emailError: String?
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
    
    private var isEmailValid: Bool {
        ValidationUtils.isValidEmail(email)
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
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
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
                .background(!email.isEmpty && !password.isEmpty && isEmailValid ? Color.customButton : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isLoading || email.isEmpty || password.isEmpty || !isEmailValid)
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
                email: email,
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
                            try await SupabaseManager.shared.client
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
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func attemptLogin() {
        // Hide keyboard
        focusedField = nil
        
        isLoading = true
        print("Attempting login for email: \(email)")
        
        // Check credentials in Supabase
        Task {
            do {
                let client = SupabaseManager.shared.client
                
                let response = try await client
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
                        self.errorMessage = "Invalid email or password"
                    }
                }
            } catch {
                print("Login error: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Invalid email or password"
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
        if EmailService.shared.verifyOTP(email: email, code: otpCode) {
            // OTP verified
            EmailService.shared.clearOTP(for: email)
            
            // Set the login state without using Supabase auth
            Task {
                do {
                    // Get the member's ID from the Members table
                    let response = try await SupabaseManager.shared.client
                        .from("Members")
                        .select("id")
                        .eq("email", value: email)
                        .single()
                        .execute()
                    
                    if let jsonString = String(data: response.data, encoding: .utf8),
                       let jsonData = jsonString.data(using: .utf8) {
                        
                        struct MemberID: Codable {
                            let id: String
                        }
                        
                        if let memberId = try? JSONDecoder().decode(MemberID.self, from: jsonData) {
                            print("Successfully retrieved member ID: \(memberId.id)")
                            
                            // Store the member ID locally for future reference
                            UserDefaults.standard.set(memberId.id, forKey: "currentMemberId")
                            UserDefaults.standard.set(email, forKey: "currentMemberEmail")
                            UserDefaults.standard.set(true, forKey: "isMemberLoggedIn")
                            
                            DispatchQueue.main.async {
                                self.showingOTPView = false
                                self.isMemberLoggedIn = true
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.errorMessage = "Failed to retrieve member ID"
                                self.showingOTPView = false
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.errorMessage = "Failed to process member data"
                            self.showingOTPView = false
                        }
                    }
                } catch {
                    print("Error retrieving member ID: \(error)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Authentication failed: \(error.localizedDescription)"
                        self.showingOTPView = false
                    }
                }
            }
        } else {
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
    @State private var timeRemaining = 60
    @State private var timer: Timer?
    @State private var emailError: String?
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isOTPFocused: Bool
    
    // Reference to the email service
    private let emailService = EmailService.shared
    
    let onRequestReset: () -> Void
    let onVerifyOTP: () -> Void
    
    private var isEmailValid: Bool {
        ValidationUtils.isValidEmail(email)
    }
    
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
                        
                        if !isEmailValid {
                            errorMessage = "Please enter a valid email address"
                            return
                        }
                        
                        isLoading = true
                        onRequestReset()
                        
                        // After sending email
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isLoading = false
                            otpSent = true
                            isOTPFocused = true
                            startTimer()
                        }
                    }
                }) {
                    HStack {
                        Spacer()
                        if isLoading || verifyingOTP {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(otpSent ? "Verify" : "Send Verification Code")
                                .font(.headline)
                        }
                        Spacer()
                    }
                }
                .frame(height: 50)
                .padding(.horizontal)
                .background(otpSent ? (passwordResetOTP.isEmpty ? Color.gray : Color.customButton) : (email.isEmpty || !isEmailValid ? Color.gray : Color.customButton))
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isLoading || verifyingOTP || (!otpSent && (email.isEmpty || !isEmailValid)) || (otpSent && passwordResetOTP.isEmpty))
                
                if otpSent {
                    Button(action: {
                        if timeRemaining == 0 {
                            passwordResetOTP = ""
                            onRequestReset()
                            startTimer()
                        }
                    }) {
                        Text(timeRemaining > 0 ? "Resend code in \(timeRemaining)s" : "Resend Code")
                            .font(.subheadline)
                    }
                    .foregroundColor(timeRemaining > 0 ? Color.gray : Color.customButton)
                    .disabled(timeRemaining > 0 || isLoading)
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
                        timer?.invalidate()
                        timer = nil
                        dismiss()
                    }
                }
            }
            .onAppear {
                isEmailFocused = true
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func startTimer() {
        timeRemaining = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                timer = nil
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
