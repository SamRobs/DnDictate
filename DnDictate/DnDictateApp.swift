////
////  DnDictateApp.swift
////  DnDictate
////
////  Created by Sam Robinson on 3/20/25.
////

import SwiftUI
import Supabase

@main
struct DnDictateApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabaseManager)
        }
    }
}
