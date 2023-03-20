//
//  PrinterRequestsManagerTests.swift
//  SoyuzTests
//
//  Created by maddiefuzz on 2/21/23.
//

import XCTest
import Network
@testable import Soyuz

class PrinterRequestManagerTests: XCTestCase {
    var printerRequestManager: PrinterRequestManager?
    
    var testBonjourListener: NWListener?
    
    override func setUp() {
        printerRequestManager = PrinterRequestManager(browser: NWBrowser(for: .bonjour(type: "_http._tcp", domain: "local."), using: .tcp))
        
        // Set up test bonjour server
        //let parameters = NWParameters(tls: .none, tcp: NWListener.)
        do {
            testBonjourListener = try NWListener(using: .tcp, on: .http)
            testBonjourListener!.start(queue: DispatchQueue.main)
        } catch {
            print("Error: \(error)")
        }
    }
    
    func testBonjourDiscoveredItemsNotNil() {
        XCTAssertNotNil(printerRequestManager?.nwBrowserDiscoveredItems)
    }
}
