import SwiftUI

struct AuthView: View {
    @State private var email = "johndoe@pacifica.demo"
    @State private var password = ""
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Sign in to test Pacifica") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button(isSigningIn ? "Signing in…" : "Sign in") {
                    Task { await signIn() }
                }
                .disabled(isSigningIn || email.isEmpty || password.isEmpty)
            }
            .navigationTitle("Pacifica")
        }
    }

    private func signIn() async {
        isSigningIn = true
        errorMessage = nil
        defer { isSigningIn = false }

        do {
            try await SupabaseClientProvider.shared.auth.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AuthView()
}
