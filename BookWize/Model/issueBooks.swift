//
//  IssuedBooks.swift
//  BookWize
//
//  Created by Anshika on 26/03/25.
//
import SwiftUI
import Foundation

struct issueBooks: Identifiable, Codable {
    let id: UUID
    let isbn: String
    let memberEmail: String
    let issueDate: Date
    let returnDate: Date?
    
    // Coding keys to handle potential differences in JSON keys
    enum CodingKeys: String, CodingKey {
        case id
        case isbn
        case memberEmail = "member_email"
        case issueDate = "issue_date"
        case returnDate = "return_date"
    }
    
//    init(id: UUID = UUID(), isbn: String, memberEmail: String, issueDate: Date, returnDate: Date? = nil) {
//            self.id = id
//            self.isbn = isbn
//            self.memberEmail = memberEmail
//            self.issueDate = issueDate
//            self.returnDate = returnDate
//        }
    
//    // Custom initializer to handle potential UUID and date variations
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        
//        // Handle ID (could be string or UUID)
//        if let uuidString = try? container.decode(String.self, forKey: .id) {
//            id = UUID(uuidString: uuidString) ?? UUID()
//        } else {
//            id = try container.decode(UUID.self, forKey: .id)
//        }
//        
//        isbn = try container.decode(String.self, forKey: .isbn)
//        memberEmail = try container.decode(String.self, forKey: .memberEmail)
//        
//        // Handle potential date formats
//        let dateFormatter = ISO8601DateFormatter()
//        
//        if let dateString = try? container.decode(String.self, forKey: .issueDate) {
//            issueDate = dateFormatter.date(from: dateString) ?? Date()
//        } else {
//            issueDate = try container.decode(Date.self, forKey: .issueDate)
//        }
//        
//        // Optional return date
//        returnDate = try? container.decodeIfPresent(Date.self, forKey: .returnDate)
//    }
}

