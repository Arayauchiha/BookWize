import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authViewModel = AuthViewModel()
    
    @State private var name = ""
    @State private var email = ""
    @State private var gender = Gender.male
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedLibrary = "Central Library"
    @State private var showSuccessAlert = false
    @State private var showMembershipView = false
    
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var confirmPasswordError: String?
    
    let libraries = ["Central Library", "City Library", "University Library", "Community Library"]
    
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
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .submitLabel(.next)
                        .onChange(of: email) { newValue in
                            if !newValue.isEmpty {
                                emailError = ValidationUtils.getEmailError(newValue)
                            } else {
                                emailError = nil
                            }
                        }
                    
                    if let emailError = emailError {
                        Text(emailError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    TextField("Name", text: $name)
                        .submitLabel(.next)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                }
                
                Section(header: Text("Security")) {
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .onChange(of: password) { newValue in
                        if !newValue.isEmpty {
                            passwordError = ValidationUtils.getPasswordError(newValue)
                        } else {
                            passwordError = nil
                        }
                    }
                    
                    if let passwordError = passwordError {
                        Text(passwordError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    HStack {
                        if showConfirmPassword {
                            TextField("Confirm Password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword)
                        }
                        
                        Button(action: {
                            showConfirmPassword.toggle()
                        }) {
                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .onChange(of: confirmPassword) { newValue in
                        if !newValue.isEmpty {
                            if newValue != password {
                                confirmPasswordError = "Passwords do not match"
                            } else {
                                confirmPasswordError = nil
                            }
                        } else {
                            confirmPasswordError = nil
                        }
                    }
                    
                    if let confirmPasswordError = confirmPasswordError {
                        Text(confirmPasswordError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section(header: Text("Library Selection")) {
                    Picker("Select Library", selection: $selectedLibrary) {
                        ForEach(libraries, id: \.self) { library in
                            Text(library).tag(library)
                        }
                    }
                }
                
                Section {
                    Button("Create Account") {
                        authViewModel.signup(
                            email: email,
                            name: name,
                            gender: gender,
                            password: password,
                            confirmPassword: confirmPassword,
                            selectedLibrary: selectedLibrary
                        )
                        showSuccessAlert = true
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Sign Up")
            .alert("Error", isPresented: $authViewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authViewModel.errorMessage)
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("Continue to Membership") {
                    showMembershipView = true
                }
            } message: {
                Text("Account created successfully!")
            }
            .fullScreenCover(isPresented: $showMembershipView) {
                MembershipView(userName: name, userEmail: email)
            }
        }
    }
}
