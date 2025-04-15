//
//  HomeView.swift
//  DnDictate
//
//  Created by Sam Robinson on 3/25/25.
//

import SwiftUI
import Supabase

struct HomeView: View {
    let supabase: SupabaseClient
    
    var body: some View {
        VStack {
            Text("Hello There Traveler!")
                .font(.largeTitle)
                .padding()
            
            NavigationLink(destination: RecordingView(supabase: supabase)) {
                Text("Record Session")
                    .padding()
                    .frame(width: 200)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            NavigationLink(destination: EntityView(supabase: supabase)) {
                Text("View Instruments")
                    .padding()
                    .frame(width: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            NavigationLink(destination: EntityView2(supabase: supabase)) {
                Text("View Entities")
                    .padding()
                    .frame(width: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

#Preview {
    HomeView(supabase: SupabaseClient(supabaseURL: URL(string: "https://example.com")!, supabaseKey: ""))
}

