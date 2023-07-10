/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import XCTest
import Starscream
import Combine
import Network
@testable import Soyuz

class DummyEngine: Engine {
    var delegate: Starscream.EngineDelegate?
    
    @Published var startCalled = false
    @Published var stopCalled = false
    
    func resetForNextTest() {
        self.startCalled = false
        self.stopCalled = false
    }
    
    func register(delegate: Starscream.EngineDelegate) {
        self.delegate = delegate
    }
    
    func start(request: URLRequest) {
        startCalled = true
    }
    
    func stop(closeCode: UInt16) {
        stopCalled = true
        return
    }
    
    func forceStop() {
        stopCalled = true
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
        
        // Test connecting to endpoint
        let connectExpectation = XCTestExpectation(description: "MoonrakerSocketManager.connectToBonjourEndpoint opens Starscream socket")
        
        cancellable = engine.$startCalled
            .sink(receiveValue: { newValue in
                if newValue == true {
                    connectExpectation.fulfill()
                }
            })
        
        socketManager?.connectToBonjourEndpoint(endpoint)
        wait(for: [connectExpectation], timeout: 2)
        XCTAssertTrue(engine.startCalled)
        
        // Test screen sleeping
        engine.resetForNextTest()
        let screenSleepExpectation = XCTestExpectation(description: "MoonrakerSocketManager.screenChangedSleepState screen sleep triggers Starscream socket disconnection")
        
        let sleepNotification = Notification(name: NSWorkspace.screensDidSleepNotification)
        
        cancellable = engine.$stopCalled
            .sink(receiveValue: { newValue in
                if newValue == true {
                    screenSleepExpectation.fulfill()
                }
            })
        
        socketManager?.screenChangedSleepState(sleepNotification)
        wait(for: [screenSleepExpectation], timeout: 2)
        XCTAssertTrue(engine.stopCalled)
        
        // Test screen waking
        engine.resetForNextTest()
        let screenWakeExpectation = XCTestExpectation(description: "MoonrakerSocketManager.screenChangedSleepState screen wake triggers Starscream socket reconnection")
        
        let wakeNotification = Notification(name: NSWorkspace.screensDidWakeNotification)
        
        cancellable = engine.$startCalled
            .sink(receiveValue: { newValue in
                if newValue == true {
                    screenWakeExpectation.fulfill()
                }
            })
        
        socketManager?.screenChangedSleepState(wakeNotification)
        wait(for: [screenWakeExpectation], timeout: 2)
        XCTAssertTrue(engine.startCalled)
    }
    
}
