import SwiftUI
import Supabase

// Singleton for Supabase client with proper session management
@MainActor
final class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    let client: SupabaseClient
    @Published private(set) var session: Session?
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://kwdtkmdppbizgrhiuair.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt3ZHRrbWRwcGJpemdyaGl1YWlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc4MzYzMDAsImV4cCI6MjA1MzQxMjMwMH0.nbXalXiXDrOmaBMI1OlTw7gr74dZiLj93orCOqXD2qs"
        )
        
        // Initialize session
        Task {
            await initializeSession()
        }
    }
    
    private func initializeSession() async {
        do {
            session = try await client.auth.session
        } catch {
            print("Error initializing session: \(error)")
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        session = response
    }
    
    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            redirectTo: URL(string: "https://example.com/welcome")
        )
        session = response.session
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        session = nil
    }
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var authStatus: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared
    
    func signUp() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.signUp(email: email, password: password)
            authStatus = "Sign up successful!"
        } catch {
            errorMessage = error.localizedDescription
            authStatus = "Sign up failed"
        }
    }

    func signIn() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.signIn(email: email, password: password)
            authStatus = "Sign in successful!"
        } catch {
            errorMessage = error.localizedDescription
            authStatus = "Sign in failed"
        }
    }
}

struct SignInView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isLoggedIn = false
    @EnvironmentObject private var supabaseManager: SupabaseManager

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
                    if viewModel.authStatus.contains("successful") {
                        isLoggedIn = true
                    }
                }
            }
            .disabled(viewModel.isLoading)
            .padding()

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Text(viewModel.authStatus)
                .foregroundColor(viewModel.authStatus.contains("failed") ? .red : .green)
                .padding()
        }
        .background(
            NavigationLink(destination: HomeView(supabase: supabaseManager.client), isActive: $isLoggedIn) {
                EmptyView()
            }
            .hidden()
        )
    }
}

struct SignUpView: View {
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject private var supabaseManager: SupabaseManager

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
            .disabled(viewModel.isLoading)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Text(viewModel.authStatus)
                .foregroundColor(viewModel.authStatus.contains("failed") ? .red : .green)
        }
    }
}
