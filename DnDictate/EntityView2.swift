//
//  EntityView 2.swift
//  DnDictate
//
//  Created by Sam Robinson on 3/25/25.
//


import SwiftUI
import Supabase

struct EntityView2: View {
    let supabase: SupabaseClient
    @State var entities: [Entity] = []
    @State private var showAddEntitySheet = false
    @State private var newName: String = ""
    @State private var newDescription: String = ""
    @State private var newType: Entity.EntityType = .character
    @State private var errorMessage: String?
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    var body: some View {
        NavigationStack {
            List(entities) { entity in
                VStack(alignment: .leading) {
                    Text(entity.name)
                    if let description = entity.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .overlay {
                if entities.isEmpty {
                    ProgressView()
                }
            }
            .task {
                await fetchEntities()
            }
            .navigationTitle("Entities")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showAddEntitySheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddEntitySheet) {
                NavigationView {
                    Form {
                        Section(header: Text("New Entity")) {
                            TextField("Name", text: $newName)
                            
                            Picker("Type", selection: $newType) {
                                ForEach(Entity.EntityType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            
                            TextField("Description", text: $newDescription)
                        }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        }
                        
                        Button("Add") {
                            Task {
                                await addEntity()
                            }
                        }
                    }
                    .navigationTitle("Add Entity")
                    .navigationBarItems(trailing: Button("Cancel") {
                        showAddEntitySheet = false
                    })
                }
            }
        }
    }
    
    func fetchEntities() async {
        do {
            let fetchedEntities: [Entity] = try await supabase.from("entities").select().execute().value
            
            DispatchQueue.main.async {
                entities = fetchedEntities
            }
            
            print("Fetched Entities: \(fetchedEntities)")
        } catch {
            print("Error fetching entities:")
            dump(error)
        }
    }
    
    func addEntity() async {
        guard !newName.isEmpty else {
            errorMessage = "Entity name cannot be empty."
            return
        }

        let newEntity = Entity(
            id: UUID(),
            name: newName,
            type: newType,
            description: newDescription.isEmpty ? nil : newDescription,
            confidence: 1.0,
            isConfirmed: true,
            sessionId: UUID().uuidString,
            createdAt: Date()
        )
        
        do {
            try await supabase.from("entities").insert(newEntity).execute()

            // Clear form and close sheet on success
            DispatchQueue.main.async {
                newName = ""
                newDescription = ""
                newType = .character
                errorMessage = nil
                showAddEntitySheet = false
                
                // Refresh the entities list
                Task {
                    await fetchEntities()
                }
            }
        } catch {
            DispatchQueue.main.async {
                errorMessage = "Failed to add entity: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    EntityView2(supabase: SupabaseClient(supabaseURL: URL(string: "https://example.com")!, supabaseKey: ""))
}
