import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct CustomPasswordFieldStyle: ViewModifier {
    @Binding var text: String
    @Binding var isVisible: Bool
    let placeholder: String
    
    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 8) {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .textContentType(.password)
                        .textFieldStyle(CustomTextFieldStyle())
                } else {
                    SecureField(placeholder, text: $text)
                        .textContentType(.password)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                Button(action: {
                    isVisible.toggle()
                }) {
                    Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                }
                .padding(.trailing, 12)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
}

extension View {
    func customTextField() -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
    }
}











