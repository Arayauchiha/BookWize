import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var showError = false
    @Published var errorMessage = ""
    
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
        
        // TODO: Implement actual signup
        // For demo purposes, we'll create a new user
        let user = User(email: email, name: name, gender: gender, password: password, selectedLibrary: selectedLibrary)
        currentUser = user
        isAuthenticated = true
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
    }
} 