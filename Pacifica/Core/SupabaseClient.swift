import Foundation
import Supabase

enum SupabaseClientProvider {
    static let shared: SupabaseClient = {
        let projectURL = URL(string: "https://upazsathfbfltyowjfjb.supabase.co")!
        let publishableKey = "sb_publishable_xNMRuNmWAlOm0pC13hES-A_MPYvVWJj"
        return SupabaseClient(supabaseURL: projectURL, supabaseKey: publishableKey)
    }()
}
