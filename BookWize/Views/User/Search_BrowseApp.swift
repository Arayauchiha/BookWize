//
//  Search_BrowseApp.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import SwiftUI

struct Search_BrowseApp: View {
    @State private var selectedTab = 1  // Start on search tab (index 1)
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
            
            // Search Tab (Default)
            SearchBrowseView(userPreferredGenres: userPreferredGenres)
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
            
            // Book Club Tab
            NavigationView {
                Text("Book Club Coming Soon")
                    .navigationTitle("Book Club")
            }
            .tabItem {
                Label("Book Club", systemImage: "person.3.fill")
            }
            .tag(3)
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
