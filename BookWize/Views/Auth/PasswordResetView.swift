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
                                } else {
                                    SecureField("Enter new password", text: $newPassword)
                                        .textContentType(.newPassword)
                                        .textInputAutocapitalization(.never)
                                        .focused($focusedField, equals: .newPassword)
                                }
                            }
                            
                            
                            Button(action: { isNewPasswordVisible.toggle()
                                Task{
                                    let data:[FetchData] = try await SupabaseManager.shared.client.from("Users").select().execute().value
                                    try await SupabaseManager.shared.client.from("Users").update(FetchData(email: data[0].email, password:newPassword, vis: true)).eq("email", value: data[0].email).execute()
                                }
                            }) {
                                Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(Color.customButton.opacity(Color.secondaryIconOpacity))
                            }
                        }
                        .padding()
                        .background(Color.customInputBackground)
                        .cornerRadius(8)
                    }
                    
                    // Confirm password field
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
                    }
                    
                    // Password requirements info
                    Text("Password must be at least 8 characters long")
                        .font(.caption)
                        .foregroundStyle(Color.customText.opacity(0.5))
                        .padding(.top, 4)
                    
                    Button(action: onSave) {
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
                    .disabled(newPassword.isEmpty || confirmPassword.isEmpty)
                    .opacity(newPassword.isEmpty || confirmPassword.isEmpty ? 0.7 : 1)
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

#Preview {
    PasswordResetView(
        newPassword: .constant(""),
        confirmPassword: .constant(""),
        isNewPasswordVisible: .constant(false),
        title: "Create New Password",
        message: "Please set a new password for your account",
        buttonTitle: "Set Password",
        onSave: {},
        onCancel: {}
    )
}
