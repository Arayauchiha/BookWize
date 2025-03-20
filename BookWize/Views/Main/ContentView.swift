//
//  ContentView.swift
//  BookWize
//
//  Created by Aryan Singh on 17/03/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("isAdminLoggedIn") private var isAdminLoggedIn = false
    @AppStorage("isLibrarianLoggedIn") private var isLibrarianLoggedIn = false
    @AppStorage("isMemberLoggedIn") private var isMemberLoggedIn = false

    var body: some View {
        Group {
            if isAdminLoggedIn {
                AdminDashboardView()
            } else if isLibrarianLoggedIn {
                // Replace with your LibrarianDashboardView
                Text("Librarian Dashboard")
                    .font(.largeTitle)
                    .onTapGesture {
                        // For testing: allow logout
                        isLibrarianLoggedIn = false
                    }
            } else if isMemberLoggedIn {
                // Replace with your MemberDashboardView
                Text("Member Dashboard")
                    .font(.largeTitle)
                    .onTapGesture {
                        // For testing: allow logout
                        isMemberLoggedIn = false
                    }
            } else {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 25) {
                            // Welcome message with adjusted alignment
                            Text("Select your role")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(Color.customText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.top, 50)

                            // Role selection cards with appropriate colors
                            VStack(spacing: 16) {
                                NavigationLink {
                                    LoginView(userRole: .member)
                                } label: {
                                    RoleCard(
                                        title: "Member",
                                        icon: "person.fill",
                                        iconColor: Color.memberColor,
                                        cardColor: Color.customCardBackground
                                    )
                                }

                                NavigationLink {
                                    LoginView(userRole: .librarian)
                                } label: {
                                    RoleCard(
                                        title: "Librarian",
                                        icon: "books.vertical.fill",
                                        iconColor: Color.librarianColor,
                                        cardColor: Color.customCardBackground
                                    )
                                }

                                NavigationLink {
                                    LoginView(userRole: .admin)
                                } label: {
                                    RoleCard(
                                        title: "Admin",
                                        icon: "gear",
                                        iconColor: Color.adminColor,
                                        cardColor: Color.customCardBackground
                                    )
                                }
                            }
                            .padding(.horizontal, 20)

                            Spacer(minLength: 50)
                        }
                    }
                    .navigationBarHidden(true)
                    .background(Color.customBackground)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.colorScheme, .light)
}
