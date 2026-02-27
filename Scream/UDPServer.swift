//
//  UDPServer.swift
//  Scream
//
//  Created by neon443 on 26/02/2026.
//

import Foundation
import Network

protocol UDPServer {
	func start()
	func stop()
	func send(message: String)
}

final class UDPServerImplementation: Sendable {
//	public static let shared: UDPServerImplementation = .init(host: "localhost", port: 03067, initialMessage: nil)
	private let connection: NWConnection
	
	init(host: String, port: UInt16, initialMessage: String?) {
		connection = NWConnection(
			host: NWEndpoint.Host(host),
			port: NWEndpoint.Port(integerLiteral: port),
			using: .udp
		)
		connection.stateUpdateHandler = { [weak self] state in
			print("server state is \(state)")
			if state == .ready {
				guard let initialMessage else { return }
				self?.send(message: initialMessage)
			}
		}
	}
}

extension UDPServerImplementation: UDPServer {
	func start() {
		connection.start(queue: .global())
		print("server startedf")
	}
	
	func stop() {
		connection.cancel()
		print("server stopped")
	}
	
	func send(_ data: Data) {
		connection.send(content: data, completion: .contentProcessed({ error in
			if let error {
				print("server: fialed to send \(error)")
			} else {
				print("server: message sent")
			}
		}))
	}
	
	func send(message: String) {
		guard let data = message.data(using: .utf8) else {
			print("server: encode message failed")
			return
		}
		
		connection.send(content: data, completion: .contentProcessed({ error in
			if let error {
				print("server: failed to send \(error)")
			} else {
				print("server: message sent")
			}
		}))
	}
}
