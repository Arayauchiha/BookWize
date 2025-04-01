import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
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
                        .foregroundStyle(Color.customText.opacity(0.4))
                        .frame(width: 20, height: 20)
                }
                .padding(.trailing, 12)
            }
        }
        .background(Color.customInputBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.customText.opacity(0.1), lineWidth: 1)
        )
    }
}

extension View {
    func customTextField() -> some View {
        self
            .background(Color.customInputBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.customText.opacity(0.1), lineWidth: 1)
            )
    }
}

// End of file











