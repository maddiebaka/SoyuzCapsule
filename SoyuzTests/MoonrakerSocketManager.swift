//
//  PrinterRequestsManagerTests.swift
//  SoyuzTests
//
//  Created by maddiefuzz on 2/21/23.
//

import XCTest
import Starscream
import Network
@testable import Soyuz

class PrinterRequestManagerTests: XCTestCase {
    var socketManager: MoonrakerSocketManager?
    
    // Server-side test variables
    let server = WebSocketServer()
    let address = "localhost"
    let port: UInt16 = 80
    
    override func setUp() {
        let server = WebSocketServer()
        
        let error = server.start(address: address, port: port)
        
        if let err = error {
            print("Error starting WebSocket server: \(err)")
        }
        
       socketManager = MoonrakerSocketManager()
    }
    
    func testBlah() {
        guard let url = URL(string: "\(address):\(port)") else {
            return
        }
        print("Success")
        let endpoint = NWEndpoint.url(url)
        print(endpoint.debugDescription)
        socketManager?.connectToBonjourEndpoint(endpoint)
        return
    }
    
//    override func setUp() {
//        printerRequestManager = PrinterRequestManager(browser: NWBrowser(for: .bonjour(type: "_http._tcp", domain: "local."), using: .tcp))
//        
//        // Set up test bonjour server
//        //let parameters = NWParameters(tls: .none, tcp: NWListener.)
//        do {
//            testBonjourListener = try NWListener(using: .tcp, on: .http)
//            testBonjourListener!.start(queue: DispatchQueue.main)
//        } catch {
//            print("Error: \(error)")
//        }
//    }
//    
//    func testBonjourDiscoveredItemsNotNil() {
//        XCTAssertNotNil(printerRequestManager?.nwBrowserDiscoveredItems)
//    }
}
