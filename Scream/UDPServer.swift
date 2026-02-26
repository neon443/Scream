//
//  UDPServer.swift
//  Scream
//
//  Created by neon443 on 26/02/2026.
//

import Foundation
import Network

final class UDPServerImplementation: Sendable {
	private let connectionListener: NWListener
	
	//init a udp server at x port
	init(port: UInt16) {
		connectionListener = try! NWListener(
			using: .udp,
			on: NWEndpoint.Port(integerLiteral: port)
		)
		
		connectionListener.newConnectionHandler = { [weak self] connection in
			connection.start(queue: .global())
			self?.receive(on: connection)
		}
		
		connectionListener.stateUpdateHandler = { state in
			print("state: \(state)")
		}
	}
}

protocol UDPServer {
	func start()
	func stop()
}

extension UDPServerImplementation: UDPServer {
	func start() {
		connectionListener.start(queue: .global())
		print("server started")
	}
	
	func stop() {
		connectionListener.cancel()
		print("server stoped")
	}
}

private extension UDPServerImplementation {
	func receive(on connection: NWConnection) {
		connection.receiveMessage { data, contentContext, isComplete, error in
			if let error {
				print("error \(error)")
			}
			
			if let data, 
			   let message = String(data: data, encoding: .utf8) {
				print(message)
			}
		}
	}
}
