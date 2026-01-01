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

	@IBOutlet var window: NSWindow!

	@IBAction func Button(_ sender: Any) {
		Task {
			await sr.start()
		}
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}


}

