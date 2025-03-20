//
//  AuthSelectionView.swift
//  DnDictate
//
//  Created by Sam Robinson on 3/25/25.
//


import SwiftUI

struct AuthSelectionView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome!")
                    .font(.title)
                    .padding()

                NavigationLink("Sign Up", destination: SignUpView())
                    .padding()

                NavigationLink("Sign In", destination: SignInView())
                    .padding()
            }
        }
    }
}

#Preview {
    AuthSelectionView()
}