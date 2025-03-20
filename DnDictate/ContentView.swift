////
////  ContentView.swift
////  DnDictate
////
////  Created by Sam Robinson on 3/20/25.
////

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome to DnDictate")
                    .font(.title)
                    .padding()

                NavigationLink(destination: AuthSelectionView()) {
                    Text("Sign Up/Sign In")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
