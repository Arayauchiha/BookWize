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

    var body: some View {
        NavigationView {
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
                            Text("Member View")
                        } label: {
                            RoleCard(
                                title: "Member",
                                icon: "person.fill",
                                iconColor: Color.memberColor,
                                cardColor: Color.customCardBackground
                            )
                        }

                        NavigationLink {
                            Text("Librarian View")
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

#Preview {
    ContentView()
        .environment(\.colorScheme, .light)
}
