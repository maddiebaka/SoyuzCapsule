//
//  MoonrakerSocketManager.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/7/23.
//

import Foundation
import Network
import AppKit
import Starscream


class MoonrakerSocketManager: ObservableObject, WebSocketDelegate {
    let WEBSOCKET_TIMEOUT_INTERVAL: TimeInterval = 60.0
    
    // Websocket JSON-RPC published data
    @Published var state: String
    @Published var progress: Double
    @Published var extruderTemperature: Double
    @Published var bedTemperature: Double
    
    // Active connection published data
    @Published var isConnected = false
    @Published var socketHost: String
    @Published var socketPort: String
    
    // Published NWConnection for listing connection information
    @Published var connection: NWConnection?
    @Published var friendlyHostname: String = ""
    
    var notification = UserNotificationHandler.shared
    
    private var socket: WebSocket?
    private var lastPingDate = Date()
    private var starscreamEngine: Engine
    
    
    // MARK: PRM init()
    init(starscreamEngine: Engine = WSEngine(transport: TCPTransport())) {
        state = ""
        progress = 0.0
        extruderTemperature = 0.0
        bedTemperature = 0.0
        socketHost = ""
        socketPort = ""
        
        self.starscreamEngine = starscreamEngine
        
        // Set up sleep/wake notification observers
        let center = NSWorkspace.shared.notificationCenter;
        let mainQueue = OperationQueue.main
        
        center.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: mainQueue) { notification in
            self.screenChangedSleepState(notification)
        }
        
        center.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: mainQueue) { notification in
            self.screenChangedSleepState(notification)
        }
    }
    
    // Called from the UI with an endpoint.
    // Momentarily connect/disconnects from the endpoint to retrieve the host/port
    // calls private function openWebsocket to process the host/port
    func connectToBonjourEndpoint(_ endpoint: NWEndpoint) {
        // Debug stuff
        endpoint.txtRecord?.forEach({ (key: String, value: NWTXTRecord.Entry) in
            print("\(key): \(value)")
        })
        
        //        if isConnected == true {
        //            connection?.cancel()
        //            socket?.disconnect()
        //        }
        //
        if connection == nil || connection?.state == .cancelled {
            connection = NWConnection(to: endpoint, using: .tcp)
        }
        
        connection?.stateUpdateHandler = { [self] state in
            switch state {
            case .ready:
                if let innerEndpoint = connection?.currentPath?.remoteEndpoint, case .hostPort(let host, let port) = innerEndpoint {
                    let hostPortDebugOutput = "Connected to \(host):\(port)"
                    
                    print(hostPortDebugOutput)
                    
                    let hostString = "\(host)"
                    let regex = try! Regex("%(.+)")
                    let match = hostString.firstMatch(of: regex)
                    
                    let sanitizedHost = hostString.replacingOccurrences(of: match?.0 ?? "", with: "")
                    
                    print("[sanitized] Resolved \(sanitizedHost):\(port)")
                    
                    connection?.cancel()
                    
                    DispatchQueue.main.async {
                        self.friendlyHostname = endpoint.toFriendlyString()
                        self.socketHost = sanitizedHost
                        self.socketPort = "\(port)"
                        self.openWebsocket()
                    }
                }
            default:
                break
            }
        }
        connection?.start(queue: .global())
    }
    
    func disconnect() {
        print("disconnect() called")
        self.isConnected = false
        socket?.disconnect()
        socket = nil
    }
    
    
    // MARK: Private functions
    
    // Opens the websocket connection
    func openWebsocket() {
        // Exit function if there is no server to connect to
        if socketHost.isEmpty || socketPort.isEmpty {
            return
        }
        
        if socket != nil {
            socket!.connect()
            return
        }
        
        lastPingDate = Date.now
        
        var request = URLRequest(url: URL(string: "ws://\(socketHost):\(socketPort)/websocket")!)
        request.timeoutInterval = 30
        socket = WebSocket(request: request, engine: starscreamEngine)
        socket!.delegate = self
        print("About to connect to WebSocket at: \(request.debugDescription)")
        socket!.connect()
    }
    
    // TODO: This may not work properly when already connected to the socket
    private func reconnectWebsocket() {
        if socket == nil {
            print("Socket doesn't exist. Fail-safe triggered.")
            return
        }
        
        socket!.disconnect()
        self.openWebsocket()
    }
    
    // MARK: Callbacks
    func screenChangedSleepState(_ notification: Notification) {
        switch(notification.name) {
        case NSWorkspace.screensDidSleepNotification:
            print("Screen slept. Disconnecting..")
            self.disconnect()
            //socket?.disconnect()
        case NSWorkspace.screensDidWakeNotification:
            print("Screen awoke. Opening websocket..")
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
        case .text(let string):
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
            switch(error) {
            case .some(HTTPUpgradeError.notAnUpgrade(200)):
                print("[debug] Starscream: Forcing disconnect and reconnect..")
                self.socket?.forceDisconnect()
                self.socket = nil
                self.openWebsocket()
            default:
                break
            }
        }
    }
    
    // MARK: JSON-RPC Parsing
    // Parse a JSON-RPC query-response message
    func parse_response(_ response: jsonRpcResponse) {
        state = response.result.status.print_stats?.state ?? ""
        
        
        progress = response.result.status.virtual_sdcard?.progress ?? 0.0
        extruderTemperature = response.result.status.extruder?.temperature ?? 0.0
        bedTemperature = response.result.status.heater_bed?.temperature ?? 0.0
    }
    
    // Parse a JSON-RPC update message
    func parse_update(_ update: jsonRpcUpdate) {
        if let newState = update.params.status?.print_stats?.state {
            print("Printer state: \(newState)")
            // Issue a notification when state changes from printing to complete
            // TODO: Handle this better
            if newState == "complete" && state == "printing" {
                notification.sendNotification(.printComplete)
            }
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
