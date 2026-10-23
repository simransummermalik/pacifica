import Foundation
import Supabase

/// Creates the app's Supabase client.
///
/// Replace the two placeholder values locally before making Supabase requests.
/// Use the publishable key from the Supabase Connect/API panel. Never use the
/// service_role key in this iOS app.
enum SupabaseClientProvider {
    static let shared: SupabaseClient = {
        let projectURLString = "https://upazsathfbfltyowjfjb.supabase.co"
        let publishableKey = "sb_publishable_xNMRuNmWAlOm0pC13hES-A_MPYvVWJj"

        guard
            let projectURL = URL(string: projectURLString),
            projectURL.scheme == "https",
            !publishableKey.hasPrefix("REPLACE_WITH_")
        else {
            fatalError(
                "Set the Supabase project URL and publishable key in SupabaseClient.swift before using Supabase."
            )
        }

        return SupabaseClient(
            supabaseURL: projectURL,
            supabaseKey: publishableKey
        )
    }()
}
