//
//  CaptureEngine.swift
//  Scream
//
//  Created by neon443 on 01/01/2026.
//

import Foundation
import Cocoa
import ScreenCaptureKit
import VideoToolbox

struct CapturedFrame {
	static var invalid: CapturedFrame {
		CapturedFrame(surface: nil, pixelBuffer: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0, timestamp: .invalid)
	}
	
	let surface: IOSurface?
	let pixelBuffer: CVPixelBuffer?
	let contentRect: CGRect
	let contentScale: CGFloat
	let scaleFactor: CGFloat
	var size: CGSize { contentRect.size }
	var timestamp: CMTime
}

class CaptureEngine: NSObject {
	private var stream: SCStream?
	var streamOutput: StreamHandler?
	let videoSampleBufferQueue = DispatchQueue(label: "videoSampleBufferQueue")
	let audioSampleBufferQueue = DispatchQueue(label: "audioSampleBufferQueue")
	let micSampleBufferQueue = DispatchQueue(label: "micSampleBufferQueue")
	
	private var continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation?
	
	func startCapture(config: SCStreamConfiguration, filter: SCContentFilter) -> AsyncThrowingStream<CapturedFrame, Error> {
		let videoEncoderSpec = [kVTVideoEncoderSpecification_EnableLowLatencyRateControl: true as CFBoolean] as CFDictionary
		
		let sourceImageBufferAttrs = [kCVPixelBufferPixelFormatTypeKey: 1 as CFNumber] as CFDictionary
		var compressionSessionOut: VTCompressionSession?
		let err = VTCompressionSessionCreate(
			allocator: kCFAllocatorDefault,
			width: 3200,
			height: 1800,
			codecType: kCMVideoCodecType_H264,
			encoderSpecification: videoEncoderSpec,
			imageBufferAttributes: sourceImageBufferAttrs,
			compressedDataAllocator: nil,
			outputCallback: nil,
//			outputCallback: { outputCallbackRefCon, sourceFrameRefCon, status, infoFlags, samplebuffer in
//				print(status)
//			},
			refcon: nil,
			compressionSessionOut: &compressionSessionOut
		)
		
		guard err == noErr, let compressionSession = compressionSessionOut else {
			fatalError()
		}
		
		return AsyncThrowingStream<CapturedFrame, Error> { continuation in
			let streamOutput = StreamHandler(continuation: continuation)
			self.streamOutput = streamOutput
			
			do {
				streamOutput.frameBufferHandler = { frame in
					VTCompressionSessionEncodeFrame(compressionSession,
													imageBuffer: frame.pixelBuffer!,
													presentationTimeStamp: frame.timestamp,
													duration: .invalid,
													frameProperties: nil,
													infoFlagsOut: nil
					) { status, infoFlags, sampleBuffer in
						print()
						
					}
//													outputHandler: self.outputHandler)
					continuation.yield(frame)
				}
				streamOutput.pcmBufferHandler = { print($0) }
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
	
	func getEncoderSettings(session: VTCompressionSession) -> [CFString: Any]? {
		var supportedPresetDictionaries: CFDictionary?
		var encoderSettings: [CFString: Any]?
		
		_ = withUnsafeMutablePointer(to: &supportedPresetDictionaries) { valueOut in
			if #available(macOS 26.0, *) {
				VTSessionCopyProperty(session, key: kVTCompressionPropertyKey_SupportedPresetDictionaries, allocator: kCFAllocatorDefault, valueOut: valueOut)
			} else {
				// Fallback on earlier versions
			}
		}
		
		if let presetDictionaries = supportedPresetDictionaries as? [CFString: [CFString: Any]] {
			encoderSettings = presetDictionaries
		}
		
		return encoderSettings
	}
	
	func configureVTCompressionSession(session: VTCompressionSession, expectedFrameRate: Float = 60) throws {
//		var escapedContinuation: AsyncStream<(OSStatus, VTEncodeInfoFlags, CMSampleBuffer?, Int)>.Continuation!
//		let compressedFrameSequence = AsyncStream<(OSStatus, VTEncodeInfoFlags, CMSampleBuffer?, Int)> { escapedContinuation = $0 }
//		let outputContinuation = escapedContinuation!
//		
//		let compressionTask = Task {
//			
//		}
		
		var err: OSStatus = noErr
		var variableBitRateMode = false
		
		let encoderSettings: [CFString: Any]?
		encoderSettings = getEncoderSettings(session: session)
		
		if let encoderSettings {
			if #available(macOS 26.0, *) {
				if encoderSettings[kVTCompressionPropertyKey_VariableBitRate] != nil {
					variableBitRateMode = true
				}
			} else {
				// Fallback on earlier versions
			}
			
			err = VTSessionSetProperties(session, propertyDictionary: encoderSettings as CFDictionary)
			try NSError.check(err, "VTSessionSetProperties failed")
//			err = VTSessionSetProperty(<#T##CM_NONNULL#>, key: <#T##CM_NONNULL#>, value: <#T##CM_NULLABLE#>)
		}
		
		err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
		if err != noErr { print("failed to set to realtime \(err)") }
		
		err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: expectedFrameRate as CFNumber)
		if err != noErr { print("failed to set to framerte \(err)") }

		err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Main_AutoLevel)
		if err != noErr { print("failed to set to profile level \(err)") }
		
		err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: 10 as CFNumber)
		if err != noErr { print("failed to set to framerte \(err)") }
		
		err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: 60 as CFNumber)
		if err != noErr { print("failed to set to keyframe interval \(err)") }
		
		err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, value: 1 as CFNumber)
		if err != noErr { print("failed to set to keyframe interval duratation \(err)") }
		
//		err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_SuggestedLookAheadFrameCount, value: 1 as CFNumber)
//		if err != noErr { print("failed to set to lookahead \(err)") }
		
//		err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_SpatialAdaptiveQPLevel, value: 1 as CFNumber)
//		if err != noErr { print("failed to set to framerte \(err)") }
		
//		VTCompressionSessionEncodeFrame(session, imageBuffer: <#T##CVImageBuffer#>, presentationTimeStamp: <#T##CMTime#>, duration: <#T##CMTime#>, frameProperties: <#T##CFDictionary?#>, infoFlagsOut: <#T##UnsafeMutablePointer<VTEncodeInfoFlags>?#>, outputHandler: <#T##VTCompressionOutputHandler##VTCompressionOutputHandler##(OSStatus, VTEncodeInfoFlags, CMSampleBuffer?) -> Void#>)
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
								  pixelBuffer: pixelBuffer,
								  contentRect: contentRect,
								  contentScale: contentScale,
								  scaleFactor: scaleFactor,
								  timestamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
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

extension NSError {
	static func check(_ status: OSStatus, _ message: String? = nil) throws {
		guard status == noErr else {
			if let message {
				print("\(message), err: \(status)")
			}
			throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
		}
	}
}
