//
//  PeerListener.swift
//  WiTapNW
//
//  Created by tryao on 1/17/24.
//

import Network

var sharedListener: PeerListener?

class PeerListener {

    weak var delegate: PeerConnectionDelegate?
    var listener: NWListener?
    var name: String

    var service: NWListener.Service? {
        return listener?.service
    }

    // Create a listener with a name to advertise,
    // and a delegate to handle inbound connections.
    init(name: String, delegate: PeerConnectionDelegate) {
        self.delegate = delegate
        self.name = name
//        startListening()
    }

    // Start listening and advertising.
    func startListening() {
        do {
            // Create the listener object.
            let listener = try NWListener(using: NWParameters(passcode: ""))
            self.listener = listener

            // Set the service to advertise.
            listener.service = NWListener.Service(name: self.name, type: "_witap2._tcp.")

            listener.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    print("Listener ready on \(String(describing: listener.port))")
                case .failed(let error):
                    // If the listener fails, re-start.
                    if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
                        print("Listener failed with \(error), restarting")
                        listener.cancel()
                        self.startListening()
                    } else {
                        print("Listener failed with \(error), stopping")
                        self.delegate?.displayAdvertiseError(error)
                        listener.cancel()
                    }
                case .cancelled:
                    sharedListener = nil
                default:
                    break
                }
            }

            listener.serviceRegistrationUpdateHandler = { newState in
                switch newState{
                case .add(_):
                    /// Bonjour service has been registered, with the endpoint being advertised
                    self.delegate?.serviceDidPublish()
                default:
                    break
                }
            }

            listener.newConnectionHandler = { newConnection in
                if let delegate = self.delegate {
                    if sharedConnection == nil {
                        // Accept a new connection.
                        sharedConnection = PeerConnection(connection: newConnection, delegate: delegate)
                        self.delegate?.connectionAccept()
                    } else {
                        // If a game is already in progress, reject it.
                        newConnection.cancel()
                    }
                }
            }

            // Start listening, and request updates on the main queue.
            listener.start(queue: .main)
        } catch {
            print("Failed to create listener")
            abort()
        }
    }

    func stopListening(){
        listener?.cancel()
        listener = nil
    }

    // If the user changes their name, update the advertised name.
    func resetName(_ name: String) {
        self.name = name
        if let listener = listener {
            // Reset the service to advertise.
            listener.service = NWListener.Service(name: self.name, type: "_witap2._tcp.")
        }
    }
}
