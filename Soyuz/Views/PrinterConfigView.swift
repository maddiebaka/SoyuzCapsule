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
    
    //@State var bonjourBrowser = NWBrowser(for: .bonjourWithTXTRecord(type: "_moonraker._tcp", domain: "local."),                                       using: .tcp)
    
    @Environment(\.openURL) private var openURL
    
    
    var body: some View {
        VStack {
            if(printerManager.isConnected) {
                VStack {
                    Text("Soyuz Capsule is running in your menubar")
                        .font(.title)
                        .padding(4)
                    Image("menubar")
                        .resizable()
                        .frame(width: 225, height: 100)
                        .padding([.top], 2)
                        .padding([.leading, .trailing, .bottom], 8)
                    HStack {
                        Image(systemName: "network")
                        Text(printerManager.friendlyHostname)
                        Text("\(printerManager.socketHost):\(printerManager.socketPort)")
                        Button {
                            printerManager.disconnect()
                        } label: {
                            Text("Disconnect")
                        }
                    }
                }
                .frame(width: 500, height: 200)
            } else {
                VStack {
                    HStack {
                        Text("Auto-detected Printers")
                            .font(.title)
                        // Help button
                        Button {
                            let locBookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? String
                            NSHelpManager.shared.openHelpAnchor("bonjour", inBook: locBookName)
                        } label: {
                            ZStack {
                                Circle()
                                    .strokeBorder(Color(NSColor.controlShadowColor), lineWidth: 0.5)
                                    .background(Circle().foregroundColor(Color(NSColor.controlColor)))
                                    .shadow(color: Color(NSColor.controlShadowColor).opacity(0.3), radius: 1)
                                    .frame(width: 20, height: 20)
                                Text("?").font(.system(size: 15, weight: .medium ))
                            }
                        }.buttonStyle(PlainButtonStyle())

                    }
                    ForEach(bonjourBrowser.networkResults, id: \.hashValue) { result in
                        HStack {
                            Text(result.endpoint.toFriendlyString())
                            Button {
                                printerManager.connectToBonjourEndpoint(result.endpoint)
                            } label: {
                                Text("Connect")
                                    //.foregroundColor(.white)
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
            bonjourBrowser.enableScan(DispatchQueue.main)
        }
        .onDisappear {
            bonjourBrowser.disableScan()
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

