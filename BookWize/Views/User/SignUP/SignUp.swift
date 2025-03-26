import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    
    // Form fields
    @State private var name = ""
    @State private var email = ""
    @State private var gender = Gender.male
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedLibrary = "Good Reads Library"
    
    // Verification
    @State private var showVerificationView = false
    @State private var otpCode = ""
    
    // Loading and Errors
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showMembershipView = false
    @State private var selectedGenres: Set<String> = []
    
    // Field validation errors
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var confirmPasswordError: String?
    
    // Password validation state
    @State private var passwordValidation = ValidationUtils.PasswordValidation(
        hasMinLength: false,
        hasUppercase: false,
        hasLowercase: false,
        hasNumber: false,
        hasSpecialChar: false
    )
    
    let libraries = ["Good Reads Library"]
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        ValidationUtils.isValidEmail(email) &&
        passwordValidation.isValid &&
        password == confirmPassword &&
        emailError == nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.customBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.customText)
                            .padding(.bottom, 8)
                        
                        // Personal Information Section
                        sectionTitle("Personal Information")
                        
                        // Email
                        inputField(title: "Email", error: emailError) {
                            TextField("Enter your email", text: $email)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .onChange(of: email) { newValue in
                                    emailError = ValidationUtils.getEmailError(newValue)
                                }
                        }
                        
                        // Name
                        inputField(title: "Full Name", error: nil) {
                            TextField("Enter your full name", text: $name)
                        }
                        
                        // Gender
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender")
                                .font(.subheadline)
                                .foregroundStyle(Color.customText)
                            
                            Picker("Gender", selection: $gender) {
                                ForEach(Gender.allCases, id: \.self) { gender in
                                    Text(gender.rawValue).tag(gender)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(4)
                        }
                        
                        // Divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                            .padding(.vertical, 8)
                        
                        // Security Section
                        sectionTitle("Security")
                        
                        // Password
                        inputField(title: "Password", error: nil) {
                            SecureField("Enter password", text: $password)
                                .onChange(of: password) { newValue in
                                    passwordValidation = ValidationUtils.validatePassword(newValue)
                                    
                                    if !confirmPassword.isEmpty {
                                        confirmPasswordError = confirmPassword != newValue ? "Passwords do not match" : nil
                                    }
                                }
                        }
                        
                        // Password requirements
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password Requirements")
                                .font(.caption)
                                .foregroundStyle(Color.customText.opacity(0.7))
                            
                            HStack {
                                Image(systemName: passwordValidation.hasMinLength ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(passwordValidation.hasMinLength ? .green : .gray)
                                Text("At least 8 characters")
                                    .font(.caption)
                                    .foregroundStyle(Color.customText.opacity(0.7))
                            }
                            
                            HStack {
                                Image(systemName: passwordValidation.hasUppercase ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(passwordValidation.hasUppercase ? .green : .gray)
                                Text("One uppercase letter")
                                    .font(.caption)
                                    .foregroundStyle(Color.customText.opacity(0.7))
                            }
                            
                            HStack {
                                Image(systemName: passwordValidation.hasLowercase ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(passwordValidation.hasLowercase ? .green : .gray)
                                Text("One lowercase letter")
                                    .font(.caption)
                                    .foregroundStyle(Color.customText.opacity(0.7))
                            }
                            
                            HStack {
                                Image(systemName: passwordValidation.hasNumber ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(passwordValidation.hasNumber ? .green : .gray)
                                Text("One number")
                                    .font(.caption)
                                    .foregroundStyle(Color.customText.opacity(0.7))
                            }
                            
                            HStack {
                                Image(systemName: passwordValidation.hasSpecialChar ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(passwordValidation.hasSpecialChar ? .green : .gray)
                                Text("One special character (@$!%*?&)")
                                    .font(.caption)
                                    .foregroundStyle(Color.customText.opacity(0.7))
                            }
                        }
                        .padding(.leading, 4)
                        
                        // Confirm Password
                        inputField(title: "Confirm Password", error: nil) {
                            SecureField("Confirm your password", text: $confirmPassword)
                        }
                        
                        // Password matching validation
                        HStack {
                            Image(systemName: !confirmPassword.isEmpty && password == confirmPassword ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(!confirmPassword.isEmpty && password == confirmPassword ? .green : .gray)
                            Text("Passwords match")
                                .font(.caption)
                                .foregroundStyle(Color.customText.opacity(0.7))
                        }
                        .padding(.leading, 4)
                        
                        // Divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                            .padding(.vertical, 8)
                        
                        // Library Selection
                        sectionTitle("Select Your Library")
                        
                        Picker("Select Library", selection: $selectedLibrary) {
                            ForEach(libraries, id: \.self) { library in
                                Text(library).tag(library)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Error message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.vertical, 4)
                        }
                        
                        // Create Account Button
                        Button(action: createAccount) {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Continue")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.customButton : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(!isFormValid || isLoading)
                        .padding(.top, 16)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showVerificationView) {
                OTPVerificationView(
                    email: email,
                    otp: $otpCode,
                    onVerify: {
                        print("OTP verified, calling completeSignup()")
                        completeSignup()
                    },
                    onCancel: {
                        showVerificationView = false
                    }
                )
            }
            .fullScreenCover(isPresented: $showMembershipView) {
                MembershipView(
                    userName: name,
                    userEmail: email,
                    selectedLibrary: selectedLibrary,
                    gender: gender,
                    password: password
                )
            }
        }
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color.customText)
    }
    
    private func inputField<Content: View>(title: String, error: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.customText)
            
            content()
                .padding()
                .background(Color.customInputBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(error != nil ? Color.red : Color.clear, lineWidth: 1)
                )
            
            if let error = error {
                Text(error)
                    .foregroundStyle(Color.red)
                    .font(.caption)
                    .padding(.leading, 4)
            }
        }
    }
    
    private func createAccount() {
        isLoading = true
        
        // Send verification OTP to verify email
        Task {
            let sent = await EmailService.shared.sendOTPEmail(to: email)
            
            DispatchQueue.main.async {
                isLoading = false
                if sent {
                    showVerificationView = true
                } else {
                    errorMessage = "Failed to send verification code. Please try again."
                }
            }
        }
    }
    
    private func completeSignup() {
        print("OTP verified successfully for: \(email), proceeding to membership view")
        
        // Close verification sheet first
        showVerificationView = false
        
        // Navigate to membership view
        showMembershipView = true
    }
}

struct SignUp: View {
    var body: some View {
        SignupView()
    }
}

#Preview {
    NavigationView {
        SignupView()
    }
}
