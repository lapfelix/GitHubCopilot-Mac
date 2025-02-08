import Cocoa
import WebKit
import HotKey

class ViewController: NSViewController, NSTextFieldDelegate {
    var webView: WKWebView!
    private var hotKey: HotKey?
    private var popupWindow: PopupWindow? = nil
    
    // Base URL for GitHub Copilot chat
    private static let copilotChatURL = "https://github.com/copilot"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create and configure the WKWebView with script messaging
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        config.userContentController = userContentController

        webView = WKWebView(frame: self.view.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        self.view.addSubview(webView)

        // Load the default URL
        if let url = URL(string: Self.copilotChatURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        // Load saved hotkey or use default (⌘⌥L)
        let keyCode = UserDefaults.standard.integer(forKey: "HotKeyCode")
        let modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(UserDefaults.standard.integer(forKey: "HotKeyModifiers")))
        
        // Initialize hotkey if saved settings exist
        if let key = Key(carbonKeyCode: UInt32(keyCode)) {
            hotKey = HotKey(key: key, modifiers: modifierFlags)
            
            // Setup hotkey handler
            hotKey?.keyDownHandler = { [weak self] in
                self?.showPopup()
            }
        }
    }
    
    private func showPopup() {
        if popupWindow == nil {
            popupWindow = PopupWindow()
            popupWindow?.textField.delegate = self
        }
        popupWindow?.show()
    }
    
    // MARK: - NSTextFieldDelegate
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            // Handle Return key
            if let text = textView.string as String? {
                handleSubmittedText(text)
            }
            popupWindow?.orderOut(nil)
            self.view.window?.makeKeyAndOrderFront(nil)
            return true
        }
        return false
    }
    
    // Function to update hotkey configuration
    func updateHotKey(key: Key, modifiers: NSEvent.ModifierFlags) {
        // Remove existing hotkey
        hotKey = nil
        
        // Create new hotkey with new configuration
        hotKey = HotKey(key: key, modifiers: modifiers)
        
        // Setup handler
        hotKey?.keyDownHandler = { [weak self] in
            self?.showPopup()
        }
    }

    @IBAction func createNewChat(_ sender: Any) {
        // Navigate to the home URL
        if let url = URL(string: Self.copilotChatURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    private func handleSubmittedText(_ text: String) {
        // Inject JavaScript to fill in the Copilot textarea and submit
        let script = """
            const textarea = document.getElementById('copilot-chat-textarea');
            if (textarea) {
                // Focus the textarea first
                textarea.focus();
                
                // Set the value and trigger React's synthetic events
                const nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, "value").set;
                nativeInputValueSetter.call(textarea, \(text.debugDescription));
                
                // Trigger React's synthetic events
                textarea.dispatchEvent(new Event('input', { bubbles: true, composed: true }));
                
                // Update the preview element that React uses
                const preview = document.getElementById('copilot-chat-textarea-preview');
                if (preview) {
                    preview.textContent = \(text.debugDescription);
                }
                
                // Small delay to ensure React state is updated
                setTimeout(() => {
                    // Find and click the send button using the command ID we found in the source
                    const sendButton = document.querySelector('button[data-command-id="copilot-chat:send-message"]');
                    if (sendButton) {
                        sendButton.click();
                    }
                }, 400);
            }
        """
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript error: \(error)")
            }
        }
    }
}
