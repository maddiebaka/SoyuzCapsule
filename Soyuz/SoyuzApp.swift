/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import SwiftUI

@main
struct SoyuzApp: App {
    let persistenceController = PersistenceController.shared
    
    @State var currentIcon = "move.3d"
    
    @ObservedObject static var printerManager = MoonrakerSocketManager()
    
    var body: some Scene {
        WindowGroup("Configuration", id: "soyuz_cfg", content: {
            PrinterConfigView(printerManager: SoyuzApp.printerManager)
                //.frame(minWidth: 300, maxWidth: 600, minHeight: 60, maxHeight: 100)
        })
        .windowResizability(.contentSize)
        
        MenuBarExtra("Soyuz", systemImage: currentIcon) {
            SoyuzMenuBarExtraView(printerManager: SoyuzApp.printerManager, currentMenuBarIcon: $currentIcon)
                .padding([.top, .leading, .trailing], 8)
                .padding([.bottom], 6)
        }
        .menuBarExtraStyle(.window)
    }
}
