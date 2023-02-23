//
//  PrinterRequestsManagerTests.swift
//  SoyuzTests
//
//  Created by maddiefuzz on 2/21/23.
//

import XCTest
@testable import Soyuz

class FileHandleMock: FileHandle {
    override func write(_ data: Data) {
        return
    }
}

class PrinterRequestManagerTests: XCTestCase {
    var printerRequestsManager: PrinterRequestManager?
    
    override func setUp() {
        printerRequestsManager = PrinterRequestManager.shared
    }
    
}
