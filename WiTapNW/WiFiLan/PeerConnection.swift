//
//  PeerConnection.swift
//  WiTapNW
//
//  Created by tryao on 1/17/24.
//
import Foundation
import Network

var sharedConnection: PeerConnection?

protocol PeerConnectionDelegate: AnyObject {
    func serviceDidPublish()

    func connectionReady()

    func connectionFailed()

    // inbound connection
    func connectionAccept()

    func disconnectByRemote()

    func receivedMessage(content: Data?, message: NWProtocolFramer.Message)

    func displayAdvertiseError(_ error: NWError)
}

class PeerConnection {

    weak var delegate: PeerConnectionDelegate?
    var connection: NWConnection?
    let initiatedConnection: Bool

    // Create an outbound connection when the user initiates a game.
    init(endpoint: NWEndpoint, interface: NWInterface?, delegate: PeerConnectionDelegate){
        self.delegate = delegate
        self.initiatedConnection = true

        let parameters = NWParameters(passcode: "")
        let connection = NWConnection(to: endpoint, using: parameters)
        self.connection = connection

        startConnection()
    }

    // Handle an inbound connection when the user receives a game request.
    init(connection: NWConnection, delegate: PeerConnectionDelegate) {
        self.delegate = delegate
        self.connection = connection
        self.initiatedConnection = false

        startConnection()
    }

    // Handle the user exiting the game.
    func cancel() {
        connection?.cancel()
        connection = nil
    }

    // Handle starting the peer-to-peer connection for both inbound and outbound connections.
    func startConnection(){
        guard let connection else { return }

        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("\(connection) established")

                // When the connection is ready, start receiving messages.
                self.receiveNextMessage()

                self.delegate?.connectionReady()
            case .failed(let error):
                print("\(connection) failed with \(error)")

                // Cancel the connection upon a failure.
                connection.cancel()

                self.delegate?.connectionFailed()
            case .cancelled:
                print("\(connection) cancelled")
            default:
                break
            }
        }
        // Start the connection establishment.
        connection.start(queue: .main)
    }

    // Handle sending a "select character" message.
    func selectCharacter(_ character: UInt8) {
        guard let connection else {
            return
        }

        // Create a message object to hold the command type.
        let message = NWProtocolFramer.Message(gameMessageType: .item)
        let context = NWConnection.ContentContext(identifier: "SelectItem",
                                                  metadata: [message])

        // Send the application content along with the message.
        connection.send(content: Data([character]), contentContext: context, isComplete: true, completion: .idempotent)
    }

    // Receive a message, deliver it to your delegate, and continue receiving more messages.
    func receiveNextMessage() {
        guard let connection else { return }

        connection.receiveMessage { completeContent, contentContext, isComplete, error in
            // Extract your message type from the received context.
            if let gameMessage = contentContext?.protocolMetadata(definition: GameProtocol.definition) as? NWProtocolFramer.Message {
                self.delegate?.receivedMessage(content: completeContent, message: gameMessage)
            }
            if error == nil {
                // Continue to receive more messages until you receive and error.
                self.receiveNextMessage()
            } else {
                if case let .posix(code:code) = error {
                    if code == .ENODATA{
                        self.delegate?.disconnectByRemote()
                    }
                    print("receiveNextMessage:\(String(describing: error?.debugDescription))")
                }
            }
        }
    }
}









