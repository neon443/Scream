//
//  AppDelegate.swift
//  Scream
//
//  Created by neon443 on 31/12/2025.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
	let sr = ScreenRecorder()
//	let udpclient = UDPClientImplementation(port: 03067)
//	let udpserver = UDPServerImplementation(host: "localhost", port: 03067, initialMessage: "kys")

	@IBOutlet var window: NSWindow!

	@IBAction func Button(_ sender: Any) {
		Task {
			await sr.start()
		}
	}
//	@IBAction func Button2(_ sender: Any) {
//		udpclient.start()
//		udpserver.start()
//	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		let preview = CaptureVideoPreview(layer: sr.contentLayer)
		preview.frame.size = window.contentView!.frame.size
		window.contentView?.addSubview(preview)
		Button(self)
//		Button2(self)
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}
}
