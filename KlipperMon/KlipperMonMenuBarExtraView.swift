//
//  KlipperMonMenuBarExtraView.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/7/23.
//

import SwiftUI
import AppKit
import Network

struct KlipperMenuBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .foregroundColor(.white)
    }
}

struct KlipperMonMenuBarExtraView: View {
    let DANGERTEMP = 40.0
    
    @Environment(\.openWindow) var openWindow
    
    @ObservedObject var printerManager = PrinterRequestManager.shared
    
    @State var printerObjectsQuery: PrinterObjectsQuery?
    @State var printPercentage: Double = 0
    
    // TODO: Don't forget, create @State variable for printer status (i.e. "Printing", etc)
    // and programmatically add a "connecting" section
    @State var printerStatus: String = ""
    
    @Binding var currentMenuBarIcon: String
    
    @State var hotendHotTemp: Bool = false
    @State var bedHotTemp: Bool = false
    
    @State var nwBrowserDiscoveredItems: [NWEndpoint] = []
    
    var nwBrowser = NWBrowser(for: .bonjour(type: "_moonraker._tcp.", domain: "local."), using: .tcp)
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // TODO: Use @published API data instead of instance state variable
    var body: some View {
        VStack {
            // Printer Readouts
            if let queryResults = printerManager.printerObjectsQuery {
                Text(queryResults.result.status.print_stats.state.capitalized)
                    .font(.title)
                    .padding(4)
                // Print information
                HStack {
                    Image(systemName: "pencil.tip")
                        .rotationEffect(Angle(degrees: 180))
                        .offset(x: 5.5, y: 4)
                        .font(.system(size: 24))
                    ProgressView(value: queryResults.result.status.virtual_sdcard.progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .offset(x: 10)
                    Text("\(Int(queryResults.result.status.virtual_sdcard.progress * 100))%")
                        .padding(2)
                        .padding([.leading], 8)
                }
                // Temperatures
                HStack {
                    // Hot-end temperature
                    HStack {
                        Image(systemName: "flame")
                            .foregroundColor( hotendHotTemp ? .red : .white )
                            .opacity( hotendHotTemp ? 1.0 : 0.3 )
                        Text("Hotend")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(queryResults.result.status.extruder.temperature))°C")
                    }
                    // Bed temperature
                    HStack {
                        Image(systemName: "flame")
                            .foregroundColor( bedHotTemp ? .red : .white )
                            .opacity( bedHotTemp ? 1.0 : 0.3 )
                        Text("Plate")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(queryResults.result.status.heater_bed.temperature))°C")
                    }
                }
                Divider()
            }
        }
        .frame(minWidth: 220, minHeight: 100)
        //        .overlay {
        //            if !printerManager.printerCommsOkay {
        //                RoundedRectangle(cornerRadius: 10, style: .circular)
        //                    .foregroundColor(.black)
        //                    .frame(minWidth: 300, minHeight: 100)
        //                    .opacity(0.6)
        //            }
        //        }
        // Footer information
        HStack {
            Button {
                print("Button pressed")
                openWindow(id: "soyuz_cfg")
            } label: {
                Text("Server Config")
                    .foregroundColor(.white)
            }
            Spacer()
            if(printerManager.printerCommsOkay) {
                Image(systemName: "network")
                Text("Online")
            } else {
                Image(systemName: "xmark")
                Text("Offline")
            }
        }
        .padding(4)
        .frame(minWidth: 220, maxWidth: 250)
        .onReceive(timer) { input in
            Task {
                await printerManager.queryPrinterStats()
                
                if let query = printerManager.printerObjectsQuery {
                    hotendHotTemp = (query.result.status.extruder.temperature > DANGERTEMP) ? true : false
                    bedHotTemp = (query.result.status.heater_bed.temperature > DANGERTEMP) ? true : false
                    printerStatus = query.result.status.print_stats.state.capitalized
                } else {
                    printerStatus = "Connecting..."
                }
            }
        }
        // Testing bonjour stuff
        .onAppear {
            nwBrowser.browseResultsChangedHandler = { (newResults, changes) in
                print("[update] Results changed.")
                newResults.forEach { result in
                    print(result)
                    self.nwBrowserDiscoveredItems.append(result.endpoint)
                }
                //self.nwBrowserDiscoveredItems.append(newResults.description)
            }
            nwBrowser.stateUpdateHandler = { newState in
                switch newState {
                case .failed(let error):
                    print("[error] nwbrowser: \(error)")
                case .ready:
                    print("[ready] nwbrowser")
                case .setup:
                    print("[setup] nwbrowser")
                default:
                    break
                }
            }
            nwBrowser.start(queue: DispatchQueue.main)
        }
        ForEach(nwBrowserDiscoveredItems, id: \.hashValue) { item in
            Button {
                let connection = NWConnection(to: item, using: .tcp)
                connection.stateUpdateHandler = { newState in
                    switch newState {
                    case .failed(let error):
                        print("[error] nwconnection: \(error)")
                    case .ready:
                        print("[ready] nwconnection")
                    default:
                        break
                    }
                }
                connection.start(queue: DispatchQueue.main)
            } label: {
                Text(item.debugDescription)
            }
        }
    }
}

struct KlipperMonMenuBarExtraView_Previews: PreviewProvider {
    @State static var currentMenuBarIcon = "move.3d"
    static var previews: some View {
        KlipperMonMenuBarExtraView(currentMenuBarIcon: $currentMenuBarIcon)
    }
}

