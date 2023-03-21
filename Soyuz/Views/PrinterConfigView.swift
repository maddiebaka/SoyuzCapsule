//
//  PrinterConfigView.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/8/23.
//

import SwiftUI
import Network

struct PrinterConfigView: View {
    @ObservedObject var printerManager: PrinterRequestManager
    
    var body: some View {
        VStack {
            if(printerManager.isConnected) {
                HStack {
                    Image(systemName: "network")
                    Text(printerManager.connection.endpoint.toFriendlyString())
                    Text("\(printerManager.socketHost):\(printerManager.socketPort)")
                    Button {
                        printerManager.socket?.disconnect()
                    } label: {
                        Text("Disconnect")
                    }
                }
                .frame(width: 500, height: 80)
            } else {
                VStack {
                    Text("Auto-detected Printers")
                        .font(.title)
                    ForEach(printerManager.nwBrowserDiscoveredItems, id: \.hashValue) { result in
                        HStack {
                            Text(result.endpoint.toFriendlyString())
                            Button {
                                printerManager.resolveBonjourHost(result.endpoint)
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
    @State static var printerManager = PrinterRequestManager()
    
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

