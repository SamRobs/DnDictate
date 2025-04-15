////
////  ContentView.swift
////  DnDictate
////
////  Created by Sam Robinson on 3/20/25.
////

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var isAuthenticated = false
    
    var body: some View {
        Group {
            if isAuthenticated {
                TabView {
                    RecordingView(supabase: supabaseManager.client)
                        .tabItem {
                            Label("Record", systemImage: "mic")
                        }
                    
                    EntityWikiView(supabase: supabaseManager.client)
                        .tabItem {
                            Label("Wiki", systemImage: "book")
                        }
                }
            } else {
                SignInView()
            }
        }
        .onAppear {
            isAuthenticated = supabaseManager.session != nil
        }
        .onChange(of: supabaseManager.session) { newSession in
            isAuthenticated = newSession != nil
        }
    }
}

#Preview {
    ContentView()
}
