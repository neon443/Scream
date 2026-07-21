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
	static let controller = StreamWindowController()
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
		
		AppDelegate.controller.showWindow(nil)
		
//		controller.streamView.display(sampleBuffer: sampleBuffer)

		window.addChildWindow(AppDelegate.controller.window!, ordered: .above)
	}

	func applicationWillTerminate(_ aNotification: Notification) { }

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}
}


import Cocoa
import AVFoundation
import VideoToolbox

final class StreamWindowView: NSView {
	
	private let displayLayer = AVSampleBufferDisplayLayer()
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		
		wantsLayer = true
		
		displayLayer.videoGravity = .resizeAspect
		displayLayer.frame = bounds
		displayLayer.autoresizingMask = [
			.layerWidthSizable,
			.layerHeightSizable
		]
		
		layer?.addSublayer(displayLayer)
	}
	
	required init?(coder: NSCoder) {
		fatalError()
	}
	
	// Feed packets here.
	func enqueue(packet: ScreamPacket) {
		
		// POC:
		// Pretend packet.data already contains one complete CMSampleBuffer.
		//
		// Later this will become:
		// packet -> NAL units -> CMBlockBuffer ->
		// CMSampleBuffer -> displayLayer.enqueue()
		
	}
	
	// POC helper
	func display(sampleBuffer: CMSampleBuffer) {
		displayLayer.enqueue(sampleBuffer)
	}
	
	func flush() {
		displayLayer.flushAndRemoveImage()
	}
}
import Cocoa

final class StreamWindowController: NSWindowController {
	
	let streamView = StreamWindowView(frame: .zero)
	
	convenience init() {
		
		let window = NSWindow(
			contentRect: NSRect(x: 100, y: 100, width: 1280, height: 720),
			styleMask: [
				.titled,
				.closable,
				.miniaturizable,
				.resizable
			],
			backing: .buffered,
			defer: false
		)
		
		self.init(window: window)
		
		window.title = "Remote Stream"
		window.contentView = streamView
		
		// Hardcoded black background
		streamView.layer?.backgroundColor = NSColor.black.cgColor
	}
}
