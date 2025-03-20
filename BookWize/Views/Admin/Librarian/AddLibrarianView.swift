import SwiftUI

struct AddLibrarianView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (Librarian) -> Void
    
    // Form fields
    @State private var name = ""
    @State private var age = ""
    @State private var email = ""
    @State private var phone = ""
    
    // Credentials
    @State private var generatedPassword = ""
    @State private var showCredentials = false
    @State private var credentialsSent = false
    
    // Alert
    @State private var alertType: AlertType?
    
    var formIsValid: Bool {
        !name.isEmpty && !age.isEmpty && !email.isEmpty && !phone.isEmpty
    }
    
    var canAdd: Bool {
        formIsValid && credentialsSent
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Form fields
                    Group {
                        TextField("Full Name", text: $name)
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        TextField("Phone", text: $phone)
                            .keyboardType(.phonePad)
                    }
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.horizontal, 20)
                    
                    // Generate Credentials Button
                    if formIsValid && !credentialsSent {
                        Button(action: showCredentialsSheet) {
                            Text("Proceed to Credentials")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.librarianColor)
                                )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Add Button
                    Button(action: addLibrarian) {
                        Text("Add Librarian")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(canAdd ? Color.librarianColor : Color.gray)
                            )
                    }
                    .disabled(!canAdd)
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
            .background(Color.customBackground)
            .navigationTitle("Add Librarian")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCredentials) {
                GenerateCredentialsView(
                    email: email,
                    password: generatedPassword,
                    onSend: { 
                        credentialsSent = true
                        showCredentials = false
                    }
                )
            }
            .alert(alertType?.title ?? "", isPresented: .constant(alertType != nil)) {
                Button("OK") { alertType = nil }
            } message: {
                Text(alertType?.message ?? "")
            }
            .onAppear {
                // Generate a random password when view appears
                generatedPassword = generateRandomPassword()
            }
        }
    }
    
    private func showCredentialsSheet() {
        showCredentials = true
    }
    
    private func generateRandomPassword() -> String {
        // Generate random password
        let length = 8
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return "temp" + String((0..<length).map { _ in
            characters.randomElement()!
        })
    }
    
    private func addLibrarian() {
        guard let ageInt = Int(age) else {
            alertType = .error("Invalid age")
            return
        }
        
        let librarian = Librarian(
            name: name,
            age: ageInt,
            email: email,
            phone: phone
        )
        
        onAdd(librarian)
        dismiss()
    }
}

// Supporting Types
private enum AlertType: Identifiable {
    case error(String)
    
    var id: String { "error" }
    
    var title: String { "Error" }
    
    var message: String {
        switch self {
        case .error(let message): return message
        }
    }
}

#Preview {
    AddLibrarianView { _ in }
}

