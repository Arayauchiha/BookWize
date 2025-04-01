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
    @State private var nameError: String?
    @State private var ageError: String?
    @State private var emailError: String?
    @State private var phoneError: String?

    @State private var generatedPassword = ""
    @State private var showCredentials = false
    @State private var credentialsSent = false
    
    @State private var alertType: AlertType?
    
    var formIsValid: Bool {
        !name.isEmpty && 
        !age.isEmpty && 
        !email.isEmpty && 
        !phone.isEmpty &&
        ValidationUtils.isValidEmail(email) &&
        phone.count == 10 &&
        nameError == nil &&
        ageError == nil &&
        emailError == nil &&
        phoneError == nil
    }
    
    var canAdd: Bool {
        formIsValid && credentialsSent
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.7))
                        
                        TextField("Full Name", text: $name)
                            .textFieldStyle(CustomTextFieldStyle())
                            .onChange(of: name) { newValue in
                                if newValue.isEmpty {
                                    nameError = "Name is required"
                                } else {
                                    nameError = nil
                                }
                            }
                        
                        if let error = nameError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Age field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.7))
                        
                        TextField("Age", text: $age)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: age) { newValue in
                                if newValue.isEmpty {
                                    ageError = "Age is required"
                                } else if let ageInt = Int(newValue), ageInt < 18 || ageInt > 100 {
                                    ageError = "Age must be between 18 and 100"
                                } else {
                                    ageError = nil
                                }
                            }
                        
                        if let error = ageError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.7))
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .onChange(of: email) { newValue in
                                emailError = ValidationUtils.getEmailError(newValue)
                            }
                        
                        if let error = emailError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Phone field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.7))
                        
                        TextField("Phone", text: $phone)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: phone) { newValue in
                                if newValue.isEmpty {
                                    phoneError = "Phone number is required"
                                } else if newValue.count != 10 {
                                    phoneError = "Phone number must be 10 digits"
                                } else if Int(newValue) == nil {
                                    phoneError = "Invalid phone number"
                                } else {
                                    phoneError = nil
                                }
                            }
                        
                        if let error = phoneError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
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
        let length = 12 // Increased length for better security
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let specialChars = "!@#$%^&*"
        
        // Ensure at least one of each required character type
        var password = ""
        password += String(lowercase.randomElement()!)
        password += String(uppercase.randomElement()!)
        password += String(numbers.randomElement()!)
        password += String(specialChars.randomElement()!)
        
        // Fill the rest with random characters from all sets
        let allChars = lowercase + uppercase + numbers + specialChars
        while password.count < length {
            password += String(allChars.randomElement()!)
        }
        
        // Shuffle the password to make it more random
        return String(password.shuffled())
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
        
        Task {
            do {
                // Check if a librarian with this email already exists
                let existingLibrarians = try await SupabaseManager.shared.client
                    .from("Users")
                    .select("*")
                    .eq("email", value: email)
                    .execute()
                
                // Decode the response to check if any librarians were found
                struct ResponseData: Codable {
                    let email: String
                }
                
                if let librarians = try? JSONDecoder().decode([ResponseData].self, from: existingLibrarians.data),
                   !librarians.isEmpty {
                    // A librarian with this email already exists
                    await MainActor.run {
                        alertType = .error("A librarian with email '\(email)' already exists")
                    }
                    return
                }
                
                // If we get here, no duplicate was found, so add the new librarian
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
                
                try await SupabaseManager.shared.client.database
                    .from("Users")
                    .insert(librarianData)
                    .execute()
                
                await MainActor.run {
                    onAdd(librarianData)
                    dismiss()
                }
            } catch {
                print("Error: \(error.localizedDescription)")
                await MainActor.run {
                    alertType = .error("Failed to add librarian: \(error.localizedDescription)")
                }
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


