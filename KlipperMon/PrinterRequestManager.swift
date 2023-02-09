//
//  PrinterRequestManager.swift
//  KlipperMon
//
//  Created by maddiefuzz on 2/7/23.
//

import Foundation
import Network
import Starscream

struct JsonRpcRequest: Encodable {
    let jsonrpc = "2.0"
    let method: String
    let params: [String: String]
    //let id = UUID()
}

class PrinterRequestManager: ObservableObject, WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
        switch event {
        case .connected(let headers):
            //isConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            //isConnected = false
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
            //isConnected = false
            break
        case .error(let error):
            print("[error] Starscream: \(error.debugDescription)")
            //isConnected = false
            //handleError(error)
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
        // MARK: Starscream shit
        //
        //
        print("init PRM..")
        //        var request = URLRequest(url: URL(string: "http://10.0.21.39:7125/websocket")!)
        //        request.timeoutInterval = 5
        //        socket = WebSocket(request: request)
        //        socket.delegate = self
        //socket.connect()
        
        //let data = try! JSONEncoder().encode(JsonRpcRequest(method: "printer.objects.list", params: [:]))
        //socket.write(data: data)
        
        // MARK: NWBrowser shit
        //
        //
        nwBrowser.browseResultsChangedHandler = { (newResults, changes) in
            print("[update] Results changed.")
            newResults.forEach { result in
                print(result)
                self.nwBrowserDiscoveredItems.append(result.endpoint)
            }
            //self.nwBrowserDiscoveredItems.append(newResults.description)
        }
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
        nwBrowser.start(queue: DispatchQueue.main)
    }
    
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
        //connection.cancel()
        
        //self.openWebsocket()
    }
    // NWConnection shit
    //connection = NWConnection(
    
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
            //return printerObjectsQuery.result.status.extruder.temperature
        } catch {
            print("Exception thrown: \(error)")
            printerCommsOkay = false
        }
    }
}
