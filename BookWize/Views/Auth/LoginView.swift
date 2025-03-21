//
//  LoginView.swift
//  BookWize
//
//  Created by Aditya Singh on 18/03/25.
//

import SwiftUI
import Supabase

struct LoginView: View {
    @StateObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    
    let userRole: UserRole
    let supabase: SupabaseClient
    
    init(supabase: SupabaseClient, userRole: UserRole) {
        self.supabase = supabase
        self.userRole = userRole
        _authService = StateObject(wrappedValue: AuthService(supabase: supabase))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("\(roleTitle) Login")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(roleColor)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: {
                Task {
                    await login()
                }
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(roleColor)
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            
            if let error = authService.authError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if userRole == .member {
                HStack {
                    NavigationLink("Create Account") {
                        SignUpView(supabase: supabase)
                    }
                    .foregroundColor(roleColor)
                    
                    Spacer()
                    
                    Button("Forgot Password?") {
                        // Handle forgot password
                    }
                    .foregroundColor(roleColor)
                }
            }
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authService.authError ?? "An unknown error occurred")
        }
    }
    
    private var roleTitle: String {
        switch userRole {
        case .admin:
            return "Admin"
        case .librarian:
            return "Librarian"
        case .member:
            return "Member"
        }
    }
    
    private var roleColor: Color {
        switch userRole {
        case .admin:
            return .adminColor
        case .librarian:
            return .librarianColor
        case .member:
            return .memberColor
        }
    }
    
    private func login() async {
        isLoading = true
        do {
            try await authService.login(email: email, password: password, role: userRole)
            
            // Set the appropriate login state based on role
            switch userRole {
            case .admin:
                UserDefaults.standard.set(true, forKey: "isAdminLoggedIn")
            case .librarian:
                UserDefaults.standard.set(true, forKey: "isLibrarianLoggedIn")
            case .member:
                UserDefaults.standard.set(true, forKey: "isMemberLoggedIn")
            }
            
            isLoading = false
        } catch {
            isLoading = false
            showError = true
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoginView(
                supabase: SupabaseClient(
                    supabaseURL: URL(string: "https://example.com")!,
                    supabaseKey: ""
                ),
                userRole: .member
            )
        }
    }
}
