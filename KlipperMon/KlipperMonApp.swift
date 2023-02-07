//
//  KlipperMonApp.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/7/23.
//

import SwiftUI

@main
struct KlipperMonApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
