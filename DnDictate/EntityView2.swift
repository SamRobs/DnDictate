//
//  EntityView 2.swift
//  DnDictate
//
//  Created by Sam Robinson on 3/25/25.
//


import SwiftUI

struct EntityView2: View {
    
    @State var entities: [Entity] = []
    
    var body: some View {
        NavigationStack {
            List(entities) { entity in
                Text(entity.name)
                Text(entity.description)
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
                        Task {
                            await addEntity()
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    func fetchEntities() async {
        do {
            let fetchedEntities: [Entity] = try await supabase.from("Entities").select().execute().value
            
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
        let newEntity = Entity(id: UUID().hashValue, name: "New Entity", description: "New Entity Description") // Replace with actual entity properties
        
        do {
            try await supabase.from("Entities").insert(newEntity).execute()
            
            DispatchQueue.main.async {
                entities.append(newEntity)
            }
            
            print("Added new entity: \(newEntity)")
        } catch {
            print("Error adding entity:")
            dump(error)
        }
    }
}
