//
//  BookRequest.swift
//  BookWize
//
//  Created by Abcom on 26/03/25.
//


import Foundation
struct BookRequest: Codable {
    let Request_id: UUID
    let author: String  // Changed from type to author
    let title: String
    let quantity: Int
    let reason: String
    let Request_status: R_status
    let createdAt: Date
    
    enum R_status : String, Codable, CaseIterable{
        case pending
        case approved
        case rejected
    }
    
    enum CodingKeys: String, CodingKey {
        case Request_id
        case author  // Changed from type to author
        case title
        case quantity
        case reason
        case Request_status 
        case createdAt = "created_at"
    }
}
