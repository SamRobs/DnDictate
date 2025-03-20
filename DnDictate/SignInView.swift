//
//  SignInView.swift
//  DnDictate
//
//  Created by Sam Robinson on 3/25/25.
//


import SwiftUI

struct SignInView: View {
    @StateObject var viewModel = AuthViewModel()

    var body: some View {
        VStack {
            Text("Sign In")
                .font(.title)
                .padding()

            Form {
                TextField("Email", text: $viewModel.email)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $viewModel.password)
            }

            Button("Sign In") {
                Task {
                    await viewModel.signIn()
                }
            }
            .padding()

            Text(viewModel.authStatus)
                .foregroundColor(viewModel.authStatus.contains("failed") ? .red : .green)
                .padding()
        }
    }
}

#Preview {
    SignInView()
}