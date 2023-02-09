//
//  PrinterObjectsQuery.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/7/23.
//

import Foundation

struct PrinterObjectsQuery: Decodable {
    let result: ResultsData
}

struct ResultsData: Decodable {
    let eventtime: Double
    let status: StatusData
}

struct StatusData: Decodable {
    let virtual_sdcard: VirtualSDCardData
    let extruder: ExtruderData
    let print_stats: PrintStatsData
    let heater_bed: HeaterBedData
}

struct VirtualSDCardData: Decodable {
    let file_path: String?
    let progress: Double
    let is_active: Bool
}

struct ExtruderData: Decodable {
    let temperature: Double
    let target: Double
    let power: Double
}

struct PrintStatsData: Decodable {
    let filename: String
    let print_duration: Double
    let filament_used: Double
    let state: String
}

struct HeaterBedData: Decodable {
    let temperature: Double
    let target: Double
    let power: Double
}
