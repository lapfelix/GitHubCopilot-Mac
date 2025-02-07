import Cocoa
import HotKey

class PreferencesWindow: NSPanel {
    private var recordingHotKey = false
    private var currentModifiers: NSEvent.ModifierFlags = []
    private var currentKeyCode: UInt16 = 0
    private var recordField: NSTextField!
    var onHotKeyChange: ((Key, NSEvent.ModifierFlags) -> Void)?
    
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 400, height: 150),
                  styleMask: [.titled, .closable],
                  backing: .buffered,
                  defer: false)
        
        self.title = "Preferences"
        self.center()
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = true
        
        setupUI()
    }
    
    private func setupUI() {
        let contentView = NSView(frame: self.contentLayoutRect)
        self.contentView = contentView
        
        // Label
        let label = NSTextField(labelWithString: "Hotkey:")
        label.frame = NSRect(x: 20, y: 90, width: 60, height: 20)
        contentView.addSubview(label)
        
        // Hotkey recording field
        recordField = NSTextField(frame: NSRect(x: 90, y: 90, width: 290, height: 24))
        recordField.isEditable = false
        recordField.stringValue = "⌘⌥L"  // Default value
        recordField.backgroundColor = .controlBackgroundColor
        recordField.isBordered = true
        recordField.bezelStyle = .squareBezel
        
        // Add click handler to start recording
        recordField.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(startRecording(_:))))
        contentView.addSubview(recordField)
        
        // Description
        let description = NSTextField(wrappingLabelWithString: "Click the field above and press your desired key combination to change the hotkey.")
        description.frame = NSRect(x: 20, y: 40, width: 360, height: 40)
        description.textColor = .secondaryLabelColor
        contentView.addSubview(description)
    }
    
    @objc private func startRecording(_ sender: NSGestureRecognizer) {
        guard let field = sender.view as? NSTextField else { return }
        
        field.stringValue = "Recording..."
        recordingHotKey = true
        
        // Make window first responder to capture key events
        self.makeFirstResponder(self)
    }
    
    override func keyDown(with event: NSEvent) {
        guard recordingHotKey else {
            super.keyDown(with: event)
            return
        }
        
        // Store the key and modifiers
        currentKeyCode = event.keyCode
        currentModifiers = event.modifierFlags
        
        // Convert key code to Key type
        if let key = Key(carbonKeyCode: UInt32(currentKeyCode)) {
            // Update the text field
            recordField.stringValue = modifierFlagsToString(currentModifiers) + key.description
            
            // Notify the change
            onHotKeyChange?(key, currentModifiers)
        }
        
        recordingHotKey = false
    }
    
    private func modifierFlagsToString(_ flags: NSEvent.ModifierFlags) -> String {
        var str = ""
        if flags.contains(.command) { str += "⌘" }
        if flags.contains(.option) { str += "⌥" }
        if flags.contains(.control) { str += "⌃" }
        if flags.contains(.shift) { str += "⇧" }
        return str
    }
}
