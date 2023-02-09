//
//  PrinterRequestManager.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/7/23.
//

import Foundation
import Network

@MainActor
class PrinterRequestManager: ObservableObject {
    @Published var printerObjectsQuery: PrinterObjectsQuery?
    
    @Published var printerCommsOkay = false
    
    static let shared = PrinterRequestManager()
    
    //let nwBrowser = NWBrowser(for: .bonjour(type: "_moonraker._tcp", domain: "local."), using: .tcp)
    
    private init() {
        
    }
    
    func queryPrinterStats() async {
        guard let url = URL(string: "http://10.0.21.39/printer/objects/query?extruder&virtual_sdcard&print_stats&heater_bed") else {
            fatalError("Missing URL")
        }
        
        let urlRequest = URLRequest(url: url)
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error with response.")
                return
            }
            // handle data as JSON
            let decoder = JSONDecoder()
            printerObjectsQuery = try decoder.decode(PrinterObjectsQuery.self, from: data)
            printerCommsOkay = true
            //return printerObjectsQuery.result.status.extruder.temperature
        } catch {
            print("Exception thrown: \(error)")
            printerCommsOkay = false
        }
    }
}
