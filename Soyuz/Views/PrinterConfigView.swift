//
//  PrinterConfigView.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/8/23.
//

import SwiftUI
import Network

// MARK: PrinterConfigView
struct PrinterConfigView: View {
    @ObservedObject var printerManager: MoonrakerSocketManager
    @ObservedObject var bonjourBrowser = BonjourBrowser()
    
    var body: some View {
        VStack {
            if(printerManager.isConnected) {
                HStack {
                    Image(systemName: "network")
                    Text(printerManager.connection?.endpoint.toFriendlyString() ?? "Unknown Host")
                    Text("\(printerManager.socketHost):\(printerManager.socketPort)")
                    Button {
                        printerManager.disconnect()
                    } label: {
                        Text("Disconnect")
                    }
                }
                .frame(width: 500, height: 80)
            } else {
                VStack {
                    Text("Auto-detected Printers")
                        .font(.title)
                    ForEach(bonjourBrowser.NDEngineResults , id: \.hashValue) { result in
                        HStack {
                            Text(result.endpoint.toFriendlyString())
                            Button {
                                printerManager.connectToBonjourEndpoint(result.endpoint)
                            } label: {
                                Text("Connect")
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                    }
                }
                .frame(width: 500, height: 100)
            }
        }
        .onAppear {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}

struct PrinterConfigView_Previews: PreviewProvider {
    @State static var printerManager = MoonrakerSocketManager()
    
    static var previews: some View {
        PrinterConfigView(printerManager: printerManager)
    }
}

extension NWEndpoint {
    func toFriendlyString() -> String {
        let regex = /\.(.+)/
        let match = self.debugDescription.firstMatch(of: regex)
        return self.debugDescription.replacingOccurrences(of: match!.0, with: "")
    }
}

