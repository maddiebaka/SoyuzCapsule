//
//  KlipperMonMenuBarExtraView.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/7/23.
//

import SwiftUI
import AppKit
import Network

struct SoyuzMenuBarExtraView: View {
    // The threshhold considered a burn-risk, at which point certain UI elements turn red.
    let DANGERTEMP = 40.0
    
    @Environment(\.openWindow) var openWindow
    
    @ObservedObject var printerManager = PrinterRequestManager.shared
    
    @State var printPercentage: Double = 0
    
    @Binding var currentMenuBarIcon: String
    
    @State var hotendHotTemp: Bool = false
    @State var bedHotTemp: Bool = false
    
    // TODO: Use @published API data instead of instance state variable
    var body: some View {
        VStack {
            // Printer Readouts
            //if let printerStats = printerManager.printerStats {
            if(printerManager.isConnected) {
                VStack {
                    Text(printerManager.state.capitalized)
                        .font(.title)
                        .padding(4)
                    // Print information
                    HStack {
                        Image(systemName: "pencil.tip")
                            .rotationEffect(Angle(degrees: 180))
                            .offset(x: 5.5, y: 4)
                            .font(.system(size: 24))
                        ProgressView(value: printerManager.progress, total: 1.0)
                            .progressViewStyle(.linear)
                            .offset(x: 10)
                        Text("\(Int(printerManager.progress * 100))%")
                            .padding(2)
                            .padding([.leading], 8)
                    }
                    // Temperatures
                    HStack {
                        // Hot-end temperature
                        HStack {
                            Image(systemName: "flame")
                                .foregroundColor( printerManager.extruderTemperature > DANGERTEMP ? .red : .white )
                                .opacity( printerManager.extruderTemperature > DANGERTEMP ? 1.0 : 0.3 )
                            Text("Hotend")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(printerManager.extruderTemperature))°C")
                        }
                        // Bed temperature
                        HStack {
                            Image(systemName: "flame")
                                .foregroundColor( printerManager.bedTemperature > DANGERTEMP ? .red : .white )
                                .opacity( printerManager.bedTemperature > DANGERTEMP ? 1.0 : 0.3 )
                            Text("Plate")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(printerManager.bedTemperature))°C")
                        }
                    }
                    Divider()
                }
            }
        }
        //.frame(minWidth: 220, minHeight: 100)
        // Footer information
        HStack {
            Button {
                print("Button pressed")
                openWindow(id: "soyuz_cfg")
            } label: {
                Text("Printers")
                    .foregroundColor(.white)
            }
            Spacer()
            if(printerManager.isConnected) {
                Image(systemName: "network")
                Text("Online")
            } else {
                Image(systemName: "exclamationmark.triangle")
                Text("Offline")
            }
        }
        .padding(2)
        .frame(minWidth: 220, maxWidth: 375)
    }
}

struct KlipperMonMenuBarExtraView_Previews: PreviewProvider {
    @State static var currentMenuBarIcon = "move.3d"
    static var previews: some View {
        SoyuzMenuBarExtraView(currentMenuBarIcon: $currentMenuBarIcon)
    }
}

