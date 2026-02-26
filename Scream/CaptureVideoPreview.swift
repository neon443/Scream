//
//  CaptureVideoPreview.swift
//  Scream
//
//  Created by neon443 on 26/02/2026.
//

import Foundation
import Cocoa

class CaptureVideoPreview: NSView {
	init(layer: CALayer) {
		super.init(frame: .zero)
		wantsLayer = true
		self.layer = layer
		layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
	}
	
	required init?(coder: NSCoder) {
		fatalError()
	}
}
