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

}

enum AvailabilityStatus: String, Codable {
    case available
    case borrowed
    case reserved
    case unavailable
}
