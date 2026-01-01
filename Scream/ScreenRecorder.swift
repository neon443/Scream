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
	var isAppExluded: Bool = true
	var isAudioEnabled: Bool = false
	
	var filter: SCContentFilter?
//		var filter: SCContentFilter
//		
//		var excludedApps = [SCRunningApplication]()
//		//if users exclude Scream from the screen share
//		//exclude by matching bundleid
////		if isAppExluded {
////			excludedApps = availableContent.applications.filter { app in
////				Bundle.main.bundleIdentifier == app.bundleIdentifier
////			}
////		}
//		filter = SCContentFilter(display: availableContent.displays.first!, excludingApplications: excludedApps, exceptingWindows: [])
//	}
	
	var streamConfig: SCStreamConfiguration {
		var streamConfig = SCStreamConfiguration()
		//TODO: hdr
//		streamConfig.capturesAudio = isAudioEnabled
//		streamConfig.excludesCurrentProcessAudio = false
//		streamConfig.captureMicrophone = true
		
		streamConfig.width = Int(NSScreen.main?.frame.width ?? 100)
		streamConfig.height = Int(NSScreen.main?.frame.height ?? 100)
		
		streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 20)
		streamConfig.queueDepth = 5
		return streamConfig
	}
	let captureEngine = CaptureEngine()
	
	var contentLayer = CALayer()
	
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
		
		do {
			isRunning = true
			for try await frame in captureEngine.startCapture(config: streamConfig, filter: filter!) {
				contentLayer.contents = frame.surface
			}
		} catch {
			isRunning = false
			print(error.localizedDescription)
		}
		//TODO: update the config using stream.updateConfiguration or .updateContentFilter
	}
	
	func stop() async {
		guard isRunning else { return }
		await captureEngine.stopCapture()
		isRunning = false
	}
}

extension ScreenRecorder: SCContentSharingPickerObserver  {
	@available(macOS 14, *)
	func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor stream: SCStream?) {
		print("canceleed picker")
	}
	@available(macOS 14, *)
	func contentSharingPicker(_ picker: SCContentSharingPicker, didUpdateWith filter: SCContentFilter, for stream: SCStream?) {
		print(picker.description)
	}
	
	func contentSharingPickerStartDidFailWithError(_ error: any Error) {
		print(error.localizedDescription)
	}
}
