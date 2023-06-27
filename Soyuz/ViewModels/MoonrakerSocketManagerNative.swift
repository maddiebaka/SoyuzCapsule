//
//  MoonrakerSocketManagerNative.swift
//  Soyuz
//
//  Created by Madeline Pace on 6/27/23.
//

import Foundation

import Foundation
import Network
import AppKit
//import Starscream


class MoonrakerSocketManagerNative: ObservableObject {
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
    
    private var socket: NWConnection?
    private var lastPingDate = Date()
    
    // MARK: PRM init()
    init() {
        state = ""
        progress = 0.0
        extruderTemperature = 0.0
        bedTemperature = 0.0
        socketHost = ""
        socketPort = ""
        
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
        
        print("About to connect to endpoint \(endpoint.debugDescription)")
        
        if connection == nil || connection?.state == .cancelled {
            //            //let parameters = NWParameters.tcp
            //            //let options = NWProtocolWebSocket.Options()
            //            //parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
            //            let paramet
            connection = NWConnection(to: endpoint, using: .tcp)
        }
        //
        //        connection!.stateUpdateHandler = { [self] state in
        //            switch state {
        //            case .setup:
        //                break
        //            case .ready:
        //                self.isConnected = true
        //            case .failed(let error):
        //                self.isConnected = false
        //                print("[NWConnection websocket] connection failed: \(error)")
        //            case .cancelled:
        //                self.isConnected = false
        //                print("Connection cancelled.")
        //            default:
        //                break
        //            }
        //        }
        //
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
        //socket?.disconnect()
        //socket = nil
    }
    
    func openWebsocket() {
        let parameters = NWParameters.tcp
        let socketUrl = URL(string: "ws://\(socketHost):\(socketPort)/websocket")
        let options = NWProtocolWebSocket.Options()
        parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
        socket = NWConnection(to: .url(socketUrl!), using: parameters)
        socket?.stateUpdateHandler = { state in
            switch state {
            case .setup:
                print("[websocket] Connection setup.")
            case .ready:
                print("[websocket] Connection ready.")
            case .failed(let error):
                print("[websocket] Connection failed: \(error)")
            case .cancelled:
                print("[websocket] Connection cancelled.")
            default:
                break
            }
        }
        
        socket?.start(queue: .global())
   }
    
    func socketConnectionChangedState() {
        
    }
    
    
    // TODO: This may not work properly when already connected to the socket
    private func reconnectWebsocket() {
        if socket == nil {
            print("Socket doesn't exist. Fail-safe triggered.")
            return
        }
        
        //socket!.disconnect()
        //self.openWebsocket()
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
            //self.openWebsocket()
        default:
            return
        }
    }
}

// Properly formatted JSON-RPC Request for use with Starscream
// MARK: JSON-RPC Request Codable
//struct JsonRpcRequest: Codable {
//    var jsonrpc = "2.0"
//    let method: String
//    let params: [String: [String: String?]]
//    var id = 1
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(jsonrpc, forKey: .jsonrpc)
//        try container.encode(method, forKey: .method)
//        try container.encode(params, forKey: .params)
//        try container.encode(id, forKey: .id)
//    }
//}
