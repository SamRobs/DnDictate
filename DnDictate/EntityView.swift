//
//  ContentView 2.swift
//  DnDictate
//
//  Created by Sam Robinson on 3/20/25.
//


//
//  ContentView.swift
//  DnDictate
//
//  Created by Sam Robinson on 3/20/25.
//

import SwiftUI

struct EntityView: View {
    
    @State var instruments: [Instrument] = []
    
    
    var body: some View {
        List(instruments) { instrument in
            Text(instrument.name)
        }
        .overlay {
            if instruments.isEmpty {
                ProgressView()
            }
        }
        .task {
            do {
                instruments = try await supabase.from("instruments").select().execute().value
            } catch {
                dump(error)
            }
        }
    }
}

#Preview {
    EntityView()
}
