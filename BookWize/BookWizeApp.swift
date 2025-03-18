//
//  BookWizeApp.swift
//  BookWize
//
//  Created by Aryan Singh on 17/03/25.
//

import SwiftUI

@main
struct BookWizeApp: App {
    let persistenceController: PersistenceController = .shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
