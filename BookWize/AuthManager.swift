//
//  AuthManager.swift
//  BookWize
//
//  Created by Aryan Singh on 20/03/25.
//

import Foundation
import SwiftUI

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private let emailService = EmailService()
    
    // Dictionary to store OTPs with email as key
    @Published var otpStore: [String: String] = [:]
    
    // For admin email verification
    @Published var isAdminEmailVerified = false
    
    private init() {}
    
    // Generate a random 6-digit OTP
    func generateOTP() -> String {
        return String(format: "%06d", Int.random(in: 0..<1000000))
    }
    
    // Send verification OTP to user email
    func sendVerificationOTP(to email: String) async -> Bool {
        let otp = generateOTP()
        otpStore[email] = otp
        
        let subject = "BookWize: Email Verification Code"
        let body = """
        Hello,
        
        Your verification code for BookWize is: \(otp)
        
        If you didn't request this code, please ignore this email.
        
        Regards,
        BookWize Team
        """
        
        return await emailService.sendEmail(to: email, subject: subject, body: body)
    }
    
    // Send librarian credentials
    func sendLibrarianCredentials(email: String, password: String) async -> Bool {
        let subject = "BookWize: Your Librarian Credentials"
        let body = """
        Hello,
        
        You have been added as a Librarian to BookWize.
        
        Your login credentials are:
        Email: \(email)
        Temporary Password: \(password)
        
        Please login and change your password when prompted.
        
        Regards,
        BookWize Admin Team
        """
        
        return await emailService.sendEmail(to: email, subject: subject, body: body)
    }
    
    // Verify OTP
    func verifyOTP(email: String, enteredOTP: String) -> Bool {
        guard let storedOTP = otpStore[email] else {
            return false
        }
        
        let isValid = storedOTP == enteredOTP
        
        if (isValid) {
            otpStore.removeValue(forKey: email)
        }
        
        return isValid
    }
}
