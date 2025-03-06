import Foundation
import Supabase
import CoreLocation

@MainActor
class AuthManager: NSObject, ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: AuthError?
    
    private let supabase: SupabaseClient
    private let userService = UserService.shared
    private let locationManager = CLLocationManager()
    
    override init() {
        self.supabase = SupabaseConfig.client
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Request location permissions immediately
        requestLocationPermissions()
        
        // Check for existing session on init
        Task {
            await checkAndRestoreSession()
        }
    }
    
    func requestLocationPermissions() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // New method to check and restore session on app launch
    func checkAndRestoreSession() async {
        do {
            isLoading = true
            
            // First try to get the current session
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            print("Found existing session for user ID: \(userId.uuidString)")
            
            // Try to get the user from the database
            let user = try await userService.fetchUser(id: userId.uuidString)
            
            // Set the current user and authentication state
            self.currentUser = user
            self.isAuthenticated = true
            print("Successfully restored user session")
            
        } catch let sessionError {
            // Provide more detailed error logging
            print("No existing session found or error: \(sessionError.localizedDescription)")
            
            if sessionError.localizedDescription.contains("sessionMissing") {
                print("Session missing - user needs to log in")
            } else {
                print("Error type: \(type(of: sessionError))")
                print("Error details: \(sessionError)")
            }
            
            self.isAuthenticated = false
            self.currentUser = nil
        }
        
        isLoading = false
    }
    
    func logIn(_ email: String, _ password: String) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            print("Attempting login with email: \(email)")
            
            // Remove the session check that was causing the error
            // and directly attempt to sign in
            let authResponse = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            print("Auth success - User ID: \(authResponse.user.id)")
            print("User metadata: \(authResponse.user.userMetadata)")
            
            // First check if user exists in public.users table
            print("Checking if user exists in public.users table...")
            let userCheck = try await supabase
                .from("users")
                .select("id, email")
                .eq("id", value: authResponse.user.id.uuidString)
                .execute()
            
            print("User check result: \(userCheck.data.count) records found")
            
            if userCheck.data.count == 0 {
                print("No profile found, creating new user profile...")
                
                // Get user's name from metadata or use default
                let userName = authResponse.user.userMetadata["name"]?.value as? String ?? "User"
                
                // Create new user profile with minimal data first
                let minimalUser: [String: AnyJSON] = [
                    "id": try AnyJSON(authResponse.user.id.uuidString),
                    "email": try AnyJSON(email),
                    "profile": try AnyJSON([
                        "name": try AnyJSON(userName),
                        "joinDate": try AnyJSON(Date().ISO8601Format())
                    ])
                ]
                
                do {
                    print("Attempting to insert minimal user profile...")
                    let insertResult = try await supabase
                        .from("users")
                        .insert(minimalUser)
                        .execute()
                    
                    print("Successfully created minimal user profile: \(insertResult)")
                    
                    // Now create the full user profile
                    let newUser = User(
                        id: authResponse.user.id.uuidString,
                        email: email,
                        profile: User.Profile(
                            name: userName,
                            avatar: "person.circle.fill",
                            bio: "",
                            location: User.Profile.Location(
                                latitude: 0,
                                longitude: 0,
                                address: ""
                            ),
                            joinDate: Date(),
                            social: User.Profile.Social.empty
                        ),
                        vehicles: [],
                        friends: [],
                        isPremium: false,
                        achievements: [],
                        preferences: User.Preferences.defaultPreferences,
                        upcomingMeets: nil
                    )
                    
                    print("Attempting to update to full user profile...")
                    let updateResult = try await supabase
                        .from("users")
                        .update(newUser)
                        .eq("id", value: authResponse.user.id.uuidString)
                        .execute()
                    
                    print("Successfully updated to full user profile: \(updateResult)")
                    await MainActor.run {
                        self.currentUser = newUser
                        self.isAuthenticated = true
                        // Request location permissions after successful authentication
                        self.requestLocationPermissions()
                    }
                } catch let createError {
                    print("Failed to create/update user profile: \(createError)")
                    print("Error type: \(type(of: createError))")
                    print("Error description: \(createError.localizedDescription)")
                    print("Error details: \(createError)")
                    
                    if let supabaseError = createError as? SupabaseError {
                        switch supabaseError {
                        case .failedToCreateUser:
                            print("Failed to create user in database")
                            await MainActor.run { self.error = .databaseError }
                        case .failedToGetUser:
                            print("Failed to get user from database")
                            await MainActor.run { self.error = .userProfileNotFound }
                        case .failedToUpdateUser:
                            print("Failed to update user in database")
                            await MainActor.run { self.error = .databaseError }
                        case .userNotFound:
                            print("User not found in database")
                            await MainActor.run { self.error = .userProfileNotFound }
                        default:
                            print("Unknown Supabase error occurred")
                            await MainActor.run { self.error = .databaseError }
                        }
                    } else {
                        print("Non-Supabase error occurred: \(createError)")
                        await MainActor.run { self.error = .databaseError }
                    }
                }
            } else {
                print("User profile found, fetching full profile...")
                
                do {
                    let response = try await supabase
                        .from("users")
                        .select()
                        .eq("id", value: authResponse.user.id.uuidString)
                        .single()
                        .execute()
                    
                    // Print raw response for debugging
                    if let jsonString = String(data: response.data, encoding: .utf8) {
                        print("Raw user data: \(jsonString)")
                    }
                    
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let profile: User = try decoder.decode(User.self, from: response.data)
                    print("Successfully decoded user profile")
                    
                    // Create a new user with updated joinDate if needed
                    let updatedUser = User(
                        id: profile.id,
                        email: profile.email,
                        profile: User.Profile(
                            name: profile.profile.name,
                            avatar: profile.profile.avatar,
                            bio: profile.profile.bio,
                            location: profile.profile.location,
                            joinDate: profile.profile.joinDate ?? Date(),
                            social: profile.profile.social
                        ),
                        vehicles: profile.vehicles,
                        friends: profile.friends,
                        isPremium: profile.isPremium,
                        achievements: profile.achievements,
                        preferences: profile.preferences,
                        upcomingMeets: profile.upcomingMeets
                    )
                    
                    // Ensure state updates happen on the main thread and are synchronized
                    await MainActor.run {
                        print("Updating authentication state on main thread")
                        self.currentUser = updatedUser
                        self.isAuthenticated = true
                        self.isLoading = false
                        self.error = nil
                        // Request location permissions after successful authentication
                        self.requestLocationPermissions()
                    }
                    
                    print("Authentication state updated successfully")
                } catch let profileError {
                    print("Error fetching profile: \(profileError)")
                    print("Error type: \(type(of: profileError))")
                    print("Error description: \(profileError.localizedDescription)")
                    print("Error details: \(profileError)")
                    
                    if let decodingError = profileError as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("Missing key: \(key.stringValue)")
                            print("Coding path: \(context.codingPath)")
                        case .typeMismatch(let type, let context):
                            print("Type mismatch: expected \(type)")
                            print("Coding path: \(context.codingPath)")
                        case .valueNotFound(let type, let context):
                            print("Value not found: expected \(type)")
                            print("Coding path: \(context.codingPath)")
                        case .dataCorrupted(let context):
                            print("Data corrupted: \(context.debugDescription)")
                        @unknown default:
                            print("Unknown decoding error")
                        }
                    }
                    
                    if let supabaseError = profileError as? SupabaseError {
                        switch supabaseError {
                        case .failedToGetUser:
                            print("Failed to get user from database")
                            await MainActor.run { self.error = .userProfileNotFound }
                        case .userNotFound:
                            print("User not found in database")
                            await MainActor.run { self.error = .userProfileNotFound }
                        default:
                            print("Unknown Supabase error occurred")
                            await MainActor.run { self.error = .databaseError }
                        }
                    } else {
                        print("Non-Supabase error occurred: \(profileError)")
                        await MainActor.run { self.error = .databaseError }
                    }
                }
            }
        } catch let authError {
            print("Authentication error: \(authError)")
            print("Error type: \(type(of: authError))")
            print("Error description: \(authError.localizedDescription)")
            print("Error details: \(authError)")
            
            // Add specific handling for sessionMissing error
            if authError.localizedDescription.contains("sessionMissing") {
                print("Session missing error detected - this is expected during login")
                await MainActor.run { self.error = .invalidSession }
            } else if let supabaseError = authError as? SupabaseError {
                switch supabaseError {
                case .userNotFound:
                    print("User not found during authentication")
                    await MainActor.run { self.error = .userNotFound }
                case .failedToCreateUser:
                    print("Failed to create user during authentication")
                    await MainActor.run { self.error = .databaseError }
                case .failedToGetUser:
                    print("Failed to get user during authentication")
                    await MainActor.run { self.error = .userProfileNotFound }
                case .failedToUpdateUser:
                    print("Failed to update user during authentication")
                    await MainActor.run { self.error = .databaseError }
                default:
                    print("Unknown Supabase error occurred during authentication")
                    await MainActor.run { self.error = .unknown }
                }
            } else {
                print("Non-Supabase error occurred during authentication: \(authError)")
                await MainActor.run { self.error = .unknown }
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func signUp(_ email: String, _ password: String, _ name: String) async {
        isLoading = true
        error = nil
        
        do {
            print("Starting signup process for email: \(email)")
            
            // 1. First, check if user already exists in auth.users
            let existingUser = try await supabase
                .from("auth.users")
                .select("id")
                .eq("email", value: email)
                .single()
                .execute()
            
            if existingUser.data.count > 0 {
                self.error = .emailAlreadyInUse
                isLoading = false
                return
            }
            
            // 2. Create auth user
            let session = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": AnyJSON(name)]
            )
            
            print("Auth user created with ID: \(session.user.id)")
            
            // 3. Create public user profile with minimal data first
            let minimalUser: [String: AnyJSON] = [
                "id": try AnyJSON(session.user.id.uuidString),
                "email": try AnyJSON(email),
                "profile": try AnyJSON([
                    "name": try AnyJSON(name)
                ])
            ]
            
            try await supabase
                .from("users")
                .insert(minimalUser)
                .execute()
            
            print("Minimal user profile created")
            
            // 4. Now create the full user profile
            let newUser = User(
                id: session.user.id.uuidString,
                email: email,
                profile: User.Profile(
                    name: name,
                    avatar: "person.circle.fill",
                    bio: "",
                    location: User.Profile.Location(
                        latitude: 0,
                        longitude: 0,
                        address: ""
                    ),
                    joinDate: Date(),
                    social: User.Profile.Social.empty
                ),
                vehicles: [],
                friends: [],
                isPremium: false,
                achievements: [],
                preferences: User.Preferences.defaultPreferences,
                upcomingMeets: nil
            )
            
            try await supabase
                .from("users")
                .update(newUser)
                .eq("id", value: session.user.id.uuidString)
                .execute()
            
            print("Full user profile created")
            self.currentUser = newUser
            self.isAuthenticated = true
            
            // Request location permissions after successful signup
            self.requestLocationPermissions()
            
        } catch let signupError {
            print("Signup Error: \(signupError)")
            print("Error Type: \(type(of: signupError))")
            
            let errorString = signupError.localizedDescription.lowercased()
            if errorString.contains("duplicate key") {
                self.error = .emailAlreadyInUse
            } else if errorString.contains("network") {
                self.error = .networkError
            } else if errorString.contains("password") {
                self.error = .invalidPassword
            } else {
                self.error = .unknown
            }
        }
        
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            self.error = .unknown
            print("Error signing out: \(error)")
        }
    }
    
    func resetPassword(_ email: String) async {
        isLoading = true
        error = nil
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            self.error = .unknown
            print("Error resetting password: \(error)")
        }
        
        isLoading = false
    }
    
    func updateProfile(_ profile: User) async {
        isLoading = true
        error = nil
        
        do {
            try await supabase
                .from("users")
                .update(profile)
                .eq("id", value: profile.id)
                .execute()
            
            self.currentUser = profile
        } catch {
            self.error = .unknown
            print("Error updating profile: \(error)")
        }
        
        isLoading = false
    }
    
    // Test function to check Supabase connection
    func testConnection() async -> String {
        do {
            // Test basic connection to Supabase
            _ = try await supabase.auth.session
            let connectionStatus = "Connection successful! Session created"
            
            // Test users table
            do {
                print("Testing users table existence...")
                _ = try await supabase
                    .from("users")
                    .select("id")
                    .limit(1)
                    .execute()
                
                return connectionStatus + "\nUsers table exists and is accessible."
            } catch {
                return connectionStatus + "\nConnection works but users table test failed: \(error.localizedDescription)"
            }
        } catch {
            return "Connection error: \(error.localizedDescription)"
        }
    }
    
    // Add a function to check the users table structure
    func checkDatabaseStructure() async -> String {
        do {
            var report = "Database Structure Check:\n"
            
            // Check if users table exists and get a sample record
            let query = try await supabase
                .from("users")
                .select("id")
                .limit(1)
                .execute()
            
            let data = query.data
            if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], !json.isEmpty {
                report += "- Users table exists and has structure: \(json[0].keys.joined(separator: ", "))\n"
            } else {
                report += "- Users table exists but couldn't parse structure\n"
            }
            
            return report
        } catch {
            return "Error checking database structure: \(error.localizedDescription)"
        }
    }
    
    // Function to manually create a user record for diagnostic purposes
    func createTestUserRecord(userId: String, email: String) async -> String {
        do {
            print("Attempting to manually create user record with ID: \(userId)")
            
            // Create initial user profile
            let newUser = User(
                id: userId,
                email: email,
                profile: User.Profile(
                    name: "Test User",
                    avatar: "person.circle.fill",
                    bio: "",
                    location: User.Profile.Location(
                        latitude: 0,
                        longitude: 0,
                        address: ""
                    ),
                    joinDate: Date(),
                    social: User.Profile.Social.empty
                ),
                vehicles: [],
                friends: [],
                isPremium: false,
                achievements: [],
                preferences: User.Preferences.defaultPreferences
            )
            
            try await supabase
                .from("users")
                .insert(newUser)
                .execute()
            
            return "Successfully created test user record with ID: \(userId)"
        } catch {
            return "Failed to create test user record: \(error.localizedDescription)"
        }
    }
    
    // Function to check if a specific user exists in the database
    func checkUserExists(userId: String) async -> String {
        do {
            print("Checking if user exists with ID: \(userId)")
            
            let query = try await supabase
                .from("users")
                .select("id, email")
                .eq("id", value: userId)
                .execute()
            
            let data = query.data
            if let jsonData = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], !jsonData.isEmpty {
                return "User found in database: \(jsonData)"
            } else {
                return "User NOT found in database with ID: \(userId)"
            }
        } catch {
            return "Error checking if user exists: \(error.localizedDescription)"
        }
    }
    
    // Function to check current authentication session
    func checkCurrentSession() async -> String {
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id
            let userCheck = await checkUserExists(userId: userId.uuidString)
            return "Current session exists for user ID: \(userId.uuidString)\n\(userCheck)"
        } catch {
            return "Error checking current session: \(error.localizedDescription)"
        }
    }
    
    // Function to execute SQL commands for diagnosis
    func executeSQLQuery(_ sql: String) async -> String {
        do {
            print("Executing SQL query: \(sql)")
            
            let response = try await supabase
                .rpc("exec_sql", params: ["sql_query": sql])
                .execute()
            
            let data = response.data
            if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return "SQL execution result: \(json)"
            } else {
                return "SQL executed but no results or invalid response format"
            }
        } catch {
            return "Error executing SQL: \(error.localizedDescription)"
        }
    }
    
    // Function to create the users table if it doesn't exist
    func createUsersTableIfNeeded() async -> String {
        let createTableSQL = """
        -- Drop existing table if it exists (be careful with this in production)
        DROP TABLE IF EXISTS public.users CASCADE;

        -- Create the users table
        CREATE TABLE public.users (
            id UUID PRIMARY KEY REFERENCES auth.users(id),
            email TEXT UNIQUE NOT NULL,
            profile JSONB NOT NULL DEFAULT '{}'::jsonb,
            vehicles JSONB NOT NULL DEFAULT '[]'::jsonb,
            friends JSONB NOT NULL DEFAULT '[]'::jsonb,
            "isPremium" BOOLEAN NOT NULL DEFAULT false,
            achievements JSONB NOT NULL DEFAULT '[]'::jsonb,
            preferences JSONB NOT NULL DEFAULT '{}'::jsonb,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
        );

        -- Create an index on the email column
        CREATE INDEX IF NOT EXISTS users_email_idx ON public.users(email);

        -- Enable Row Level Security
        ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

        -- Drop existing policies if they exist
        DROP POLICY IF EXISTS "Users can read own data" ON public.users;
        DROP POLICY IF EXISTS "Users can update own data" ON public.users;
        DROP POLICY IF EXISTS "Users can insert own data" ON public.users;

        -- Create policies
        CREATE POLICY "Users can read own data" ON public.users
            FOR SELECT USING (auth.uid() = id);

        CREATE POLICY "Users can update own data" ON public.users
            FOR UPDATE USING (auth.uid() = id);

        CREATE POLICY "Users can insert own data" ON public.users
            FOR INSERT WITH CHECK (auth.uid() = id);

        -- Grant necessary permissions
        GRANT ALL ON public.users TO authenticated;
        GRANT ALL ON public.users TO service_role;
        """
        
        return await executeSQLQuery(createTableSQL)
    }
    
    // Add this new diagnostic function
    func diagnoseDatabaseState() async -> String {
        do {
            var report = "Database Diagnosis:\n\n"
            
            // 1. Check auth.users table
            let authUsers = try await supabase
                .from("auth.users")
                .select("*")
                .execute()
            report += "Auth Users: \(authUsers.data.count) records found\n"
            
            // 2. Check public.users table
            let publicUsers = try await supabase
                .from("users")
                .select("*")
                .execute()
            report += "Public Users: \(publicUsers.data.count) records found\n"
            
            // 3. Check for duplicate emails
            let duplicateEmails = try await supabase
                .from("users")
                .select("email")
                .execute()
            
            if let emails = try? JSONSerialization.jsonObject(with: duplicateEmails.data) as? [[String: Any]] {
                let emailCounts = emails.reduce(into: [String: Int]()) { counts, user in
                    if let email = user["email"] as? String {
                        counts[email, default: 0] += 1
                    }
                }
                
                let duplicates = emailCounts.filter { $0.value > 1 }
                if !duplicates.isEmpty {
                    report += "\nDuplicate Emails Found:\n"
                    for (email, count) in duplicates {
                        report += "- \(email): \(count) records\n"
                    }
                }
            }
            
            // 4. Check table structure
            let structure = try await supabase
                .from("users")
                .select("id, email, profile")
                .limit(1)
                .execute()
            
            if let data = try? JSONSerialization.jsonObject(with: structure.data) as? [[String: Any]], !data.isEmpty {
                report += "\nTable Structure:\n"
                for (key, value) in data[0] {
                    report += "- \(key): \(type(of: value))\n"
                }
            }
            
            return report
        } catch {
            return "Diagnosis Error: \(error.localizedDescription)"
        }
    }
    
    func cleanupDuplicateUsers() async -> String {
        do {
            var report = "Cleanup Process:\n\n"
            
            // 1. Get all users
            let users = try await supabase
                .from("users")
                .select("*")
                .execute()
            
            guard let userData = try? JSONSerialization.jsonObject(with: users.data) as? [[String: Any]] else {
                return "Failed to parse user data"
            }
            
            // 2. Group users by email
            var emailGroups: [String: [[String: Any]]] = [:]
            for user in userData {
                if let email = user["email"] as? String {
                    emailGroups[email, default: []].append(user)
                }
            }
            
            // 3. Process each group
            for (email, group) in emailGroups where group.count > 1 {
                report += "Processing email: \(email)\n"
                report += "Found \(group.count) records\n"
                
                // Sort by created_at to keep the oldest record
                let sortedGroup = group.sorted { 
                    let date1 = ($0["created_at"] as? String) ?? ""
                    let date2 = ($1["created_at"] as? String) ?? ""
                    return date1 < date2
                }
                
                // Keep the first record, delete others
                for (index, user) in sortedGroup.enumerated() {
                    if index == 0 {
                        report += "Keeping record with ID: \(user["id"] as? String ?? "unknown")\n"
                    } else {
                        if let id = user["id"] as? String {
                            try await supabase
                                .from("users")
                                .delete()
                                .eq("id", value: id)
                                .execute()
                            report += "Deleted duplicate record with ID: \(id)\n"
                        }
                    }
                }
            }
            
            return report
        } catch {
            return "Cleanup Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension AuthManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                print("Location access granted")
                manager.startUpdatingLocation()
            case .denied, .restricted:
                print("Location access denied")
            case .notDetermined:
                print("Location access not determined")
            @unknown default:
                print("Unknown location authorization status")
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            do {
                if var user = currentUser {
                    user.profile.location = User.Profile.Location(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        address: "" // We'll update this with reverse geocoding if needed
                    )
                    try await supabase
                        .from("users")
                        .update(user)
                        .eq("id", value: user.id)
                        .execute()
                    await MainActor.run {
                        self.currentUser = user
                    }
                }
            } catch {
                print("Failed to update user location: \(error)")
            }
        }
    }
} 
