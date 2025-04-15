//
//  Entity.swift
//  DnDictate
//
//  Created by Sam Robinson on 3/25/25.
//

import Foundation

struct Entity: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let type: EntityType
    let description: String?
    let confidence: Double
    let isConfirmed: Bool
    let sessionId: String
    let createdAt: Date
    
    // Relationships
    var relationships: [EntityRelationship]?
    
    enum EntityType: String, Codable, CaseIterable {
        case character = "Character"
        case location = "Location"
        case item = "Item"
        case description = "Description"
        case unknown = "Unknown"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case description
        case confidence
        case isConfirmed = "is_confirmed"
        case sessionId = "session_id"
        case createdAt = "created_at"
        case relationships
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Entity, rhs: Entity) -> Bool {
        lhs.id == rhs.id
    }
}
