//
//  Search_BrowseApp.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import SwiftUI
struct Search_BrowseApp: App {
    @State private var selectedTab = 1  // Start on search tab (index 1)
        
        var body: some Scene {
            WindowGroup {
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
                    
                    // Search Tab (Default)
                    SearchBrowseView()
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .tag(1)
                    
                    // Wishlist Tab
                    NavigationView {
                        Text("Wishlist Coming Soon")
                            .navigationTitle("Wishlist")
                    }
                    .tabItem {
                        Label("Wishlist", systemImage: "heart")
                    }
                    .tag(2)
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
}
