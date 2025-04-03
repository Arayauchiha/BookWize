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
    @State private var timeRemaining = 60
    @State private var timer: Timer?
    @State private var canResend = false
    @State private var otpFields: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedField: Int?
    
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
                        .padding(.horizontal, 20)

                    HStack(spacing: 8) {
                        ForEach(0..<6) { index in
                            OTPTextField(text: $otpFields[index], isFocused: focusedField == index)
                                .focused($focusedField, equals: index)
                                .onChange(of: otpFields[index]) { _, newValue in
                                    handleOTPChange(at: index, newValue: newValue)
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 20)
                    }
                }

                Button(action: {
                    print("Verify button pressed with OTP: \(otp)")
                    if otp.count != 6 {
                        errorMessage = "Please enter a valid 6-digit code"
                        return
                    }
                    
                    if emailService.verifyOTP(email: email, code: otp) {
                        errorMessage = ""
                        onVerify()
                    } else {
                        errorMessage = "Invalid verification code"
                    }
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
                    if canResend {
                        resendCode()
                    }
                }) {
                    if isResending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text(canResend ? "Resend Code" : "Resend Code (\(timeRemaining)s)")
                    }
                }
                .foregroundColor(canResend ? Color.customButton : Color.gray)
                .padding(.top, 8)
                .disabled(isResending || !canResend)

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
            .onAppear { 
                focusedField = 0
                startTimer()
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func handleOTPChange(at index: Int, newValue: String) {
        // Remove non-numeric characters
        let filteredValue = newValue.filter { $0.isNumber }
        
        // Update the field with filtered value
        otpFields[index] = filteredValue
        
        // If we have a value and it's not the last field, move to the next field
        if !filteredValue.isEmpty && index < 5 {
            focusedField = index + 1
        }
        
        // Combine all fields into the otp binding
        otp = otpFields.joined()
        
        // Clear error when user types
        errorMessage = ""
    }
    
    private func startTimer() {
        timeRemaining = 60
        canResend = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                canResend = true
                timer?.invalidate()
            }
        }
    }
    
    private func resendCode() {
        isResending = true
        
        // Clear the current OTP input
        otp = ""
        otpFields = Array(repeating: "", count: 6)
        
        Task {
            // Send a new OTP
            let sent = await emailService.sendOTPEmail(to: email)
            
            DispatchQueue.main.async {
                isResending = false
                if !sent {
                    errorMessage = "Failed to resend verification code"
                } else {
                    errorMessage = ""
                    focusedField = 0
                    startTimer() // Restart the timer after successful resend
                }
            }
        }
    }
}

struct OTPTextField: View {
    @Binding var text: String
    let isFocused: Bool
    
    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .multilineTextAlignment(.center)
            .frame(width: 45, height: 45)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color.customButton : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .font(.title2)
            .fontWeight(.semibold)
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
