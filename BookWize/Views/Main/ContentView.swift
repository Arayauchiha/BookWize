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
                LibrarianDashboardScreen()
            } else if isMemberLoggedIn {
                // Replace with your MemberDashboardView
                VStack {
                    Text("Member Dashboard")
                        .font(.largeTitle)
                        .padding(.bottom, 30)
                    
                    Text("Coming Soon")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding(.bottom, 50)
                    
                    // Logout Button
                    Button(action: {
                        isMemberLoggedIn = false
                    }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: 200)
                            .background(Color.customButton)
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.customBackground)
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
                                    MemberLoginView()
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
                                    AdminLoginView()
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
