//
//  SCStreamOutput.swift
//  Scream
//
//  Created by neon443 on 01/01/2026.
//

import Foundation
import ScreenCaptureKit

class StreamOutputDelegate: NSObject, SCStreamOutput {
	func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
		guard sampleBuffer.isValid else { return }
		
		switch type {
		case .screen:
			print("got a screen buffer")
			guard let attachmentsArr = CMSampleBufferGetSampleAttachmentsArray(
				sampleBuffer,
				createIfNecessary: false
			) as? [[SCStreamFrameInfo: Any]],
				  let attachments = attachmentsArr.first else { return }
		case .audio:
			print("got an audio buffer")
		case .microphone:
			print("got a mic buffer")
		@unknown default:
			fatalError("wtf is ur stream sample type")
		}
	}
}
