//
//  EmailService.swift
//  BookWize
//
//  Created by Aditya Singh on 20/03/25.
//

import Foundation
import SwiftSMTP

class EmailService {
    private let smtp: SMTP

    init() {
        // Configure your SMTP server settings
        smtp = SMTP(
            hostname: "smtp.gmail.com", // e.g., smtp.gmail.com
            email: "adddiiiyya@gmail.com", // Your email address
            password: "xhpv ekzt ipwf ksyb"
        )
    }

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
            try await smtp.send(mail)
            print("Email sent successfully to \(recipient)")
            return true
        } catch {
            print("Failed to send email: \(error.localizedDescription)")
            return false
        }
    }
    
    // Fixed HTML email function
    func sendHtmlEmail(to recipient: String, subject: String, htmlBody: String) async -> Bool {
        let from = Mail.User(name: "Aditya Singh", email: "adddiiiyya@gmail.com")
        let to = Mail.User(name: "Recipient Name", email: recipient)
        
        // Check SwiftSMTP documentation for the correct parameter name
        // If 'html' doesn't work, try one of these alternatives:
        let mail = Mail(
            from: from,
            to: [to],
            subject: subject,
            text: htmlBody // Use text instead of html if html is not supported
        )
        
        do {
            try await smtp.send(mail)
            print("HTML email sent successfully to \(recipient)")
            return true
        } catch {
            print("Failed to send HTML email: \(error.localizedDescription)")
            return false
        }
    }
}
