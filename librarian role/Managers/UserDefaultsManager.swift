import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let defaults = UserDefaults.standard
    private let usernameKey = "librarian_username"
    private let passwordKey = "librarian_password"
    
    private init() {
        // Set default credentials if none exist
        if defaults.string(forKey: usernameKey) == nil {
            defaults.setValue("librarian", forKey: usernameKey)
            defaults.setValue("password", forKey: passwordKey)
        }
    }
    
    func validateCredentials(username: String, password: String) -> Bool {
        let storedUsername = defaults.string(forKey: usernameKey) ?? ""
        let storedPassword = defaults.string(forKey: passwordKey) ?? ""
        return username == storedUsername && password == storedPassword
    }
    
    func updatePassword(currentPassword: String, newPassword: String) -> Bool {
        let storedPassword = defaults.string(forKey: passwordKey) ?? ""
        
        if currentPassword == storedPassword {
            defaults.setValue(newPassword, forKey: passwordKey)
            return true
        }
        return false
    }
} 