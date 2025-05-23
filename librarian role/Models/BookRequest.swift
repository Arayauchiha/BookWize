import Foundation
import SwiftUICore
import UIKit

struct BookRequest: Codable, Identifiable, Hashable {
    let Request_id: UUID
    let author: String
    let title: String
    let quantity: Int
    let reason: String
    let Request_status: R_status
    let createdAt: Date
    
    // Conform to Identifiable
    var id: UUID {
        return Request_id
    }
    
    enum R_status: String, Codable, CaseIterable, Hashable {
        case pending
        case approved
        case rejected
        
        var background : Color{
            switch self{
            case .pending : return .orange
            case .approved : return .green
            case .rejected : return .red
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case Request_id
        case author
        case title
        case quantity
        case reason
        case Request_status
        case createdAt = "created_at"
    }
}
