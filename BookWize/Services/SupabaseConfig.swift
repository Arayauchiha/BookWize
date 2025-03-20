import Foundation
import Supabase

enum SupabaseConfig {
    // Replace these with your actual Supabase project details
    private static let supabaseURLString = "https://qjhfnprghpszprfhjzdl.supabase.co"
    private static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqaGZucHJnaHBzenByZmhqemRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzNzE5NTAsImV4cCI6MjA1Nzk0Nzk1MH0.Bny2_LBt2fFjohwmzwCclnFNmrC_LZl3s3PVx-SOeNc"
    
    static let shared: SupabaseClient = {
        guard let supabaseURL = URL(string: supabaseURLString) else {
            fatalError("Invalid Supabase URL")
        }
        
        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
    }()
} 
