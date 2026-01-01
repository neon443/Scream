//
//  CaptureEngine.swift
//  Scream
//
//  Created by neon443 on 01/01/2026.
//

import Foundation
import ScreenCaptureKit

struct CapturedFrame {
	static var invalid: CapturedFrame {
		CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0)
	}
	
	let surface: IOSurface?
	let contentRect: CGRect
	let contentScale: CGFloat
	let scaleFactor: CGFloat
	var size: CGSize { contentRect.size }
}

class CaptureEngine: NSObject {
	private var stream: SCStream?
	var streamOutput: StreamHandler?
	let videoSampleBufferQueue = DispatchQueue(label: "videoSampleBufferQueue")
	let audioSampleBufferQueue = DispatchQueue(label: "audioSampleBufferQueue")
	let micSampleBufferQueue = DispatchQueue(label: "micSampleBufferQueue")
	
	private var continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation?
	
	func startCapture(config: SCStreamConfiguration, filter: SCContentFilter) -> AsyncThrowingStream<CapturedFrame, Error> {
		AsyncThrowingStream<CapturedFrame, Error> { continuation in
			let streamOutput = StreamHandler(continuation: continuation)
			self.streamOutput = streamOutput
			streamOutput.frameBufferHandler = { continuation.yield($0) }
			streamOutput.pcmBufferHandler = { print($0) }
			
			do {
				streamOutput.frameBufferHandler = { frame in
//					print("got frame \(frame.size) at \(frame.contentRect)")
					continuation.yield(frame)
				}
				stream = SCStream(filter: filter, configuration: config, delegate: streamOutput)
				
				try stream?.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: videoSampleBufferQueue)
//				try stream?.addStreamOutput(streamOutput, type: .audio, sampleHandlerQueue: audioSampleBufferQueue)
//				try stream?.addStreamOutput(streamOutput, type: .microphone, sampleHandlerQueue: videoSampleBufferQueue)
				stream?.startCapture()
			} catch {
				continuation.finish(throwing: error)
			}
		}
	}
	
	func stopCapture() async {
		do {
			try await stream?.stopCapture()
			continuation?.finish()
		} catch {
			continuation?.finish(throwing: error)
		}
	}
	
	func update(config: SCStreamConfiguration, filter: SCContentFilter) async {
		do {
			try await stream?.updateConfiguration(config)
			try await stream?.updateContentFilter(filter)
		} catch {
			print(error)
		}
	}
}

class StreamHandler: NSObject, SCStreamOutput, SCStreamDelegate {
	var pcmBufferHandler: ((AVAudioPCMBuffer) -> Void)?
	var frameBufferHandler: ((CapturedFrame) -> Void)?
	
	private var continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation?
	
	init(continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation?) {
		self.continuation = continuation
	}
	
	func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
		guard sampleBuffer.isValid else { return }
		
		switch type {
		case .screen:
			guard let frame = createFrame(for: sampleBuffer) else { return }
			frameBufferHandler?(frame)
		case .audio:
			handleAudio(for: sampleBuffer)
		case .microphone:
			print("idk what to do with mic buffers")
		}
	}
	
	func createFrame(for sampleBuffer: CMSampleBuffer) -> CapturedFrame? {
		guard let attachmentsArr = CMSampleBufferGetSampleAttachmentsArray(
			sampleBuffer,
			createIfNecessary: false
		) as? [[SCStreamFrameInfo: Any]],
			  let attachments = attachmentsArr.first else { return nil }
		
		guard let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
			  let status = SCFrameStatus(rawValue: statusRawValue),
			  status == .complete else { return nil }
		
		guard let pixelBuffer = sampleBuffer.imageBuffer else { return nil }
		
		guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else { return nil }
		let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)
		
		guard let contentRectDict = attachments[.contentRect],
			  let contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary),
			  let contentScale = attachments[.contentScale] as? CGFloat,
			  let scaleFactor = attachments[.scaleFactor] as? CGFloat else { return nil }
		
		var frame = CapturedFrame(surface: surface,
								  contentRect: contentRect,
								  contentScale: contentScale,
								  scaleFactor: scaleFactor)
		return frame
	}
	
	private func handleAudio(for buffer: CMSampleBuffer) -> Void? {
		try? buffer.withAudioBufferList { audioBufferList, blockBuffer in
			guard let description = buffer.formatDescription?.audioStreamBasicDescription,
				  let format = AVAudioFormat(standardFormatWithSampleRate: description.mSampleRate, channels: description.mChannelsPerFrame),
				  let samples = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: audioBufferList.unsafePointer)
			else { return }
			print("got audiobuffer")
			pcmBufferHandler?(samples)
		}
	}
	
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
		continuation?.finish(throwing: error)
	}
}
