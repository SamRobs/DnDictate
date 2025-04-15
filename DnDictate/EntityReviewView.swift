import SwiftUI

struct EntityReviewView: View {
    @StateObject private var extractor = EntityExtractor()
    @State private var showingConfirmation = false
    @State private var selectedEntity: ExtractedEntity?
    @State private var showError = false
    
    let transcriptionText: String
    let sessionId: String
    
    var body: some View {
        VStack {
            // Low Confidence Terms Section
            if !extractor.lowConfidenceTerms.isEmpty {
                VStack(alignment: .leading) {
                    Text("Review Required")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(extractor.lowConfidenceTerms) { term in
                                LowConfidenceTermView(term: term) {
                                    selectedEntity = term
                                    showingConfirmation = true
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding()
            }
            
            // All Entities Section
            VStack(alignment: .leading) {
                Text("Extracted Entities")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(extractor.entities) { entity in
                            ExtractedEntityRowView(entity: entity) {
                                if !entity.isConfirmed {
                                    selectedEntity = entity
                                    showingConfirmation = true
                                }
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding()
        }
        .onAppear {
            extractor.setSessionId(sessionId)
            extractor.extractEntities(from: transcriptionText)
        }
        .alert("Confirm Entity", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm") {
                if let entity = selectedEntity {
                    Task {
                        await extractor.confirmEntity(entity)
                    }
                }
            }
        } message: {
            if let entity = selectedEntity {
                Text("Is '\(entity.text)' a valid \(entity.type.rawValue)?")
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = extractor.errorMessage {
                Text(error)
            }
        }
    }
}

struct LowConfidenceTermView: View {
    let term: ExtractedEntity
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(term.text)
                    .font(.headline)
                Text("\(term.type.rawValue) • Confidence: \(Int(term.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
        .onTapGesture(perform: onTap)
    }
}

struct ExtractedEntityRowView: View {
    let entity: ExtractedEntity
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entity.text)
                    .font(.headline)
                Text(entity.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if entity.isConfirmed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                // Confidence indicator
                Circle()
                    .fill(confidenceColor)
                    .frame(width: 20, height: 20)
                    .onTapGesture(perform: onTap)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
    
    private var confidenceColor: Color {
        switch entity.confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .yellow
        default:
            return .red
        }
    }
}

#Preview {
    EntityReviewView(
        transcriptionText: "The wizard Gandalf entered the city of Minas Tirith with the One Ring.",
        sessionId: "test-session"
    )
} 