//
//  StreamDelegate.swift
//  Scream
//
//  Created by neon443 on 01/01/2026.
//

import Foundation
import ScreenCaptureKit

class StreamDelegate: NSObject, SCStreamDelegate {
	func outputVideoEffectDidStart(for stream: SCStream) {
		print("presenter overlay started")
	}
	
	func outputVideoEffectDidStop(for stream: SCStream) {
		print("presenter overlay stopped")
	}
	
	func streamDidBecomeActive(_ stream: SCStream) {
		print("stream became Active")
	}
	
	func streamDidBecomeInactive(_ stream: SCStream) {
		print("stream became Inactive")
	}
	
	func stream(_ stream: SCStream, didStopWithError error: any Error) {
		print(error.localizedDescription)
	}
}
