//
//  PrinterRequestManager.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/7/23.
//

import Foundation
import Network
import AppKit
import Starscream


// Protocol defining minimal API for network discovery
// MARK: Net Discovery Protocol
protocol NetworkDiscoveryEngine {
    func startScan(queue: DispatchQueue)
    func setBrowseResultsChangedHandler(_ handler: @escaping ((Set<NWBrowser.Result>, Set<NWBrowser.Result.Change>) -> Void))
    func setStateUpdateHandler(_ handler: @escaping ((NWBrowser.State) -> Void))
}

extension NWBrowser: NetworkDiscoveryEngine {
    func startScan(queue: DispatchQueue) {
        start(queue: queue)
    }
    
    func setBrowseResultsChangedHandler(_ handler: @escaping ((Set<NWBrowser.Result>, Set<NWBrowser.Result.Change>) -> Void)) {
        self.browseResultsChangedHandler = handler
    }
    
    func setStateUpdateHandler(_ handler: @escaping ((State) -> Void)) {
        self.stateUpdateHandler = handler
    }
}


// Properly formatted JSON-RPC Request for use with Starscream
// MARK: JSON-RPC Request Codable
struct JsonRpcRequest: Codable {
    var jsonrpc = "2.0"
    let method: String
    let params: [String: [String: String?]]
    var id = 1
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(method, forKey: .method)
        try container.encode(params, forKey: .params)
        try container.encode(id, forKey: .id)
    }
}

// MARK: PrinterRequestManager
//@MainActor
class PrinterRequestManager: ObservableObject, WebSocketDelegate {
    let WEBSOCKET_TIMEOUT_INTERVAL: TimeInterval = 60.0
    
    // Debug timestamp stuff
    let startDate = Date()
    let startDateString: String
    let filename: URL
    
    // Debug file writing stuff
    func writeToDebugLog(_ output: String) {
        do {
            let fileHandle = try FileHandle(forWritingTo: filename)
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS"
            
            let debugOutput = String("\(dateFormatter.string(from: Date())) - \(output)\n")
            fileHandle.write(debugOutput.data(using: .utf8)!)
        } catch {
            print("[error] writeToDebugLog - \(error)")
        }
    }
    
    // Websocket JSON-RPC endpoints discovered via bonjour
    @Published var nwBrowserDiscoveredItems: [NWBrowser.Result] = []
    
    
    // Websocket JSON-RPC published data
    @Published var state: String
    @Published var progress: Double
    @Published var extruderTemperature: Double
    @Published var bedTemperature: Double
    
    // Active connection published data
    @Published var isConnected = false
    @Published var socketHost: String
    @Published var socketPort: String
    
    let nwBrowser: NetworkDiscoveryEngine
    var connection: NWConnection!
    
    var socket: WebSocket?
    var lastPingDate = Date()
    
    // MARK: PRM init()
    init(browser: NetworkDiscoveryEngine = NWBrowser(for: .bonjourWithTXTRecord(type: "_moonraker._tcp", domain: "local."), using: .tcp)) {
        state = ""
        progress = 0.0
        extruderTemperature = 0.0
        bedTemperature = 0.0
        socketHost = ""
        socketPort = ""
        nwBrowser = browser
        
        // Debug output-to-file functionality
        startDateString = "\(startDate)\n\n"
        filename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("klippermon-debug-\(startDateString).txt")
        
        do {
            try startDateString.write(to: filename, atomically: true, encoding: .utf8)
        } catch {
            print("[error] Couldn't write to \(filename) - \(error)")
        }
        
        // Bonjour browser results changed handler
        nwBrowser.setBrowseResultsChangedHandler({ (newResults, changes) in
            print("[update] Results changed.")
            newResults.forEach { result in
                print(result)
                self.nwBrowserDiscoveredItems.append(result)
            }
        })
        // Bonjour browser state update handler
        nwBrowser.setStateUpdateHandler({ newState in
            switch newState {
            case .failed(let error):
                print("[error] nwbrowser: \(error)")
            case .ready:
                print("[ready] nwbrowser")
            case .setup:
                print("[setup] nwbrowser")
            default:
                break
            }
        })
        
        // Set up sleep/wake notification observers
        let center = NSWorkspace.shared.notificationCenter;
        let mainQueue = OperationQueue.main
        
        center.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: mainQueue) { notification in
            self.screenChangedSleepState(notification)
        }
        
        center.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: mainQueue) { notification in
            self.screenChangedSleepState(notification)
        }
        
        // Start up the bonjour browser, get results and process them in the update handler
        nwBrowser.startScan(queue: DispatchQueue.main)
    }
    
    // Called from the UI with an endpoint.
    // Momentarily connect/disconnects from the endpoint to retrieve the host/port
    // calls private function openWebsocket to process the host/port
    func connectToBonjourEndpoint(_ endpoint: NWEndpoint) {
        // Debug stuff
        endpoint.txtRecord?.forEach({ (key: String, value: NWTXTRecord.Entry) in
            print("\(key): \(value)")
        })
        
        connection = NWConnection(to: endpoint, using: .tcp)
        connection.stateUpdateHandler = { [self] state in
            switch state {
            case .ready:
                if let innerEndpoint = connection.currentPath?.remoteEndpoint, case .hostPort(let host, let port) = innerEndpoint {
                    let hostPortDebugOutput = "Connected to \(host):\(port)"
                    
                    print(hostPortDebugOutput)
                    writeToDebugLog(hostPortDebugOutput)
                    
                    let hostString = "\(host)"
                    let regex = try! Regex("%(.+)")
                    let match = hostString.firstMatch(of: regex)
                    let sanitizedHost = hostString.replacingOccurrences(of: match!.0, with: "")
                    
                    print("[sanitized] Resolved \(sanitizedHost):\(port)")
                    
                    connection.cancel()
                    
                    DispatchQueue.main.async {
                        self.socketHost = sanitizedHost
                        self.socketPort = "\(port)"
                        self.openWebsocket()
                    }
                }
            default:
                break
            }
        }
        connection.start(queue: .global())
    }

    
    // MARK: Private functions
    
    // Opens the websocket connection
    private func openWebsocket() {
        //let fullUrlString = "http://\(socketHost):\(socketPort)/websocket"
        var request = URLRequest(url: URL(string: "http://\(socketHost):\(socketPort)/websocket")!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket!.delegate = self
        socket!.connect()
    }
    
    private func reconnectWebsocket() {
        if socket == nil {
            return
        }
        
        socket!.disconnect()
        self.openWebsocket()
    }
    
    // MARK: Callsbacks
    func screenChangedSleepState(_ notification: Notification) {
        switch(notification.name) {
        case NSWorkspace.screensDidSleepNotification:
            socket?.disconnect()
        case NSWorkspace.screensDidWakeNotification:
            self.openWebsocket()
        default:
            return
        }
    }
    
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
        switch event {
        case .connected(let headers):
            isConnected = true
            print("websocket is connected: \(headers)")
            writeToDebugLog("Connected to WebSocket")
            let jsonRpcRequest = JsonRpcRequest(method: "printer.objects.subscribe",
                                                params: ["objects":
                                                            ["extruder": nil,
                                                             "virtual_sdcard": nil,
                                                             "heater_bed": nil,
                                                             "print_stats": nil]
                                                        ])
            
            print(String(data: try! JSONEncoder().encode(jsonRpcRequest), encoding: .utf8)!)
            socket?.write(data: try! JSONEncoder().encode(jsonRpcRequest), completion: {
                print("[send] json-rpc printer.objects.subscribe query")
            })
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
            writeToDebugLog("Websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            self.writeToDebugLog(string)
            // Check for initial RPC response
            let statusResponse = try? JSONDecoder().decode(jsonRpcResponse.self, from: Data(string.utf8))
            if let statusResponseSafe = statusResponse {
                self.parse_response(statusResponseSafe)
            }
            // Check for RPC updates
            if let updateResponse = try? JSONDecoder().decode(jsonRpcUpdate.self, from: Data(string.utf8)) {
                self.parse_update(updateResponse)
            }
        case .binary(let data):
            self.writeToDebugLog(String(data: data, encoding: .utf8)!)
            print("Received data: \(data.count)")
        case .ping(_):
            print("PING! \(Date())")
            // TODO: There's probably a better way to do this
            if(lastPingDate.addingTimeInterval(WEBSOCKET_TIMEOUT_INTERVAL) < Date.now) {
                print("Forcing reconnection of websocket..")
                self.reconnectWebsocket()
            }
            lastPingDate = Date()
            break
        case .pong(_):
            print("PONG!")
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
        case .error(let error):
            isConnected = false
            print("[error] Starscream: \(error.debugDescription)")
        }
    }
    
    // MARK: JSON-RPC Parsing
    // Parse a JSON-RPC query-response message
    func parse_response(_ response: jsonRpcResponse) {
        state = response.result.status.print_stats?.state ?? ""
        progress = response.result.status.virtual_sdcard?.progress ?? 0.0
        extruderTemperature = response.result.status.extruder?.temperature ?? 0.0
        bedTemperature = response.result.status.heater_bed?.temperature ?? 0.0
        
        print(response)
    }
    
    // Parse a JSON-RPC update message
    func parse_update(_ update: jsonRpcUpdate) {
        if let newState = update.params.status?.print_stats?.state {
            state = newState
        }
        if let newProgress = update.params.status?.virtual_sdcard?.progress  {
            progress = newProgress
        }
        if let newExtruderTemp = update.params.status?.extruder?.temperature  {
            extruderTemperature = newExtruderTemp
        }
        if let newBedTemp = update.params.status?.heater_bed?.temperature  {
            bedTemperature = newBedTemp
        }
    }
}