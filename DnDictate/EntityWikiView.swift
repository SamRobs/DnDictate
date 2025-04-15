import SwiftUI
import Supabase

struct EntityWikiView: View {
    @StateObject private var viewModel: EntityWikiViewModel
    @State private var searchText = ""
    @State private var selectedEntity: Entity?
    @State private var showingEditSheet = false
    @State private var showingCreateSheet = false
    
    init(supabase: SupabaseClient) {
        _viewModel = StateObject(wrappedValue: EntityWikiViewModel(supabase: supabase))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                TextField("Search entities...", text: $searchText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                
                // Entity list
                List {
                    ForEach(viewModel.filteredEntities(searchText)) { entity in
                        EntityRow(entity: entity)
                            .onTapGesture {
                                selectedEntity = entity
                                showingEditSheet = true
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task {
                                        try? await viewModel.deleteEntity(entity)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("Entity Wiki")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let entity = selectedEntity {
                    EntityEditView(
                        entity: entity,
                        availableEntities: viewModel.entities,
                        onSave: { updatedEntity in
                            Task {
                                try? await viewModel.updateEntity(updatedEntity)
                            }
                        },
                        onDelete: {
                            Task {
                                try? await viewModel.deleteEntity(entity)
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                EntityCreateView { newEntity in
                    Task {
                        try? await viewModel.createEntity(newEntity)
                        showingCreateSheet = false
                    }
                }
            }
            .task {
                await viewModel.loadEntities()
            }
        }
    }
}

struct EntityRow: View {
    let entity: Entity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entity.name)
                .font(.headline)
            
            HStack {
                Text(entity.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if let description = entity.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            if let relationships = entity.relationships, !relationships.isEmpty {
                Text("\(relationships.count) relationships")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RelationshipsSection: View {
    let entity: Entity
    let availableEntities: [Entity]
    let onSave: (Entity) -> Void
    @Binding var showingAddRelationship: Bool
    @State private var selectedRelationship: EntityRelationship?
    @State private var showingRelatedEntity = false
    
    var body: some View {
        Section(header: Text("Relationships")) {
            if let relationships = entity.relationships {
                ForEach(relationships) { relationship in
                    RelationshipLink(
                        relationshipType: relationship.relationshipType.rawValue,
                        description: relationship.description,
                        onTap: {
                            selectedRelationship = relationship
                            showingRelatedEntity = true
                        }
                    )
                }
            }
            
            Button("Add Relationship") {
                showingAddRelationship = true
            }
        }
        .sheet(isPresented: $showingRelatedEntity) {
            if let relationship = selectedRelationship {
                let relatedEntity = Entity(
                    id: relationship.targetEntityId,
                    name: "",
                    type: .unknown,
                    description: nil,
                    confidence: 0,
                    isConfirmed: false,
                    sessionId: "",
                    createdAt: Date(),
                    relationships: nil
                )
                
                EntityEditView(
                    entity: relatedEntity,
                    availableEntities: availableEntities,
                    onSave: { _ in }
                )
            }
        }
    }
}

struct RelationshipLink: View {
    let relationshipType: String
    let description: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading) {
                Text(relationshipType)
                    .font(.headline)
                if let desc = description {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct EntityEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var type: Entity.EntityType
    @State private var description: String
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var showingAddRelationship = false
    @State private var selectedTargetEntity: Entity?
    @State private var selectedRelationshipType: EntityRelationship.RelationshipType = .custom
    @State private var relationshipDescription: String = ""
    @State private var showingDeleteConfirmation = false
    
    let entity: Entity
    let onSave: (Entity) -> Void
    let onDelete: (() -> Void)?
    let availableEntities: [Entity]
    
    init(entity: Entity, availableEntities: [Entity], onSave: @escaping (Entity) -> Void, onDelete: (() -> Void)? = nil) {
        self.entity = entity
        self.availableEntities = availableEntities
        self._name = State(initialValue: entity.name)
        self._type = State(initialValue: entity.type)
        self._description = State(initialValue: entity.description ?? "")
        self.onSave = onSave
        self.onDelete = onDelete
    }
    
    var body: some View {
        Form {
            Section(header: Text("Basic Information")) {
                TextField("Name", text: $name)
                
                Picker("Type", selection: $type) {
                    ForEach(Entity.EntityType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
            
            Section(header: Text("Description")) {
                TextEditor(text: $description)
                    .frame(minHeight: 100)
            }
            
            RelationshipsSection(
                entity: entity,
                availableEntities: availableEntities,
                onSave: onSave,
                showingAddRelationship: $showingAddRelationship
            )
            
            if onDelete != nil {
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Entity")
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Entity")
        .navigationBarItems(
            leading: Button("Cancel") {
                dismiss()
            },
            trailing: Button("Save") {
                saveEntity()
            }
        )
        .sheet(isPresented: $showingAddRelationship) {
            AddRelationshipView(
                entity: entity,
                availableEntities: availableEntities.filter { $0.id != entity.id },
                onSave: { updatedEntity in
                    onSave(updatedEntity)
                    showingAddRelationship = false
                },
                onCancel: {
                    showingAddRelationship = false
                }
            )
        }
        .alert("Delete Entity", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this entity? This action cannot be undone.")
        }
    }
    
    private func saveEntity() {
        guard !name.isEmpty else {
            errorMessage = "Name cannot be empty"
            showingError = true
            return
        }
        
        let updatedEntity = Entity(
            id: entity.id,
            name: name,
            type: type,
            description: description.isEmpty ? nil : description,
            confidence: entity.confidence,
            isConfirmed: entity.isConfirmed,
            sessionId: entity.sessionId,
            createdAt: entity.createdAt,
            relationships: entity.relationships
        )
        
        onSave(updatedEntity)
        dismiss()
    }
}

struct AddRelationshipView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTargetEntity: Entity?
    @State private var selectedRelationshipType: EntityRelationship.RelationshipType = .custom
    @State private var relationshipDescription: String = ""
    
    let entity: Entity
    let availableEntities: [Entity]
    let onSave: (Entity) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Target Entity")) {
                    if !availableEntities.isEmpty {
                        Picker("Entity", selection: $selectedTargetEntity) {
                            Text("Select an entity").tag(nil as Entity?)
                            ForEach(availableEntities) { entity in
                                Text(entity.name).tag(entity as Entity?)
                            }
                        }
                    } else {
                        Text("No entities available")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Relationship Type")) {
                    Picker("Type", selection: $selectedRelationshipType) {
                        ForEach(EntityRelationship.RelationshipType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Description")) {
                    TextField("Description", text: $relationshipDescription)
                }
                
                if selectedTargetEntity != nil {
                    Button("Add Relationship") {
                        if let targetEntity = selectedTargetEntity {
                            let relationship = EntityRelationship(
                                id: UUID(),
                                sourceEntityId: entity.id,
                                targetEntityId: targetEntity.id,
                                relationshipType: selectedRelationshipType,
                                description: relationshipDescription.isEmpty ? nil : relationshipDescription,
                                createdAt: Date()
                            )
                            
                            var updatedEntity = entity
                            if updatedEntity.relationships == nil {
                                updatedEntity.relationships = []
                            }
                            updatedEntity.relationships?.append(relationship)
                            onSave(updatedEntity)
                        }
                    }
                }
            }
            .navigationTitle("Add Relationship")
            .navigationBarItems(trailing: Button("Cancel", action: onCancel))
        }
    }
}

struct EntityCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var type: Entity.EntityType = .character
    @State private var description: String = ""
    @State private var showingError = false
    @State private var errorMessage: String?
    
    let onCreate: (Entity) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $name)
                    
                    Picker("Type", selection: $type) {
                        ForEach(Entity.EntityType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Description")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Create Entity")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Create") {
                    createEntity()
                }
            )
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func createEntity() {
        guard !name.isEmpty else {
            errorMessage = "Name cannot be empty"
            showingError = true
            return
        }
        
        let newEntity = Entity(
            id: UUID(),
            name: name,
            type: type,
            description: description.isEmpty ? nil : description,
            confidence: 1.0,
            isConfirmed: true,
            sessionId: UUID().uuidString,
            createdAt: Date(),
            relationships: []
        )
        
        onCreate(newEntity)
    }
}

@MainActor
class EntityWikiViewModel: ObservableObject {
    @Published var entities: [Entity] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func loadEntities() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard try await supabase.auth.session != nil else {
                throw NSError(domain: "EntityWiki", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            let response = try await supabase.from("entities")
                .select()
                .order("name")
                .execute()
            
            let decoder = JSONDecoder()
            let data = try JSONSerialization.data(withJSONObject: response.data)
            entities = try decoder.decode([Entity].self, from: data)
            
        } catch {
            errorMessage = "Failed to load entities: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateEntity(_ entity: Entity) async throws {
        guard try await supabase.auth.session != nil else {
            throw NSError(domain: "EntityWiki", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        do {
            try await supabase.from("entities")
                .update([
                    "name": entity.name,
                    "type": entity.type.rawValue,
                    "description": entity.description,
                    "updated_at": Date().ISO8601Format()
                ])
                .eq("id", value: entity.id)
                .execute()
            
            // Reload entities to reflect changes
            await loadEntities()
            
        } catch {
            throw NSError(domain: "EntityWiki", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Failed to update entity",
                NSUnderlyingErrorKey: error
            ])
        }
    }
    
    func createEntity(_ entity: Entity) async throws {
        guard try await supabase.auth.session != nil else {
            throw NSError(domain: "EntityWiki", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        do {
            try await supabase.from("entities")
                .insert([
                    "name": entity.name,
                    "type": entity.type.rawValue,
                    "description": entity.description,
                    "created_at": Date().ISO8601Format(),
                    "updated_at": Date().ISO8601Format()
                ])
                .execute()
            
            // Reload entities to include the new one
            await loadEntities()
            
        } catch {
            throw NSError(domain: "EntityWiki", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create entity",
                NSUnderlyingErrorKey: error
            ])
        }
    }
    
    func filteredEntities(_ searchText: String) -> [Entity] {
        if searchText.isEmpty {
            return entities
        }
        
        return entities.filter { entity in
            entity.name.localizedCaseInsensitiveContains(searchText) ||
            (entity.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    func deleteEntity(_ entity: Entity) async throws {
        guard try await supabase.auth.session != nil else {
            throw NSError(domain: "EntityWiki", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        do {
            try await supabase
                .from("entities")
                .delete()
                .eq("id", value: entity.id)
                .execute()
            
            await loadEntities() // Reload the list
        } catch {
            throw NSError(domain: "EntityWiki", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Failed to delete entity",
                NSUnderlyingErrorKey: error
            ])
        }
    }
}

#Preview {
    EntityWikiView(supabase: SupabaseClient(supabaseURL: URL(string: "PREVIEW_URL")!, supabaseKey: "PREVIEW_KEY"))
} 