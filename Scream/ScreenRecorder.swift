//
//  ScreenRecorder.swift
//  Scream
//
//  Created by neon443 on 31/12/2025.
//

import Foundation
import ScreenCaptureKit

class ScreenRecorder: NSObject {
	var isRunning: Bool = false
	var isAppExluded: Bool = false
	var isAudioEnabled: Bool = true
	var filter: SCContentFilter?
	var streamConfig = SCStreamConfiguration()
	var stream: SCStream?
	var streamDelegate = StreamDelegate()
	var streamOutput = StreamOutputDelegate()
	
	let videoSampleBufferQueue = DispatchQueue(label: "videoSampleBufferQueue")
	let audioSampleBufferQueue = DispatchQueue(label: "audioSampleBufferQueue")
	
	var canRecord: Bool {
		true
	}
	
	func start() async {
		guard !isRunning else { return }
		
		let availableContent: SCShareableContent
		do {
			availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
		} catch {
			print(error.localizedDescription)
			return
		}
		
		var excludedApps = [SCRunningApplication]()
		//if users exclude Scream from the screen share
		//exclude by matching bundleid
		if isAppExluded {
			excludedApps = availableContent.applications.filter { app in
				Bundle.main.bundleIdentifier == app.bundleIdentifier
			}
		}
		filter = SCContentFilter(display: availableContent.displays.first!, excludingApplications: excludedApps, exceptingWindows: [])
		
		//TODO: hdr
		
		streamConfig.capturesAudio = isAudioEnabled
		streamConfig.excludesCurrentProcessAudio = true
//		streamConfig.captureMicrophone = true
		
		streamConfig.width = Int(NSScreen.main?.frame.width ?? 100)
		streamConfig.height = Int(NSScreen.main?.frame.height ?? 100)
		
		streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 20)
		streamConfig.queueDepth = 5
		
		stream = SCStream(filter: filter!, configuration: streamConfig, delegate: streamDelegate)
		
		try! stream?.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: videoSampleBufferQueue)
		try! stream?.addStreamOutput(streamOutput, type: .audio, sampleHandlerQueue: audioSampleBufferQueue)
//		try! stream?.addStreamOutput(streamOutput, type: .microphone, sampleHandlerQueue: videoSampleBufferQueue)
		
		//update the config using stream.updateConfiguration or .updateContentFilter
	}
}

extension ScreenRecorder: SCContentSharingPickerObserver  {
	func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor stream: SCStream?) {
		print("canceleed picker")
	}
	
	func contentSharingPicker(_ picker: SCContentSharingPicker, didUpdateWith filter: SCContentFilter, for stream: SCStream?) {
		print(picker.description)
	}
	
	func contentSharingPickerStartDidFailWithError(_ error: any Error) {
		print(error.localizedDescription)
	}
}
