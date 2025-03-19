import SwiftUI

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isNewPasswordVisible: Bool
    @FocusState private var focusedField: Field?
    
    let title: String
    let message: String
    let buttonTitle: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    private enum Field {
        case newPassword
        case confirmPassword
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.customText.opacity(0.6))
                    .padding(.top, 20)
                
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
                                        .textFieldStyle(CustomTextFieldStyle())
                                } else {
                                    SecureField("Enter new password", text: $newPassword)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                            }
                            .textContentType(.newPassword)
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .newPassword)
                            
                            Button(action: { isNewPasswordVisible.toggle() }) {
                                Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(Color.customButton.opacity(Color.secondaryIconOpacity))
                            }
                        }
                        .padding(12)
                        .background(Color.customInputBackground)
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                        
                        // Confirm password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundStyle(Color.customText.opacity(0.6))
                            
                            HStack {
                                Group {
                                    if isNewPasswordVisible {
                                        TextField("Confirm new password", text: $confirmPassword)
                                            .textFieldStyle(CustomTextFieldStyle())
                                    } else {
                                        SecureField("Confirm new password", text: $confirmPassword)
                                            .textFieldStyle(CustomTextFieldStyle())
                                    }
                                }
                                .textContentType(.newPassword)
                                .textInputAutocapitalization(.never)
                                .focused($focusedField, equals: .confirmPassword)
                            }
                            .padding(12)
                            .background(Color.customInputBackground)
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.horizontal, 0)
                    
                    Button(action: onSave) {
                        Text(buttonTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.customButton)
                            )
                    }
                    .padding(.horizontal, 20)
                    
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
            }
        }
    }
}
