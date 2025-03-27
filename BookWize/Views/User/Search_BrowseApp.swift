//
//  Search_BrowseApp.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import SwiftUI

struct Search_BrowseApp: View {
    @State private var selectedTab = 1  // Start on explore tab (index 1)
    @AppStorage("isMemberLoggedIn") private var isMemberLoggedIn = false
    let userPreferredGenres: [String]
    
    init(userPreferredGenres: [String] = []) {
        self.userPreferredGenres = userPreferredGenres
    }
        
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            NavigationView {
                Text("Dashboard Coming Soon")
                    .navigationTitle("Dashboard")
            }
            .tabItem {
                Label("Dashboard", systemImage: "rectangle.3.group")
            }
            .tag(0)
            
            // Explore Tab (Default)
            SearchBrowseView(userPreferredGenres: userPreferredGenres)
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
            
            // Book Club Tab
            NavigationView {
                Text("Book Club Coming Soon")
                    .navigationTitle("Book Club")
            }
            .tabItem {
                Label("Book Club", systemImage: "person.3.fill")
            }
            .tag(3)
            
            // Account Tab
            NavigationView {
                List {
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Member")
                                    .font(.headline)
                                Text("member@example.com")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            // Clear stored user data
                            UserDefaults.standard.removeObject(forKey: "currentMemberId")
                            UserDefaults.standard.removeObject(forKey: "currentMemberEmail")
                            
                            // Update UI
                            isMemberLoggedIn = false
                            NavigationUtil.popToRootView()
                            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                            let window = windowScene?.windows.first
                            window?.rootViewController = UIHostingController(rootView: ContentView())
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
            }
            .tabItem {
                Label("Account", systemImage: "person.circle")
            }
            .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            // Set the tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
            UITabBar.appearance().standardAppearance = appearance
        }
    }
}
