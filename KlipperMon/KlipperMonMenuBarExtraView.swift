//
//  KlipperMonMenuBarExtraView.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/7/23.
//

import SwiftUI

struct KlipperMonMenuBarExtraView: View {
    @State var printPercentage: Double = 0
    @Binding var currentMenuBarIcon: String
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Label(String(printPercentage), systemImage: "thermometer.snowflake.circle")
            .onReceive(timer) { input in
                Task {
                    self.printPercentage = await self.getPrintPercentage()
                }
            }
        
        Button("Check Printer") {
            currentMenuBarIcon = "flame"
        }
    }
    
    func getPrintPercentage() async -> Double {
        guard let url = URL(string: "http://10.0.21.39/printer/objects/query?extruder=temperature") else {
            fatalError("Missing URL")
        }
        
        let urlRequest = URLRequest(url: url)
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error!")
                return -1
            }
            print(String(data: data, encoding: .utf8))
            let decoder = JSONDecoder()
            let printerObjectsQuery = try decoder.decode(PrinterObjectsQuery.self, from: data)
            return printerObjectsQuery.result.status.extruder.temperature
            // handle data as JSON
        } catch {
            print("Error!")
            return -1
        }
    }
}

struct KlipperMonMenuBarExtraView_Previews: PreviewProvider {
    @State static var currentMenuBarIcon = "move.3d"
    static var previews: some View {
        KlipperMonMenuBarExtraView(currentMenuBarIcon: $currentMenuBarIcon)
    }
}
