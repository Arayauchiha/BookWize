import Supabase
import Foundation

enum SupabaseConfig {
    static let supabaseURL = "https://qjhfnprghpszprfhjzdl.supabase.co"
    static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqaGZucHJnaHBzenByZmhqemRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzNzE5NTAsImV4cCI6MjA1Nzk0Nzk1MH0.Bny2_LBt2fFjohwmzwCclnFNmrC_LZl3s3PVx-SOeNc"
    
    static var client: SupabaseClient {
        SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
    }
} 
