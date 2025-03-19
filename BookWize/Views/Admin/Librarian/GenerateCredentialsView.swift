import SwiftUI

struct GenerateCredentialsView: View {
    @Environment(\.dismiss) private var dismiss
    let email: String
    let password: String
    let onSend: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Generated Credentials")
                    .font(.title2)
                    .foregroundStyle(Color.customText)
                
                VStack(alignment: .leading, spacing: 16) {
                    credentialRow(title: "Email:", value: email)
                    credentialRow(title: "Password:", value: password)
                }
                .padding(16)
                .background(Color.customCardBackground)
                .cornerRadius(12)
                
                Text("These credentials will be sent to the librarian's email address.")
                    .font(.subheadline)
                    .foregroundStyle(Color.customText.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Button(action: sendCredentials) {
                    Text("Send Credentials")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.librarianColor)
                        )
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.customBackground)
            .navigationTitle("Credentials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func credentialRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.customText.opacity(0.6))
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color.customText)
        }
    }
    
    private func sendCredentials() {
        // Here you would implement actual email sending
        // For now, we'll just simulate it
        onSend()
    }
}

#Preview {
    GenerateCredentialsView(
        email: "john@example.com",
        password: "Ab12!@cd34#$",
        onSend: {}
    )
}

