import Foundation
import Supabase

@main
struct DatabaseCleanup {
    static func main() async {
        let authManager = AuthManager()
        
        // First run diagnosis
        print("Running database diagnosis...")
        let diagnosis = await authManager.diagnoseDatabaseState()
        print(diagnosis)
        
        // Ask for confirmation before proceeding with cleanup
        print("\nWould you like to proceed with cleanup? (yes/no)")
        if let input = readLine(), input.lowercased() == "yes" {
            print("\nStarting cleanup process...")
            let cleanup = await authManager.cleanupDuplicateUsers()
            print(cleanup)
        } else {
            print("Cleanup cancelled.")
        }
    }
} 