import Supabase
import SwiftUI

struct AppRootView: View {
    @State private var userID: UUID?
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                ProgressView("Loading Pacifica…")
            } else if let userID {
                RootView(userID: userID)
            } else {
                AuthView()
            }
        }
        .task {
            for await state in SupabaseClientProvider.shared.auth.authStateChanges {
                guard [.initialSession, .signedIn, .signedOut].contains(state.event) else {
                    continue
                }

                userID = state.session?.user.id
                isCheckingSession = false
            }
        }
    }
}

#Preview {
    AppRootView()
}
