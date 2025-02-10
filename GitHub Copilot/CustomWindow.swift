//
//  CustomWindow.swift
//  GitHub Copilot
//
//  Created by Felix Lapalme on 2025-02-09.
//

import Cocoa

extension NSView {
    func findSubview(withClassName name: String) -> NSView? {
        if self.className == name {
            return self
        }
        for subview in self.subviews {
            if let found = subview.findSubview(withClassName: name) {
                return found
            }
        }
        return nil
    }
}

class CustomWindow: NSWindow {

    override func sendEvent(_ event: NSEvent) {
        guard event.type == .leftMouseDown else {
            super.sendEvent(event)
            return
        }

        // Ugly hack to let clicks go through the toolbar
        // (all of this to get the nicer vertically aligned control buttons)
        let titlebarContainerView = contentView?.superview?
            .findSubview(withClassName: "NSToolbarTitleView")
        titlebarContainerView?.isHidden = true
        super.sendEvent(event)
        titlebarContainerView?.isHidden = false
    }
}
