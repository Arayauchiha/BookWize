//  Search_BrowseApp.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import Supabase
import SwiftUI
import Foundation
import Combine

struct MembershipDetailsView: View {
    let user: User
    @State private var qrCodeImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack {
                if let qrCodeImage = qrCodeImage {
                    DigitalLibraryCard(
                        userName: user.name,
                        userEmail: user.email,
                        libraryName: user.selectedLibrary,
                        qrCodeImage: qrCodeImage
                    )
                } else {
                    if isLoading {
                        ProgressView("Generating your library card...")
                    } else {
                        Button("Show My Library Card") {
                            generateQRCode()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Membership Details")
        .onAppear {
            // Generate QR code automatically when view appears
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        isLoading = true
        
        let userData = [
            "name": user.name,
            "email": user.email,
            "library": user.selectedLibrary,
            //"membershipType": "Annual",
            "memberId": user.id.uuidString
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: userData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let apiUrl = "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=\(jsonString)"
            if let url = URL(string: apiUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) {
                fetchQRCode(from: url)
            }
        }
    }
    
    private func fetchQRCode(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data, let image = UIImage(data: data) {
                    self.qrCodeImage = image
                }
            }
        }.resume()
    }
}

struct AccountSettingsView: View {
    @State private var isPasswordResetPresented = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isNewPasswordVisible = false
    let user: User
    
    var body: some View {
        List {
            Section {
                Button {
                    isPasswordResetPresented = true
                } label: {
                    Label("Change Password", systemImage: "lock")
                }
            }
        }
        .sheet(isPresented: $isPasswordResetPresented) {
            PasswordResetView(
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isNewPasswordVisible: $isNewPasswordVisible,
                email: user.email,
                title: "Change Password",
                message: "Please enter your new password below.",
                buttonTitle: "Update Password",
                onSave: {
                    isPasswordResetPresented = false
                },
                onCancel: {
                    isPasswordResetPresented = false
                }
            )
        }
    }
}

struct Search_BrowseApp: View {
    @State private var selectedTab = 0
    @AppStorage("isMemberLoggedIn") private var isMemberLoggedIn = false
    let userPreferredGenres: [String]
    @State private var user: User?
    private let supabase = SupabaseConfig.client
    
    @State private var isPasswordResetPresented = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isNewPasswordVisible = false
    @State private var showLogoutConfirmation = false
    @State private var showingProfileSheet = false
    
    init(userPreferredGenres: [String] = []) {
        self.userPreferredGenres = userPreferredGenres
    }
    
    private func fetchMember() async {
        do {
            guard let userEmail = UserDefaults.standard.string(forKey: "currentMemberEmail") else {
                print("⚠️ No email found in UserDefaults")
                return
            }
            
            print("📱 Fetching member with email: \(userEmail)")
            
            // Try up to 3 times to fetch the user data
            var attempts = 0
            var fetchedUser: User? = nil
            
            while fetchedUser == nil && attempts < 3 {
                attempts += 1
                
                do {
                    let response: [User] = try await SupabaseManager.shared.client
                        .from("Members")
                        .select("*")
                        .eq("email", value: userEmail)
                        .execute()
                        .value
                    
                    fetchedUser = response.first
                    
                    if fetchedUser != nil {
                        print("✅ Successfully fetched user on attempt \(attempts): \(fetchedUser!.name)")
                    } else {
                        print("⚠️ No user found with email on attempt \(attempts): \(userEmail)")
                        // Wait briefly before retrying
                        if attempts < 3 {
                            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        }
                    }
                } catch {
                    print("❌ Error fetching member on attempt \(attempts): \(error)")
                    // Wait briefly before retrying
                    if attempts < 3 {
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    }
                }
            }
            
            DispatchQueue.main.async {
                if let fetchedUser = fetchedUser {
                    self.user = fetchedUser
                } else {
                    print("❌ Failed to fetch user after all attempts")
                }
            }
        } catch {
            print("❌ Error in fetch member process: \(error)")
        }
    }
    
    private func handleLogout() {
        // Clear stored user data
        UserDefaults.standard.removeObject(forKey: "currentMemberId")
        UserDefaults.standard.removeObject(forKey: "currentMemberEmail")
        
        // Update UI
        isMemberLoggedIn = false
        
        // Reset user object
        self.user = nil
        
        // Ensure we're on the main thread for UI updates
        DispatchQueue.main.async {
            // Reset to root view
            NavigationUtil.popToRootView()
            
            // Navigate to the ContentView
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            
            // Use a transition animation for smoother experience
            UIView.transition(with: window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window?.rootViewController = UIHostingController(rootView: ContentView())
            }, completion: nil)
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            NavigationView {
                DashboardView()
                    .navigationTitle("Dashboard")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                Task {
                                    if user == nil {
                                        await fetchMember()
                                    }
                                    DispatchQueue.main.async {
                                        showingProfileSheet = true
                                    }
                                }
                            }) {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
            }
            .tabItem {
                Label("Dashboard", systemImage: "rectangle.3.group")
            }
            .tag(0)
            
            // Explore Tab
            NavigationView {
                SearchBrowseView(
                    userPreferredGenres: userPreferredGenres,
                    supabase: supabase
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            Task {
                                if user == nil {
                                    await fetchMember()
                                }
                                DispatchQueue.main.async {
                                    showingProfileSheet = true
                                }
                            }
                        }) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .tabItem {
                Label("Explore", systemImage: "safari")
            }
            .tag(1)
            
            // Wishlist Tab
            NavigationView {
                WishlistView()
                    .navigationTitle("My Wishlist")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                Task {
                                    if user == nil {
                                        await fetchMember()
                                    }
                                    DispatchQueue.main.async {
                                        showingProfileSheet = true
                                    }
                                }
                            }) {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
            }
            .tabItem {
                Label("Wishlist", systemImage: "heart")
            }
            .tag(2)
        }
        .accentColor(.blue)
        .onAppear {
            Task {
                await fetchMember()
            }
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
            UITabBar.appearance().standardAppearance = appearance
        }
        .sheet(isPresented: $showingProfileSheet) {
            NavigationView {
                ProfileView(
                    user: user,
                    isPasswordResetPresented: $isPasswordResetPresented,
                    newPassword: $newPassword,
                    confirmPassword: $confirmPassword,
                    isNewPasswordVisible: $isNewPasswordVisible,
                    handleLogout: handleLogout
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: showingProfileSheet) { newValue in
            if newValue && user == nil {
                Task {
                    await fetchMember()
                }
            }
        }
    }
}

// Profile View to be shown as a modal sheet
struct ProfileView: View {
    let user: User?
    @Binding var isPasswordResetPresented: Bool
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isNewPasswordVisible: Bool
    let handleLogout: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        if isLoading {
            VStack {
                ProgressView("Loading profile...")
                    .padding()
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        } else {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user?.name ?? "Member")
                                .font(.headline)
                            Text(user?.email ?? "member@example.com")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    if let user = user {
                        NavigationLink {
                            MembershipDetailsView(user: user)
                        } label: {
                            Label {
                                Text("Library Card")
                            } icon: {
                                Image(systemName: "creditcard.fill")
                                    .frame(width: 30, height: 30)
                            }
                        }
                        
                        Button {
                            print("🔐 Change password tapped for user:", user.email)
                            isPasswordResetPresented = true
                        } label: {
                            Label {
                                Text("Change Password")
                            } icon: {
                                Image(systemName: "lock")
                                    .frame(width: 30, height: 30)
                            }
                        }
                    }
                    
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .alert("Logout", isPresented: $showingLogoutAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Logout", role: .destructive) {
                            dismiss()
                            // Add a slight delay to ensure the sheet is dismissed before handling logout
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                handleLogout()
                            }
                        }
                    } message: {
                        Text("Are you sure you want to logout?")
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(isPresented: $isPasswordResetPresented) {
                if let user = user {
                    MemberPasswordResetView(
                        newPassword: $newPassword,
                        confirmPassword: $confirmPassword,
                        isNewPasswordVisible: $isNewPasswordVisible,
                        email: user.email,
                        title: "Change Password",
                        message: "Please enter your new password below.",
                        buttonTitle: "Update Password",
                        onSave: {
                            print("✅ Password update completed for user:", user.email)
                            isPasswordResetPresented = false
                        },
                        onCancel: {
                            print("❌ Password update cancelled for user:", user.email)
                            isPasswordResetPresented = false
                        }
                    )
                }
            }
            .onAppear {
                isLoading = user == nil
            }
        }
    }
}
