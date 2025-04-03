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
            
            let response: [User] = try await SupabaseManager.shared.client
                .from("Members")
                .select("*")
                .eq("email", value: userEmail)
                .execute()
                .value
            
            DispatchQueue.main.async {
                if let fetchedUser = response.first {
                    self.user = fetchedUser
                    print("✅ Successfully fetched user: \(fetchedUser.name)")
                } else {
                    print("❌ No user found with email: \(userEmail)")
                }
            }
        } catch {
            print("❌ Error fetching member: \(error)")
        }
    }
    
    private func handleLogout() {
        // Clear stored user data
        UserDefaults.standard.removeObject(forKey: "currentMemberId")
        UserDefaults.standard.removeObject(forKey: "currentMemberEmail")
        
        // Update UI
        isMemberLoggedIn = false
        NavigationUtil.popToRootView()
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        window?.rootViewController = UIHostingController(rootView: ContentView())
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "rectangle.3.group")
                }
                .tag(0)
            
            // Explore Tab (Default)
            SearchBrowseView(
                userPreferredGenres: userPreferredGenres,
                supabase: supabase
            )
            .tabItem {
                Label("Explore", systemImage: "safari")
            }
            .tag(1)
            
            // Wishlist Tab - Updated to use our new WishlistView
            WishlistView()
                .tabItem {
                    Label("Wishlist", systemImage: "heart")
                }
                .tag(2)
            
            // Account Tab - Modified to include Membership Details
            NavigationView {
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
                            // Show confirmation alert
                            let alertController = UIAlertController(
                                title: "Logout",
                                message: "Are you sure you want to logout?",
                                preferredStyle: .alert
                            )
                            
                            alertController.addAction(UIAlertAction(
                                title: "Cancel",
                                style: .cancel
                            ))
                            
                            alertController.addAction(UIAlertAction(
                                title: "Logout",
                                style: .destructive,
                                handler: { _ in handleLogout() }
                            ))
                            
                            // Present the alert
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                rootViewController.present(alertController, animated: true)
                            }
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Account")
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
                    Task {
                        await fetchMember()
                    }
                }
            }
            .tabItem {
                Label("Account", systemImage: "person.circle")
            }
            .tag(3)
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
    }
}
