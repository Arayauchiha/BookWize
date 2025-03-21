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
    
    let libraries = ["Good Reads Library"]
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        ValidationUtils.isValidEmail(email) &&
        ValidationUtils.isValidPassword(password) &&
        password == confirmPassword &&
        emailError == nil &&
        passwordError == nil &&
        confirmPasswordError == nil
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
                        inputField(title: "Password", error: passwordError) {
                            SecureField("Enter password", text: $password)
                                .onChange(of: password) { newValue in
                                    passwordError = ValidationUtils.getPasswordError(newValue)
                                    if !confirmPassword.isEmpty {
                                        confirmPasswordError = confirmPassword != newValue ? "Passwords do not match" : nil
                                    }
                                }
                        }
                        
                        // Confirm Password
                        inputField(title: "Confirm Password", error: confirmPasswordError) {
                            SecureField("Confirm your password", text: $confirmPassword)
                                .onChange(of: confirmPassword) { newValue in
                                    confirmPasswordError = newValue != password ? "Passwords do not match" : nil
                                }
                        }
                        
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
