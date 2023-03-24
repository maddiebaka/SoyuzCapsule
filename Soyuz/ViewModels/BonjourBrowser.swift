//
//  BonjourBrowser.swift
//  Soyuz
//
//  Created by maddiefuzz on 3/20/23.
//

import Foundation
import Network

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

// MARK: BonjourBrowser

class BonjourBrowser: ObservableObject {
    @Published var NDEngineResults: [NWBrowser.Result] = []
    
    private let nwBrowser: NetworkDiscoveryEngine
    var connection: NWConnection!
    
    // TEMPORARY
//    var bonjourListener: NWListener?

    init(browser: NetworkDiscoveryEngine = NWBrowser(for: .bonjourWithTXTRecord(type: "_moonraker._tcp", domain: "local."), using: .tcp)) {
        nwBrowser = browser
        // Bonjour browser results changed handler
        nwBrowser.setBrowseResultsChangedHandler({ (newResults, changes) in
            print("[update] Results changed.")
            self.NDEngineResults.removeAll()
            newResults.forEach { result in
                print(result)
                self.NDEngineResults.append(result)
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
        
        nwBrowser.startScan(queue: DispatchQueue.main)
    }
    
}
