import Foundation

struct ValidationUtils {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
    
    static func getEmailError(_ email: String) -> String? {
        if email.isEmpty {
            return nil
        }
        if !isValidEmail(email) {
            return "Please enter a valid email address"
        }
        return nil
    }
    
    // Password validation states
    struct PasswordValidation {
        var hasMinLength: Bool
        var hasUppercase: Bool
        var hasLowercase: Bool
        var hasNumber: Bool
        var hasSpecialChar: Bool
        
        var isValid: Bool {
            hasMinLength && hasUppercase && hasLowercase && hasNumber && hasSpecialChar
        }
    }
    
    static func validatePassword(_ password: String) -> PasswordValidation {
        return PasswordValidation(
            hasMinLength: password.count >= 8,
            hasUppercase: password.contains(where: { $0.isUppercase }),
            hasLowercase: password.contains(where: { $0.isLowercase }),
            hasNumber: password.contains(where: { $0.isNumber }),
            hasSpecialChar: password.contains(where: { "@$!%*?&".contains($0) })
        )
    }
    
    static func getPasswordError(_ password: String) -> String? {
        if password.isEmpty {
            return nil
        }
        if password.count < 8 {
            return "Password must be at least 8 characters long."
        }
        if !password.contains(where: { $0.isUppercase }) {
            return "Password must contain at least one uppercase letter."
        }
        if !password.contains(where: { $0.isLowercase }) {
            return "Password must contain at least one lowercase letter."
        }
        if !password.contains(where: { $0.isNumber }) {
            return "Password must contain at least one digit."
        }
        let specialCharacterSet = CharacterSet(charactersIn: "@$!%*?&")
        if password.rangeOfCharacter(from: specialCharacterSet) == nil {
            return "Password must contain at least one special character (@$!%*?&)."
        }
        return nil // Password is valid
    }
}
