import Foundation

struct EntityRelationship: Identifiable, Codable {
    let id: UUID
    let sourceEntityId: UUID
    let targetEntityId: UUID
    let relationshipType: RelationshipType
    let description: String?
    let createdAt: Date
    
    enum RelationshipType: String, Codable, CaseIterable, Hashable {
        case livesIn = "Lives In"
        case owns = "Owns"
        case isLocatedIn = "Is Located In"
        case isPartOf = "Is Part Of"
        case knows = "Knows"
        case custom = "Custom"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case sourceEntityId = "source_entity_id"
        case targetEntityId = "target_entity_id"
        case relationshipType = "relationship_type"
        case description
        case createdAt = "created_at"
    }
} 