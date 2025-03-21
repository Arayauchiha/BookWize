//
//  ContentView.swift
//  BookWize
//
//  Created by Aryan Singh on 17/03/25.
//

import SwiftUI
import CoreData
import Supabase

struct ContentView: View {
    @AppStorage("isAdminLoggedIn") private var isAdminLoggedIn = false
    @AppStorage("isLibrarianLoggedIn") private var isLibrarianLoggedIn = false
    @AppStorage("isMemberLoggedIn") private var isMemberLoggedIn = false
    
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://qjhfnprghpszprfhjzdl.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqaGZucHJnaHBzenByZmhqemRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzNzE5NTAsImV4cCI6MjA1Nzk0Nzk1MH0.Bny2_LBt2fFjohwmzwCclnFNmrC_LZl3s3PVx-SOeNc"
    )
    
    var body: some View {
        Group {
            if isAdminLoggedIn {
                AdminDashboardView(supabase: supabase)
            } else if isLibrarianLoggedIn {
                LibrarianDashboardScreen()
            } else if isMemberLoggedIn {
                Search_BrowseApp()
            } else {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 25) {
                            Text("Select your role")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .padding(.top, 50)
                            
                            // Admin Login Button
                            NavigationLink(destination: LoginView(supabase: supabase, userRole: .admin)) {
                                RoleSelectionButton(
                                    title: "Admin",
                                    subtitle: "Library Management",
                                    systemImage: "person.badge.key.fill",
                                    color: .adminColor
                                )
                            }
                            
                            // Librarian Login Button
                            NavigationLink(destination: LoginView(supabase: supabase, userRole: .librarian)) {
                                RoleSelectionButton(
                                    title: "Librarian",
                                    subtitle: "Book Management",
                                    systemImage: "books.vertical.fill",
                                    color: .librarianColor
                                )
                            }
                            
                            // Member Login Button
                            NavigationLink(destination: LoginView(supabase: supabase, userRole: .member)) {
                                RoleSelectionButton(
                                    title: "Member",
                                    subtitle: "Browse & Borrow",
                                    systemImage: "person.fill",
                                    color: .memberColor
                                )
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemBackground))
                }
            }
        }
    }
}

struct RoleSelectionButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 50)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(color)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

//extension Color {
//    static let adminColor = Color("AdminColor", bundle: nil)
//    static let librarianColor = Color("LibrarianColor", bundle: nil)
//    static let memberColor = Color("MemberColor", bundle: nil)
//}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
