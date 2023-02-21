//
//  PrinterStats.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/9/23.
//

import Foundation

class PrinterStats: ObservableObject {
    @Published var state: String
    @Published var progress: Double
    @Published var extruderTemperature: Double
    @Published var bedTemperature: Double
    
    init(response: jsonRpcResponse) {
        state = response.result.status.print_stats?.state ?? ""
        progress = response.result.status.virtual_sdcard?.progress ?? 0.0
        extruderTemperature = response.result.status.extruder?.temperature ?? 0.0
        bedTemperature = response.result.status.heater_bed?.temperature ?? 0.0
        
        print(response)
    }
    
    func update(update: jsonRpcUpdate) {
//        print(update)
        if let newState = update.params.status?.print_stats?.state {
            //state = update.params[0].print_stats?.state
            state = newState
        }
        if let newProgress = update.params.status?.virtual_sdcard?.progress  {
            print("Update progress")
            progress = newProgress
        }
        if let newExtruderTemp = update.params.status?.extruder?.temperature  {
            print("Update extruder temp \(newExtruderTemp)")
            extruderTemperature = newExtruderTemp
        }
        if let newBedTemp = update.params.status?.heater_bed?.temperature  {
            print("Update heated bed \(newBedTemp)")
            bedTemperature = newBedTemp
        }
    }
}
