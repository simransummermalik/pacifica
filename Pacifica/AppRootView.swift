import Foundation
import SwiftUI

struct AppRootView: View {
    @State private var isSignedIn: Bool?
    @State private var userID: UUID?

    var body: some View {
        Group {
            if isSignedIn == nil {
                ProgressView("Loading Pacifica…")
            } else if isSignedIn == true, let userID {
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

                isSignedIn = state.session != nil
                userID = state.session?.user.id
            }
        }
    }
}

#Preview {
    AppRootView()
}
