//
//  GenerateCredentialsView.swift
//  BookWize
//
//  Created by Aditya Singh on 18/03/25.
//

import SwiftUI

struct GenerateCredentialsView: View {
    @Environment(\.dismiss) var dismiss
    let onSend: () -> Void
    
    @State private var email: String
    @State private var password: String
    @State private var isSending = false
    @State private var isSent = false
    @State private var errorMessage = ""
    
    private let emailService = EmailService()
    
    init(email: String, password: String, onSend: @escaping () -> Void) {
        self._email = State(initialValue: email)
        self._password = State(initialValue: password)
        self.onSend = onSend
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Librarian Credentials")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Email:")
                    .fontWeight(.semibold)
                Text(email)
                    .padding(.bottom, 10)
                
                Text("Temporary Password:")
                    .fontWeight(.semibold)
                Text(password)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }
            
            Button(action: {
                Task {
                    await sendCredentialsEmail()
                }
            }) {
                if isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if isSent {
                    Label("Email Sent", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Label("Send Credentials by Email", systemImage: "envelope.fill")
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSent ? Color.green.opacity(0.2) : Color.librarianColor)
            .foregroundColor(isSent ? .green : .white)
            .cornerRadius(10)
            .disabled(isSending || isSent)
            
            Button("Generate New Password") {
                password = generateRandomPassword()
            }
            .padding()
            .foregroundColor(.librarianColor)
            
            Button("Done") {
                if isSent {
                    onSend()
                    dismiss()
                } else {
                    errorMessage = "Please send credentials first"
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSent ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(!isSent)
        }
        .padding()
    }
    
    private func generateRandomPassword() -> String {
        let length = 8
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    private func sendCredentialsEmail() async {
        isSending = true
        errorMessage = ""
        
        let subject = "BookWize: Your Librarian Account Credentials"
        let body = """
        Hello,
        
        Your account for BookWize Library Management System has been created.
        
        Here are your login credentials:
        
        Email: \(email)
        Temporary Password: \(password)
        
        Please note that you will be required to change your password on first login.
        
        Regards,
        BookWize Administration
        """
        
        let success = await emailService.sendEmail(to: email, subject: subject, body: body)
        
        DispatchQueue.main.async {
            isSending = false
            if success {
                isSent = true
            } else {
                errorMessage = "Failed to send email. Please try again."
            }
        }
    }
}

#Preview {
    GenerateCredentialsView(
        email: "librarian@example.com", 
        password: "temp123", 
        onSend: {}
    )
}

