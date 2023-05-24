//
//  MoonrakerSocketManagerTests.swift
//  SoyuzTests
//
//  Created by maddiefuzz on 2/21/23.
//

import XCTest
import Starscream
import Combine
import Network
@testable import Soyuz

class DummyEngine: Engine {
    var delegate: Starscream.EngineDelegate?
    
    @Published var startCalled = false
    
    func register(delegate: Starscream.EngineDelegate) {
        self.delegate = delegate
    }
    
    func start(request: URLRequest) {
        startCalled = true
    }
    
    func stop(closeCode: UInt16) {
        return
    }
    
    func forceStop() {
        return
    }
    
    func write(data: Data, opcode: Starscream.FrameOpCode, completion: (() -> ())?) {
        return
    }
    
    func write(string: String, completion: (() -> ())?) {
        return
    }
    
    
}

class MoonrakerSocketManagerTests: XCTestCase {
    var socketManager: MoonrakerSocketManager?
    var bonjourListener: NWListener?
    var engine: DummyEngine!
    var cancellable: AnyCancellable?
    
    override func setUp() {
        engine = DummyEngine()
        socketManager = MoonrakerSocketManager(starscreamEngine: engine!)
        
        do {
            bonjourListener = try NWListener(using: .tcp, on: .http)
            
            bonjourListener!.newConnectionHandler = { newConnection in
                return
            }
            
            bonjourListener!.start(queue: DispatchQueue.main)
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func testConnectToBonjourEndpoint() {
        let endpoint = NWEndpoint.hostPort(host: "localhost", port: .http)
        print("Trying to connect to bonjour endpoint \(endpoint)")
        
        let expectation = XCTestExpectation(description: "MoonrakerSocketManager.connectToBonjourEndpoint opens Starscream socket")
        
        cancellable = engine.$startCalled
            .sink(receiveValue: { newValue in
                if newValue == true {
                    expectation.fulfill()
                }
            })
        
        socketManager?.connectToBonjourEndpoint(endpoint)
        wait(for: [expectation], timeout: 2)
        XCTAssertTrue(engine.startCalled)
    }
}
