import Foundation
import NaturalLanguage
import Supabase

struct ExtractedEntity: Identifiable {
    let id = UUID()
    let text: String
    let type: EntityType
    let confidence: Double
    let range: Range<String.Index>
    var isConfirmed: Bool = false
    
    enum EntityType: String {
        case character = "Character"
        case location = "Location"
        case item = "Item"
        case description = "Description"
        case unknown = "Unknown"
    }
}

class EntityExtractor: ObservableObject {
    @Published var entities: [ExtractedEntity] = []
    @Published var lowConfidenceTerms: [ExtractedEntity] = []
    @Published var errorMessage: String?
    
    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
    private let confidenceThreshold = 0.7 // Adjust this threshold as needed
    private var sessionId: String?
    
    func setSessionId(_ id: String) {
        sessionId = id
    }
    
    func extractEntities(from text: String) {
        entities.removeAll()
        lowConfidenceTerms.removeAll()
        
        tagger.string = text
        
        // Configure the tagger
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        // Extract named entities
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            if let tag = tag {
                let entityText = String(text[range])
                let confidence = calculateConfidence(for: entityText, tag: tag)
                
                let entityType = mapTagToEntityType(tag)
                let entity = ExtractedEntity(
                    text: entityText,
                    type: entityType,
                    confidence: confidence,
                    range: range
                )
                
                DispatchQueue.main.async {
                    self.entities.append(entity)
                    if confidence < self.confidenceThreshold {
                        self.lowConfidenceTerms.append(entity)
                    }
                }
            }
            return true
        }
    }
    
    func confirmEntity(_ entity: ExtractedEntity) async {
        guard let sessionId = sessionId else {
            errorMessage = "No session ID set"
            return
        }
        
        do {
            let dbEntity = Entity(
                id: entity.id,
                name: entity.text,
                type: Entity.EntityType(rawValue: entity.type.rawValue) ?? .unknown,
                description: nil,
                confidence: entity.confidence,
                isConfirmed: true,
                sessionId: sessionId,
                createdAt: Date()
            )
            
            try await supabase.from("entities").insert(dbEntity).execute()
            
            // Update local state
            DispatchQueue.main.async {
                if let index = self.entities.firstIndex(where: { $0.id == entity.id }) {
                    var updatedEntity = self.entities[index]
                    updatedEntity.isConfirmed = true
                    self.entities[index] = updatedEntity
                }
                
                // Remove from low confidence terms if present
                self.lowConfidenceTerms.removeAll { $0.id == entity.id }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to save entity: \(error.localizedDescription)"
            }
        }
    }
    
    private func calculateConfidence(for text: String, tag: NLTag) -> Double {
        // Base confidence on various factors
        var confidence = 0.5 // Start with neutral confidence
        
        // Check if the word is capitalized (common for names)
        if text.first?.isUppercase == true {
            confidence += 0.2
        }
        
        // Check word length (very short or very long words might be fantasy terms)
        if text.count < 3 {
            confidence -= 0.2
        } else if text.count > 10 {
            confidence -= 0.1
        }
        
        // Check for common fantasy name patterns
        if containsFantasyPatterns(text) {
            confidence -= 0.3
        }
        
        // Normalize confidence to 0-1 range
        return max(0.0, min(1.0, confidence))
    }
    
    private func containsFantasyPatterns(_ text: String) -> Bool {
        // Common fantasy name patterns
        let patterns = [
            "ae", "wyn", "wynn", "dwyn", "wynne", // Welsh patterns
            "thor", "odin", "loki", // Norse patterns
            "el", "il", "al", // Elvish patterns
            "zz", "xx", "kk", // Double consonant patterns
            "'", "-" // Special characters
        ]
        
        return patterns.contains { text.lowercased().contains($0) }
    }
    
    private func mapTagToEntityType(_ tag: NLTag) -> ExtractedEntity.EntityType {
        switch tag {
        case .personalName:
            return .character
        case .placeName:
            return .location
        case .organizationName:
            return .item // Could be a magical organization or guild
        default:
            return .unknown
        }
    }
} 