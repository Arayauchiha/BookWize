import SwiftUI

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isNewPasswordVisible: Bool
    @FocusState private var focusedField: Field?
    
    let email: String
    let title: String
    let message: String
    let buttonTitle: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    // Password validation state
    @State private var passwordValidation = ValidationUtils.PasswordValidation(
        hasMinLength: false,
        hasUppercase: false,
        hasLowercase: false,
        hasNumber: false,
        hasSpecialChar: false
    )
    
    private enum Field {
        case newPassword
        case confirmPassword
    }
    
    struct FetchData:Codable{
        var email:String
        var password:String
        var vis:Bool
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.customText.opacity(0.6))
                    .padding(.top, 20)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 16) {
                    // New password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.6))
                        
                        HStack {
                            Group {
                                if isNewPasswordVisible {
                                    TextField("Enter new password", text: $newPassword)
                                        .textContentType(.newPassword)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .newPassword)
                                        .onChange(of: newPassword) { newValue in
                                            passwordValidation = ValidationUtils.validatePassword(newValue)
                                        }
                                } else {
                                    SecureField("Enter new password", text: $newPassword)
                                        .textContentType(.newPassword)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .newPassword)
                                        .onChange(of: newPassword) { newValue in
                                            passwordValidation = ValidationUtils.validatePassword(newValue)
                                        }
                                }
                            }
                            
                            Button(action: { isNewPasswordVisible.toggle() }) {
                                Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(Color.customButton.opacity(Color.secondaryIconOpacity))
                            }
                        }
                        .padding()
                        .background(Color.customInputBackground)
                        .cornerRadius(8)
                    }
                    .padding(.bottom, 8)

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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.6))
                        
                        HStack {
                            Group {
                                if isNewPasswordVisible {
                                    TextField("Confirm new password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .confirmPassword)
                                } else {
                                    SecureField("Confirm new password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .confirmPassword)
                                }
                            }
                        }
                        .padding()
                        .background(Color.customInputBackground)
                        .cornerRadius(8)
                        
                        // Password matching validation
                        HStack {
                            Image(systemName: !confirmPassword.isEmpty && newPassword == confirmPassword ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(!confirmPassword.isEmpty && newPassword == confirmPassword ? .green : .gray)
                            Text("Passwords match")
                                .font(.caption)
                                .foregroundStyle(Color.customText.opacity(0.7))
                        }
                        .padding(.leading, 4)
                    }
                    
                    Button(action: {
                        onSave()
                        Task {
                            try await SupabaseManager.shared.client
                                .from("Users")
                                .update(FetchData(email: email, password: newPassword, vis: true))
                                .eq("email", value: email)
                                .execute()
                        }
                    }) {
                        Text(buttonTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.customButton)
                    )
                    .padding(.top, 16)
                    .disabled(newPassword.isEmpty || confirmPassword.isEmpty || !passwordValidation.isValid || newPassword != confirmPassword)
                    .opacity(newPassword.isEmpty || confirmPassword.isEmpty || !passwordValidation.isValid || newPassword != confirmPassword ? 0.7 : 1)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.customBackground)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(Color.customButton)
                }
            }
            .onAppear { 
                focusedField = .newPassword
            }
        }
    }
}
