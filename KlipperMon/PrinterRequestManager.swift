//
//  PrinterRequestManager.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/7/23.
//

import Foundation
import Network
import Starscream

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

class PrinterRequestManager: ObservableObject, WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
            let jsonRpcRequest = JsonRpcRequest(method: "printer.objects.subscribe",
                                                params: ["objects":
                                                            ["extruder": nil,
                                                             "virtual_sdcard": nil,
                                                             "heater_bed": nil,
                                                             "print_stats": nil]
                                                        ])
            
            print(String(data: try! JSONEncoder().encode(jsonRpcRequest), encoding: .utf8)!)
            socket.write(data: try! JSONEncoder().encode(jsonRpcRequest), completion: {
                print("Data transferred.")
            })
        case .disconnected(let reason, let code):
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            break
        case .error(let error):
            print("[error] Starscream: \(error.debugDescription)")
        }
    }
    
    // REST query results
    @Published var printerObjectsQuery: PrinterObjectsQuery?
    
    // Websocket RPC-JSON endpoints discovered via bonjour
    @Published var nwBrowserDiscoveredItems: [NWEndpoint] = []
    
    @Published var printerCommsOkay = false
    
    var socket: WebSocket!
    
    private var socketHost, socketPort: String?
    
    //var nwBrowser: NWBrowser!
    let nwBrowser = NWBrowser(for: .bonjour(type: "_moonraker._tcp", domain: "local."), using: .tcp)
    var connection: NWConnection!
    
    static let shared = PrinterRequestManager()
    
    private init() {
        // MARK: Bonjour browser initialization at instantiation
        nwBrowser.browseResultsChangedHandler = { (newResults, changes) in
            print("[update] Results changed.")
            newResults.forEach { result in
                print(result)
                self.nwBrowserDiscoveredItems.append(result.endpoint)
            }
        }
        // State update handler
        nwBrowser.stateUpdateHandler = { newState in
            switch newState {
            case .failed(let error):
                print("[error] nwbrowser: \(error)")
            case .ready:
                print("[ready] nwbrowser")
                if let innerEndpoint = self.connection?.currentPath?.remoteEndpoint, case .hostPort(let host, let port) = innerEndpoint {
                    print("Connected to:", "\(host):\(port)")
                }
            case .setup:
                print("[setup] nwbrowser")
            default:
                break
            }
        }
        // Start up the bonjour browser, get results and process them in the update handler
        nwBrowser.start(queue: DispatchQueue.main)
    }
    
    // Called from the UI, providing an endpoint.
    // Momentarily connect/disconnects from the endpoint to retrieve the host/port
    // calls private function openWebsocket to process the host/port
    func resolveBonjourHost(_ endpoint: NWEndpoint) {
        connection = NWConnection(to: endpoint, using: .tcp)
        connection.stateUpdateHandler = { [self] state in
            switch state {
            case .ready:
                if let innerEndpoint = connection.currentPath?.remoteEndpoint, case .hostPort(let host, let port) = innerEndpoint {
                    print("Connected to \(host):\(port)")
                    let hostString = "\(host)"
                    let regex = try! Regex("%en0")
                    let match = hostString.firstMatch(of: regex)
                    let sanitizedHost = hostString.replacingOccurrences(of: match!.0, with: "")
                    
                    print("[sanitized] Resolved \(sanitizedHost):\(port)")
                    socketHost = sanitizedHost
                    socketPort = "\(port)"
                    connection.cancel()
                    self.openWebsocket()
                }
            default:
                break
            }
        }
        connection.start(queue: .global())
    }
    
    // Opens the websocket connection
    // TODO: host and port should be function arguments probably maybe
    private func openWebsocket() {
        if let host = socketHost, let port = socketPort {
            //let fullUrlString = "http://\(socketHost):\(socketPort)/websocket"
            var request = URLRequest(url: URL(string: "http://\(host):\(port)/websocket")!)
            request.timeoutInterval = 5
            socket = WebSocket(request: request)
            socket.delegate = self
            socket.connect()
        }
    }
    
    // Old REST way to do it
    // TODO: Stop using this.
    func queryPrinterStats() async {
        guard let url = URL(string: "http://10.0.21.39/printer/objects/query?extruder&virtual_sdcard&print_stats&heater_bed") else {
            fatalError("Missing URL")
        }
        
        let urlRequest = URLRequest(url: url)
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error with response.")
                return
            }
            // handle data as JSON
            let decoder = JSONDecoder()
            printerObjectsQuery = try decoder.decode(PrinterObjectsQuery.self, from: data)
            printerCommsOkay = true
        } catch {
            print("Exception thrown: \(error)")
            printerCommsOkay = false
        }
    }
}
