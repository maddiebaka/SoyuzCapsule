/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

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
    @Published var networkResults: [NWBrowser.Result] = []
    
    private var nwBrowser: NWBrowser!
    private var connection: NWConnection!
    
    
    init() {
        if nwBrowser == nil {
            setup()
        }
    }
    
    func setup() {
        nwBrowser = NWBrowser(for: .bonjourWithTXTRecord(type: "_moonraker._tcp", domain: "local."), using: .tcp)
        // Bonjour browser results changed handler
        nwBrowser.setBrowseResultsChangedHandler({ (newResults, changes) in
            print("[update] Results changed.")
            self.networkResults.removeAll()
            newResults.forEach { result in
                print(result)
                self.networkResults.append(result)
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
    
    func enableScan(_ queue: DispatchQueue) {
        if(nwBrowser.state == .cancelled) {
            self.setup()
        }
        nwBrowser.start(queue: queue)
    }
    
    func disableScan() {
        if(nwBrowser.state != .cancelled) {
            nwBrowser.cancel()
        }
    }
}
