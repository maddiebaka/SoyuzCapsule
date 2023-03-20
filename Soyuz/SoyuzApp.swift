//
//  KlipperMonApp.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/7/23.
//

import SwiftUI

@main
struct SoyuzApp: App {
    let persistenceController = PersistenceController.shared
    
    @State var currentIcon = "move.3d"
    
    @ObservedObject var printerManager = PrinterRequestManager()
    
    var body: some Scene {
//        WindowGroup(id: "floating-stats") {
//            KlipperMonMenuBarExtraView(currentMenuBarIcon: $currentIcon)
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
//        }
        
        WindowGroup("Configuration", id: "soyuz_cfg", content: {
            PrinterConfigView(printerManager: printerManager)
                //.frame(minWidth: 300, maxWidth: 600, minHeight: 60, maxHeight: 100)
        })
        .windowResizability(.contentSize)
        
        MenuBarExtra("Soyuz", systemImage: currentIcon) {
            SoyuzMenuBarExtraView(printerManager: printerManager, currentMenuBarIcon: $currentIcon)
                .padding([.top, .leading, .trailing], 8)
                .padding([.bottom], 6)
        }
        .menuBarExtraStyle(.window)
    }
}
