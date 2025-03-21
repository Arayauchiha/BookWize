import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isVerificationNeeded = false
    @Published var verificationEmail = ""
    
    private let emailService = EmailService()
    
    func login(email: String, password: String) {
        // TODO: Implement actual authentication
        // For demo purposes, we'll just simulate a successful login
        if !email.isEmpty && !password.isEmpty {
            // Set verification email for OTP
            verificationEmail = email
            isVerificationNeeded = true
        } else {
            showError = true
            errorMessage = "Please fill in all fields"
        }
    }
    
    func signup(email: String, name: String, gender: Gender, password: String, confirmPassword: String, selectedLibrary: String, selectedGenres: [String] = []) {
        if password != confirmPassword {
            showError = true
            errorMessage = "Passwords do not match"
            return
        }
        
        // Create user
        let user = User(email: email, name: name, gender: gender, password: password, selectedLibrary: selectedLibrary, selectedGenres: selectedGenres)
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
    
    func sendVerificationOTP(to email: String) async -> Bool {
        return await EmailService.shared.sendOTPEmail(to: email)
    }
    
    func verifyOTP(email: String, code: String) -> Bool {
        return EmailService.shared.verifyOTP(email: email, code: code)
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
    }
}
