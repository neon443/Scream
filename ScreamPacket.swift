//
//  ScreamPacket.swift
//  Scream
//
//  Created by neon443 on 03/01/2026.
//

import Foundation
import Cocoa
import VideoToolbox

struct ScreamPacket: Codable, Identifiable {
	var id: Double //actually the timestamp seconds :shocked:
	var timestamp: CMTime { .init(seconds: self.id, preferredTimescale: 1000000000) }
	var data: Data
	var index: Int
	var packetsInChunk: Int
	var isKeyframe: Bool
}
