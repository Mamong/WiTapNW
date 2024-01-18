//
//  PeerBrowser.swift
//  WiTapNW
//
//  Created by tryao on 1/17/24.
//

import Network

protocol PeerBrowserDelegate: AnyObject {
    func refreshResults(results: Set<NWBrowser.Result>)
    func displayBrowseError(_ error: NWError)
}

class PeerBrowser {
    weak var delegate: PeerBrowserDelegate?
    var browser: NWBrowser?

    init(delegate: PeerBrowserDelegate) {
        self.delegate = delegate
//        startBrowsing()
    }

    func startBrowsing(){
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        let browser = NWBrowser(for: .bonjour(type: "_witap2._tcp.", domain: nil), using: parameters)
        self.browser = browser
        browser.stateUpdateHandler = { newState in
            switch newState {
            case .failed(let error):
                if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
                    print("Browser failed with \(error), restarting")
                    browser.cancel()
                    self.startBrowsing()
                } else {
                    print("Browser failed with \(error), stopping")
                                        self.delegate?.displayBrowseError(error)
                    browser.cancel()
                }
            case .ready:
                print("Browser ready")
                self.delegate?.refreshResults(results: browser.browseResults)
            case .cancelled:
                self.delegate?.refreshResults(results: Set())
            default:
                break
            }
        }

        browser.browseResultsChangedHandler = { results, changes in
            self.delegate?.refreshResults(results: results)
        }

        browser.start(queue: .main)
    }

    func stopBrowsing(){
        browser?.cancel()
        browser = nil
    }
}
