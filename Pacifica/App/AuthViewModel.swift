import Foundation
import Observation

/// Sign-in state and logic, moved unchanged out of AuthView. AppRootView navigates on Supabase's auth state changes.
@Observable
@MainActor
final class AuthViewModel {
    typealias SignIn = @Sendable (_ email: String, _ password: String) async throws -> Void

    static let demoEmail = "johndoe@pacifica.demo"

    var email = AuthViewModel.demoEmail
    var password = ""
    private(set) var isSigningIn = false
    private(set) var errorMessage: String?
    /// Incremented on each failed sign-in; drives the shake and warning haptic.
    private(set) var failedAttempts = 0

    private let signInAction: SignIn

    init(signIn: @escaping SignIn = { email, password in
        _ = try await SupabaseClientProvider.shared.auth.signIn(email: email, password: password)
    }) {
        self.signInAction = signIn
    }

    /// Same rule as the original Sign in button's `.disabled(...)`.
    var canSignIn: Bool {
        !isSigningIn && !email.isEmpty && !password.isEmpty
    }

    func signIn() async {
        guard canSignIn else { return }
        isSigningIn = true
        errorMessage = nil
        defer { isSigningIn = false }

        do {
            try await signInAction(email.trimmingCharacters(in: .whitespacesAndNewlines), password)
        } catch {
            errorMessage = error.localizedDescription
            failedAttempts += 1
        }
    }

    /// Restores the demo email the screen starts with. The demo password isn't stored in the app.
    func useDemoAccount() {
        email = Self.demoEmail
        errorMessage = nil
    }
}

#if DEBUG
extension AuthViewModel {
    static func preview(
        email: String = demoEmail,
        password: String = "",
        isSigningIn: Bool = false,
        errorMessage: String? = nil
    ) -> AuthViewModel {
        let viewModel = AuthViewModel { _, _ in
            try await Task.sleep(for: .seconds(1))
            throw URLError(.userAuthenticationRequired)
        }
        viewModel.email = email
        viewModel.password = password
        viewModel.isSigningIn = isSigningIn
        viewModel.errorMessage = errorMessage
        return viewModel
    }
}
#endif
