import Foundation
import Supabase

enum SupabaseConfig {
    static let supabaseURL = "https://ubvxaqceclhgflosgvai.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVidnhhcWNlY2xoZ2Zsb3NndmFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDEwNDY5NDIsImV4cCI6MjA1NjYyMjk0Mn0.qRK2OsTAcMY7WfznhOIAonFqHTj5CLyKuASwqGqOllU"
    
    static let client: SupabaseClient = {
        SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseAnonKey
        )
    }()
} 