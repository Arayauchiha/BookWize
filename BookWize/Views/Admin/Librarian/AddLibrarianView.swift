import SwiftUI
import Supabase

func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
}


struct AddLibrarianView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (LibrarianData) -> Void

    @State private var name = ""
    @State private var age = ""
    @State private var email = ""
    @State private var phone = ""

    @State private var generatedPassword = ""
    @State private var showCredentials = false
    @State private var credentialsSent = false
    

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
                            .keyboardType(.numberPad)
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
                                        .fill(isValidEmail(email) && phone.count == 10 ? Color.librarianColor : Color.gray)
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
        guard isValidEmail(email) else {
            alertType = .error("Invalid Email")
            return
        }
        guard phone.count == 10 else {
            alertType = .error("Phone number should be of 10 digit")
            return
        }
        guard let phoneInt = Int(phone) else {
            alertType = .error("Invalid phone number")
            return
        }
        
        var librarianData = LibrarianData()
        
        librarianData.name = name
        librarianData.age = ageInt
        librarianData.email = email
        librarianData.phone = phoneInt
        librarianData.password = generatedPassword
        librarianData.status = .pending
        librarianData.dateAdded = Date()
        librarianData.requiresPasswordReset = true
        librarianData.roleFetched = .librarian
        
        Task {
            do {
                try await SupabaseManager.shared.client.database
                    .from("Users")
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

struct LibrarianData: Codable {
    var lib_Id = UUID()
    var name: String = ""
    var age: Int? = 0
    var email: String = ""
    var phone: Int? = 0 
    var password: String = ""
    var status: Status = .pending
    var dateAdded: Date = Date()
    var requiresPasswordReset: Bool = true
    var roleFetched: UserRole?
    
    enum CodingKeys: String, CodingKey {
        case name, email, phone, age, status, password, roleFetched
        case dateAdded = "date_added"
        case requiresPasswordReset = "requires_password_reset"
    }
}

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
