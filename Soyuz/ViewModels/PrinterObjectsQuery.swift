//
//  PrinterObjectsQuery.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/7/23.
//

import Foundation

// Root struct to decode for REST response
struct PrinterObjectsQuery: Decodable {
    let result: ResultsData
}

struct ResultsData: Decodable {
    let eventtime: Double
    let status: StatusData
}

// Individual update replies for JSON-RPC
struct jsonRpcUpdate: Decodable {
    let method: String?
    let params: jsonRpcParams
}

struct jsonRpcParams: Decodable {
    let status: StatusData?
    let timestamp: Double?
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.status = try container.decode(StatusData.self)
        self.timestamp = try container.decode(Double.self)
    }
}

// Root structs to decode for JSON-RPC response
struct jsonRpcResponse: Decodable  {
    let result: jsonRpcResult
    
}

struct jsonRpcResult: Decodable {
    let eventtime: Double
    let status: StatusData
}

// Shared data sub-structs
struct StatusData: Decodable {
    let virtual_sdcard: VirtualSDCardData?
    let extruder: ExtruderData?
    let print_stats: PrintStatsData?
    let heater_bed: HeaterBedData?
}

struct VirtualSDCardData: Decodable {
    let file_path: String?
    let progress: Double?
    let is_active: Bool?
}

struct ExtruderData: Decodable {
    let temperature: Double?
    let target: Double?
    let power: Double?
}

struct PrintStatsData: Decodable {
    let filename: String?
    let print_duration: Double?
    let filament_used: Double?
    let state: String?
}

struct HeaterBedData: Decodable {
    let temperature: Double?
    let target: Double?
    let power: Double?
}
