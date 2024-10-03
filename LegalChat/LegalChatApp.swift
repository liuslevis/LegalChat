//
//  LegalChatApp.swift
//  LegalChat
//
//  Created by david on 2023/5/30.
//

import SwiftUI

@main
struct LegalChatApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
