import SwiftUI
import Supabase


class AuthViewModel: ObservableObject { // Renamed from SignUpViewModel
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var authStatus: String = "" // Renamed from signUpStatus

    func signUp() async {
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                redirectTo: URL(string: "https://example.com/welcome")
            )
            DispatchQueue.main.async {
                self.authStatus = "Sign up successful!"
            }
        } catch {
            DispatchQueue.main.async {
                self.authStatus = "Sign up failed: \(error.localizedDescription)"
            }
        }
    }

    func signIn() async { // New function for sign-in
        do {
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            DispatchQueue.main.async {
                self.authStatus = "Sign in successful!"
            }
        } catch {
            DispatchQueue.main.async {
                self.authStatus = "Sign in failed: \(error.localizedDescription)"
            }
        }
    }
}

struct SignUpView: View {
    @StateObject var viewModel = AuthViewModel() // Updated to use AuthViewModel

    var body: some View {
        VStack {
            Text("Email and Password")
            Form {
                TextField("Email", text: $viewModel.email)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $viewModel.password)
            }

            Button("Sign Up") {
                Task {
                    await viewModel.signUp()
                }
            }
            Text(viewModel.authStatus) // Updated to use authStatus
        }
    }
}

#Preview {
    SignUpView()
}
