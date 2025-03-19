import SwiftUI

struct OTPVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    let email: String
    @Binding var otp: String
    let onVerify: () -> Void
    let onCancel: () -> Void
    @FocusState private var isOTPFieldFocused: Bool

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

                Button(action: onVerify) {
                    Text("Verify")
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
                .disabled(otp.count != 6)

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
