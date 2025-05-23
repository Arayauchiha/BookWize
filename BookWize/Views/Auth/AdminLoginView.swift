struct FetchData:Codable{
    var email:String
    var password:String
    var vis:Bool
}
import SwiftUI

struct AdminLoginView: View {
    @State private var email: String = .init()
    @State private var password:String = .init()
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isNewPasswordVisible = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var verificationCode = ""
    @State private var isPasswordVisible = false
    @State private var emailError: String?
    @FocusState private var focusedField: Field?
    
    @State private var showPasswordChange = false
    @State private var showVerification = false
    
    @AppStorage("isAdminLoggedIn") private var isAdminLoggedIn = false
    
    private enum Field {
        case email, password
    }
    
    private var isEmailValid: Bool {
        ValidationUtils.isValidEmail(email)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
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
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .customTextField()
                        .onSubmit {
                            focusedField = .password
                        }
                        .onChange(of: email) { _, newValue in
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

                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundStyle(Color.customText.opacity(0.7))
                    
                    ModifiedContent(content: EmptyView(), modifier: CustomPasswordFieldStyle(
                        text: $password,
                        isVisible: $isPasswordVisible,
                        placeholder: "Enter your password"
                    ))
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

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
        .sheet(isPresented: $showPasswordChange) {
            PasswordResetView(
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isNewPasswordVisible: $isNewPasswordVisible,
                email: email,
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
                    showPasswordChange = false

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
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    func login() {
        Task {
            isLoading = true
            
            do {
                let data: [FetchData] = try await SupabaseManager.shared.client
                    .from("Users")
                    .select("*")
                    .eq("email", value: email)
                    .eq("password", value: password)
                    .eq("roleFetched", value: "admin")
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
                            showPasswordChange = true
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
            
            isAdminLoggedIn = true
            UserDefaults.standard.set(email, forKey: "currentMemberEmail")
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
