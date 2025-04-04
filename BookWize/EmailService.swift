
import Foundation
import SwiftSMTP

class EmailService {
    static let shared = EmailService()
    private let smtp: SMTP
    
    // Simple in-memory OTP storage
    private var otpCodes: [String: String] = [:]

    init() {
        smtp = SMTP(
            hostname: "smtp.gmail.com",
            email: "adddiiiyya@gmail.com",
            password: "xhpv ekzt ipwf ksyb"
        )
    }
    
    func generateOTP() -> String {
        return String(format: "%06d", Int.random(in: 0..<1000000))
    }

    func sendOTPEmail(to email: String) async -> Bool {
        let otp = generateOTP()
        otpCodes[email] = otp
        
        let subject = "BookWize - Email Verification"
        let body = """
        Hello,
        
        Your verification code for BookWize is: \(otp)
        
        If you didn't request this code, please ignore this email.
        
        Regards,
        BookWize Team
        """
        
        return await sendEmail(to: email, subject: subject, body: body)
    }
    
    func sendPasswordResetOTP(to email: String) async -> (Bool, String) {
        let otp = generateOTP()
        otpCodes[email] = otp
        
        let subject = "BookWize - Password Reset"
        let body = """
        Hello,
        
        Your password reset code for BookWize is: \(otp)
        
        If you didn't request this code, please ignore this email.
        
        Regards,
        BookWize Team
        """
        
        let sent = await sendEmail(to: email, subject: subject, body: body)
        return (sent, otp)
    }
    
    func verifyOTP(email: String, code: String) -> Bool {
        guard let storedOTP = otpCodes[email] else {
            return false
        }
        
        return storedOTP == code
    }
    
    func clearOTP(for email: String) {
        otpCodes.removeValue(forKey: email)
    }

    // Regular email functions
    func sendEmail(to recipient: String, subject: String, body: String) async -> Bool {
        let from = Mail.User(name: "Aditya Singh", email: "adddiiiyya@gmail.com")
        let to = Mail.User(name: "Recipient Name", email: recipient)

        let mail = Mail(
            from: from,
            to: [to],
            subject: subject,
            text: body
        )

        do {
            smtp.send(mail)
            print("Email sent successfully to \(recipient)")
            return true
        }
    }
    
    func sendHtmlEmail(to recipient: String, subject: String, htmlBody: String) async -> Bool {
        let from = Mail.User(name: "Aditya Singh", email: "adddiiiyya@gmail.com")
        let to = Mail.User(name: "Recipient Name", email: recipient)
        
        let mail = Mail(
            from: from,
            to: [to],
            subject: subject,
            text: htmlBody
        )
        
        do {
            smtp.send(mail)
            print("HTML email sent successfully to \(recipient)")
            return true
        }
    }
}
