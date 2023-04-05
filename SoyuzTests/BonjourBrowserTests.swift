//
//  BonjourBrowserTests.swift
//  SoyuzTests
//
//  Created by maddiefuzz on 3/24/23.
//

import XCTest
import Network
import Combine
@testable import Soyuz

class SoyuzBonjourBrowserTests: XCTestCase {
    var bonjourBrowser: BonjourBrowser?
    var bonjourListener: NWListener?
    var cancellable: AnyCancellable?
    
    override func setUp() {
        do {
            bonjourListener = try NWListener(using: .tcp, on: .http)
            bonjourListener!.service = NWListener.Service(name: "Test", type: "_xctest._tcp")
            
            bonjourListener!.newConnectionHandler = { newConnection in
                return
            }
        } catch {
            print("Error: \(error)")
        }
        bonjourBrowser = BonjourBrowser(browser: NWBrowser(for: .bonjour(type: "_xctest._tcp", domain: "local."), using: .tcp))
    }
    
    func testBonjourDiscoveredItemsPopulated() {
        guard let browser = bonjourBrowser else {
            XCTAssert(false)
            return
        }
        
        let expectation = XCTestExpectation(description: "BonjourBrowser publishes network services")
        
        cancellable = browser.$NDEngineResults
            .dropFirst()
            .sink(receiveValue: { newValue in
                if newValue.count > 0 {
                    expectation.fulfill()
                }
            })
        
        bonjourListener!.start(queue: DispatchQueue.main)
        wait(for: [expectation], timeout: 2)
        XCTAssert(!browser.NDEngineResults.isEmpty)
        XCTAssertEqual(browser.NDEngineResults.count, 1)
    }
    
}
