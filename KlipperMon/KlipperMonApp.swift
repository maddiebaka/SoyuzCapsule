//
//  KlipperMonApp.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/7/23.
//

import SwiftUI


@main
struct KlipperMonMenuBarApp: App {
    let persistenceController = PersistenceController.shared
    
    @State var currentIcon = "move.3d"
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        
        MenuBarExtra("Soyuz", systemImage: currentIcon) {
            KlipperMonMenuBarExtraView(currentMenuBarIcon: $currentIcon)
        }
        .menuBarExtraStyle(.window)
    }
}

protocol MenuBarExtraIconUpdater {
    func updateIcon(systemName: String)
}

struct KlipperMonApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
