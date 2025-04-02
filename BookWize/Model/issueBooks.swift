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
    let actualReturnedDate: Date?
    
    // Coding keys to handle potential differences in JSON keys
    enum CodingKeys: String, CodingKey {
        case id
        case isbn
        case memberEmail = "member_email"
        case issueDate = "issue_date"
        case returnDate = "return_date"
        case actualReturnedDate = "actual_returned_date"
    }
}

