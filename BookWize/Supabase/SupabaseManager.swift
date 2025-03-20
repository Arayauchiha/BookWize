//
//  SupabaseManager.swift
//  BookWize
//
//  Created by Aditya Singh on 20/03/25.
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://qjhfnprghpszprfhjzdl.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqaGZucHJnaHBzenByZmhqemRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzNzE5NTAsImV4cCI6MjA1Nzk0Nzk1MH0.Bny2_LBt2fFjohwmzwCclnFNmrC_LZl3s3PVx-SOeNc"
        )
    }
}

