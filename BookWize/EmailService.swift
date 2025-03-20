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
}
