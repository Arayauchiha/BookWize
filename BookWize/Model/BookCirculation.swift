//
//  IssuedBooks.swift
//  BookWize
//
//  Created by Anshika on 26/03/25.
//
import SwiftUI
import Foundation

struct BookCirculation: Identifiable, Codable {
    let id: UUID
    let isbn: String
    let memberID: UUID
    let startDate: Date
    var endDate: Date?
    var status: LoanStatus
}

enum LoanStatus: String, Codable {
    case issued, returned, renewed, reserved
}


