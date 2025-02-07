import Cocoa

class CustomTextField: NSTextField {
    override func cancelOperation(_ sender: Any?) {
        // This will be called when escape is pressed
        window?.orderOut(nil)
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        return result
    }
}