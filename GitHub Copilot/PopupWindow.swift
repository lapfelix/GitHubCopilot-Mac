import Cocoa

class PopupWindow: NSWindow {
    public let textField: CustomTextField
    
    init() {
        // Create a rect in the middle of the screen
        let screenSize = NSScreen.main?.frame ?? .zero
        let windowSize = NSSize(width: 400, height: 60)
        let x = (screenSize.width - windowSize.width) / 2
        let y = (screenSize.height - windowSize.height) / 2
        let frame = NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height)
        
        self.textField = CustomTextField(frame: NSRect(x: 10, y: 10, width: windowSize.width - 20, height: 40))
        super.init(contentRect: frame,
                  styleMask: [.borderless],
                  backing: .buffered,
                  defer: false)
        
        self.level = .floating
        self.backgroundColor = NSColor.black.withAlphaComponent(0.8)
        self.isOpaque = false
        self.hasShadow = true
        self.isReleasedWhenClosed = false
        self.contentView?.layer?.cornerCurve = .continuous
        self.contentView?.layer?.cornerRadius = 18

        // Configure the text field
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.isBezeled = false
        textField.isEditable = true
        textField.font = NSFont.systemFont(ofSize: 24)
        textField.focusRingType = .none
        
        self.contentView?.addSubview(textField)
        //self.makeKey()
    }
    
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    func show() {
        DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
            NSApp.activate(ignoringOtherApps: true)
            self?.orderFrontRegardless()
            self?.makeKey()
            self?.textField.stringValue = ""
            self?.makeFirstResponder(self?.textField)
            _ = self?.textField.becomeFirstResponder()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.makeKeyAndOrderFront(nil)
            self.makeFirstResponder(self.textField)
        }

    }

    override func keyDown(with event: NSEvent) {
        // Dismiss when pressing escape
        if event.keyCode == 53 {
            self.orderOut(nil)
        } else {
            super.keyDown(with: event)
        }
    }
}
