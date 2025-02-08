import Cocoa

class PopupWindow: NSWindow {
    public lazy var textField: CustomTextField = {
        let textField = CustomTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.appearance = NSAppearance(named: .vibrantDark)
        textField.drawsBackground = false
        return textField
    }()
    
    public lazy var logoImageView: NSImageView = {
        let logoImage = NSImage(named: "gh_copilot")
        let imageView = NSImageView(frame: NSRect(x: 20, y: 20, width: 20, height: 20))
        imageView.image = logoImage
        imageView.imageScaling = .scaleProportionallyUpOrDown
        return imageView
    }()
    
    init() {
        // Create a rect in the middle of the screen
        let screenSize = NSScreen.main?.frame ?? .zero
        let windowSize = NSSize(width: 600, height: 65)
        let x = (screenSize.width - windowSize.width) / 2
        let y = (screenSize.height - windowSize.height) / 2
        let frame = NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height)

        let font = NSFont.systemFont(ofSize: 24, weight: .regular)

        let topPadding: CGFloat = 10
        let bottomPadding: CGFloat = 10

        
        // Create stack view for layout
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 12
        stackView.edgeInsets = NSEdgeInsets(top: topPadding, left: 20, bottom: bottomPadding, right: 20)
        stackView.distribution = .fill
        
        // Configure text field without frame
        
        super.init(contentRect: frame,
                  styleMask: [.borderless, .nonactivatingPanel],
                  backing: .buffered,
                  defer: false)
        
        // Configure window properties
        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.isReleasedWhenClosed = false
        self.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        self.isMovable = true
        
        // Enable layer-backing for the window
        self.contentView?.wantsLayer = true
        
        // Setup auto layout
        stackView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set logo size constraints
        NSLayoutConstraint.activate([
            logoImageView.widthAnchor.constraint(equalToConstant: 35),
            logoImageView.heightAnchor.constraint(equalToConstant: 35)
        ])
        
        // Create a visual effect view for blur
        let blurView = NSVisualEffectView(frame: self.contentView!.bounds)

        // force dark mode
        blurView.appearance = NSAppearance(named: .vibrantDark)

        blurView.blendingMode = .behindWindow
        blurView.material = .hudWindow
        blurView.state = .active
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = 18
        blurView.layer?.cornerCurve = .continuous
        blurView.layer?.masksToBounds = true
        blurView.layer?.borderWidth = 1
        blurView.layer?.borderColor = NSColor(white: 0, alpha: 0.3).cgColor
        blurView.autoresizingMask = [.width, .height]
        
        // Create the border view
        let onePixel = 1.0 / self.backingScaleFactor

        let borderView = NSView(frame: NSInsetRect(self.contentView!.bounds, onePixel, onePixel))
        borderView.wantsLayer = true
        borderView.layer?.borderWidth = 1
        borderView.layer?.borderColor = NSColor(white: 1, alpha: 0.3).cgColor
        borderView.layer?.cornerRadius = 17
        borderView.layer?.cornerCurve = .continuous
        borderView.autoresizingMask = [.width, .height]
        
        // Create a container view for the rounded corners
        let containerView = NSView(frame: self.contentView!.bounds)
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 18
        containerView.layer?.cornerCurve = .continuous
        containerView.layer?.masksToBounds = true
        containerView.autoresizingMask = [.width, .height]
        
        // Add views in the correct order
        containerView.addSubview(blurView)
        containerView.addSubview(borderView)
        
        // Add views to stack view
        stackView.addArrangedSubview(logoImageView)
        stackView.addArrangedSubview(textField)

        logoImageView.contentTintColor = .white

        // Configure the text field
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.isBezeled = false
        textField.isEditable = true
        textField.font = font
        textField.focusRingType = .none
        textField.usesSingleLineMode = true
        textField.maximumNumberOfLines = 1
        let placeholderText = "Ask Copilot"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor(white: 1, alpha: 0.5),
            .font: font
        ]
        textField.placeholderAttributedString = NSAttributedString(string: placeholderText, attributes: attributes)

        // Add stack view to container
        containerView.addSubview(stackView)
        self.contentView?.addSubview(containerView)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Setup stack view constraints
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    func show() {
        textField.stringValue = ""
        
        // Temporarily add titled style mask (Snap's technique)
        self.styleMask.insert(.titled)
        
        // Activate app while preserving window focus
        NSApp.activate(ignoringOtherApps: true)
        
        // Show window
        self.center()
        self.makeKeyAndOrderFront(nil)
        
        // Remove the titled style mask after window is shown
        self.styleMask.remove(.titled)
        
        // Configure field editor
        if let fieldEditor = self.fieldEditor(true, for: textField) as? NSTextView {
            fieldEditor.isFieldEditor = true
        }
        
        // Force focus on text field
        self.makeFirstResponder(textField)
    }
    
    @objc private func focusWindow() {
        self.makeKeyAndOrderFront(nil)
        self.makeFirstResponder(self.textField)
        _ = self.textField.becomeFirstResponder()
    }

    
    override func resignKey() {
        super.resignKey()
        self.orderOut(nil)
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
