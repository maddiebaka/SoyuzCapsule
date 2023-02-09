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
        WindowGroup(id: "floating-stats") {
            KlipperMonMenuBarExtraView(currentMenuBarIcon: $currentIcon)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                //.frame(width: 300, height: 140)
        }
        //.windowResizability(.contentSize)
        
        Window("Configuration", id: "soyuz_cfg", content: {
            PrinterConfigView()
        })
        
        MenuBarExtra("Soyuz", systemImage: currentIcon) {
            KlipperMonMenuBarExtraView(currentMenuBarIcon: $currentIcon)
                .padding([.top, .leading, .trailing], 8)
                .padding([.bottom], 6)
        }
        .menuBarExtraStyle(.window)
    }
}
