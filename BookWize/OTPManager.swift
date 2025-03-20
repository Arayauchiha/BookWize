//
//  OTPManager.swift
//  BookWize
//
//  Created by Aditya Singh on 20/03/25.
//

import Foundation
import SwiftUI

class OTPManager {
    static let shared = OTPManager()
    private let emailService = EmailService()
    
    // Simple in-memory OTP storage
    private var otpCodes: [String: String] = [:]
    
    private init() {}
    
    func generateOTP() -> String {
        return String(Int.random(in: 100000...999999))
    }
    
    func sendOTPEmail(to email: String) async -> Bool {
        let otp = generateOTP()
        otpCodes[email] = otp
        
        let subject = "Your verification code"
        let body = "Your verification code is: \(otp)"
        
        return await emailService.sendEmail(to: email, subject: subject, body: body)
    }
    
    func verifyOTP(email: String, code: String) -> Bool {
        guard let storedOTP = otpCodes[email] else {
            return false
        }
        
        return code == storedOTP
    }
    
    func clearOTP(for email: String) {
        otpCodes.removeValue(forKey: email)
    }
}