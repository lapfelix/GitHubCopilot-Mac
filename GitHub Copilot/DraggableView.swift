//
//  DraggableView.swift
//  GitHub Copilot
//
//  Created by Felix Lapalme on 2025-02-09.
//

import Cocoa

/** A view that can be used to drag the window around. */
class DraggableView: NSView {
    override func mouseDown(with event: NSEvent) {
        self.window?.performDrag(with: event)
    }
}
