import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let emailService = EmailService()
    
    func login(email: String, password: String) {
        // TODO: Implement actual authentication
        // For demo purposes, we'll just simulate a successful login
        if !email.isEmpty && !password.isEmpty {
            isAuthenticated = true
        } else {
            showError = true
            errorMessage = "Please fill in all fields"
        }
    }
    
    func signup(email: String, name: String, gender: Gender, password: String, confirmPassword: String, selectedLibrary: String) {
        if password != confirmPassword {
            showError = true
            errorMessage = "Passwords do not match"
            return
        }
        
        // Create user
        let user = User(email: email, name: name, gender: gender, password: password, selectedLibrary: selectedLibrary)
        currentUser = user
        isAuthenticated = true
        
        // Send welcome email
        Task {
            let subject = "Welcome to BookWize!"
            let body = """
            Hello \(name),
            
            Welcome to BookWize! Your account has been successfully created.
            
            Your selected library: \(selectedLibrary)
            
            You can now enjoy all the benefits of our library management system.
            
            Regards,
            BookWize Team
            """
            
            _ = await emailService.sendEmail(to: email, subject: subject, body: body)
        }
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
    }
}