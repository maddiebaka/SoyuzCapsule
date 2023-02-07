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
    let extruder: ExtruderData
}

struct ExtruderData: Decodable {
    let temperature: Double
}
