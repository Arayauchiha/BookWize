import SwiftUI

struct OTPVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    let email: String
    @Binding var otp: String
    let onVerify: () -> Void
    let onCancel: () -> Void
    @FocusState private var isOTPFieldFocused: Bool
    @State private var errorMessage = ""
    @State private var isResending = false
    
    // Reference to the email service
    private let emailService = EmailService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter the verification code sent to\n\(email)")
                    .font(.subheadline)
                    .foregroundStyle(Color.customText.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Verification Code")
                        .font(.subheadline)
                        .foregroundStyle(Color.customText.opacity(0.6))

                    TextField("Enter 6-digit code", text: $otp)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($isOTPFieldFocused)
                        .onChange(of: otp) { _, newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                otp = String(newValue.prefix(6))
                            }
                            // Remove non-numeric characters
                            otp = newValue.filter { $0.isNumber }
                        }
                        .textFieldStyle(CustomTextFieldStyle())
                        .padding(.horizontal, 20)
                }
                .padding(.horizontal, 20)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    print("Verify button pressed with OTP: \(otp)")
                    if otp.count != 6 {
                        errorMessage = "Please enter a valid 6-digit code"
                        return
                    }
                    
                    errorMessage = ""
                    // Call the onVerify callback which should handle all verification logic
                    onVerify()
                    
                    // Important: Do NOT dismiss here - let the parent view determine
                    // when to dismiss based on successful verification
                }) {
                    Text("Verify")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.customButton)
                )
                .padding(.horizontal, 20)
                .disabled(otp.count != 6)
                .opacity(otp.count != 6 ? 0.7 : 1)

                Button(action: {
                    resendCode()
                }) {
                    if isResending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Resend Code")
                    }
                }
                .foregroundColor(Color.customButton)
                .padding(.top, 8)
                .disabled(isResending)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.customBackground)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle("Verify OTP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(Color.customButton)
                }
            }
            .onAppear { isOTPFieldFocused = true }
        }
    }
    
    private func resendCode() {
        isResending = true
        
        // Clear the current OTP input
        otp = ""
        
        Task {
            // Send a new OTP
            let sent = await emailService.sendOTPEmail(to: email)
            
            DispatchQueue.main.async {
                isResending = false
                if !sent {
                    errorMessage = "Failed to resend verification code"
                } else {
                    errorMessage = ""
                    isOTPFieldFocused = true
                }
            }
        }
    }
}

#Preview {
    OTPVerificationView(
        email: "test@example.com",
        otp: .constant(""),
        onVerify: {},
        onCancel: {}
    )
    .environment(\.colorScheme, .light)
}
