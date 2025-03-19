import Foundation

struct ValidationUtils {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8
    }
    
    static func getEmailError(_ email: String) -> String? {
        if email.isEmpty {
            return "Email is required"
        }
        if !isValidEmail(email) {
            return "Please enter a valid email address"
        }
        return nil
    }
    
    static func getPasswordError(_ password: String) -> String? {
        if password.isEmpty {
            return "Password is required"
        }
        if !isValidPassword(password) {
            return "Password must be at least 8 characters long"
        }
        return nil
    }
}
