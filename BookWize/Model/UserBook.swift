//
//  Book.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import Foundation

struct UserBook: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let author: String
    let isbn: String
    let genre: String
    let publicationYear: Int
    let availability: AvailabilityStatus
    let reservedBy: UUID?
    let imageURL: String?
    
    static func == (lhs: UserBook, rhs: UserBook) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.author == rhs.author &&
               lhs.isbn == rhs.isbn &&
               lhs.genre == rhs.genre &&
               lhs.publicationYear == rhs.publicationYear &&
               lhs.availability == rhs.availability &&
               lhs.reservedBy == rhs.reservedBy &&
               lhs.imageURL == rhs.imageURL
    }
}

enum AvailabilityStatus: String, Codable {
    case available
    case borrowed
    case reserved
    case unavailable
}
