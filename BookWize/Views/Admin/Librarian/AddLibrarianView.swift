import SwiftUI
import Supabase

struct AddLibrarianView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (LibrarianData) -> Void
    
    // Form fields
    @State private var name = ""
    @State private var age = ""
    @State private var email = ""
    @State private var phone = "" // Still a String for TextField input, but will convert to Int
    
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
                    Group {
                        TextField("Full Name", text: $name)
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        TextField("Phone", text: $phone)
                            .keyboardType(.numberPad) // Use numberPad for integer input
                    }
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.horizontal, 20)
                    
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
                generatedPassword = generateRandomPassword()
            }
        }
    }
    
    private func showCredentialsSheet() {
        showCredentials = true
    }
    
    private func generateRandomPassword() -> String {
        let length = 8
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    private func addLibrarian() {
        guard let ageInt = Int(age) else {
            alertType = .error("Invalid age")
            return
        }
        
        guard let phoneInt = Int(phone) else { // Convert phone to Int
            alertType = .error("Invalid phone number")
            return
        }
        
        let librarianData = LibrarianData(
            name: name,
            age: ageInt,
            email: email,
            phone: phoneInt, // Now an Int
            password: generatedPassword,
            status: .pending,
            dateAdded: Date(),
            requiresPasswordReset: true
        )
        
        Task {
            do {
                try await SupabaseManager.shared.client.database
                    .from("librarians")
                    .insert(librarianData)
                    .execute()
                onAdd(librarianData)
                dismiss()
            } catch {
                print("Error: \(error.localizedDescription)")
                alertType = .error("Failed to add librarian: \(error.localizedDescription)")
            }
        }
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

struct LibrarianData: Encodable {
    let lib_Id = UUID()
    let name: String
    let age: Int
    let email: String
    let phone: Int // Changed from String to Int
    let password: String
    var status: Status
    let dateAdded: Date
    let requiresPasswordReset: Bool
    
    enum Status: String, CaseIterable, Codable {
        case pending = "pending"
        case working = "working"
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .working: return .green
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case name, email, phone, age, status, password
        case dateAdded = "date_added"
        case requiresPasswordReset = "requires_password_reset"
    }
}
