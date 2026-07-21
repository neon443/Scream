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
	lazy var preview = CaptureVideoPreview(layer: sr.contentLayer)
	let button = NSButton(title: "Start Stream", target: self, action: #selector(Button))
	var isRunning = false
//	let udpclient = UDPClientImplementation(port: 03067)
//	let udpserver = UDPServerImplementation(host: "localhost", port: 03067, initialMessage: "kys")

	@IBOutlet var window: NSWindow!

	@IBAction func Button(_ sender: Any) {
		isRunning.toggle()
		print(isRunning,  "\(isRunning ? "Stop" : "Start") Stream")
		self.button.title = "\(isRunning ? "Stop" : "Start") Stream"
		preview.layer?.opacity = isRunning ? 1 : 0
		Task {
			if isRunning {
				await sr.start()
			} else {
				await sr.stop()
			}
		}
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		window.contentView?.addSubview(preview)
		window.contentView?.addSubview(button)
		preview.translatesAutoresizingMaskIntoConstraints = false
		
		preview.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor).isActive = true
		preview.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor).isActive = true
		preview.topAnchor.constraint(equalTo: window.contentView!.topAnchor).isActive = true
		preview.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor).isActive = true
		
	}

	func applicationWillTerminate(_ aNotification: Notification) { }

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}
}
