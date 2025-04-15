//
// EnitityView.swift
//  DnDictate
//
//  Created by Sam Robinson on 3/20/25.
//

import SwiftUI
import Supabase

struct EntityView: View {
    let supabase: SupabaseClient
    @State var instruments: [Instrument] = []
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
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
    EntityView(supabase: SupabaseClient(supabaseURL: URL(string: "https://example.com")!, supabaseKey: ""))
}
