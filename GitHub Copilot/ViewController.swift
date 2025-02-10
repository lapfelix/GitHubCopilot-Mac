import Cocoa
import WebKit
import HotKey

class ViewController: NSViewController, NSTextFieldDelegate, WKNavigationDelegate {
    var webView: WKWebView!
    private var hotKey: HotKey?
    private var popupWindow: PopupWindow? = nil

    private lazy var leftHeaderGrabView: NSView = {
        let view = DraggableView(frame: NSRect(x: 0, y: self.view.frame.height - self.view.safeAreaInsets.top, width: 78, height: 55))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.blue.withAlphaComponent(0.5).cgColor
        return view
    }()
    private var middleHeaderGrabView: NSView?
    
    // Base URL for GitHub Copilot chat
    private static let copilotChatURL = "https://github.com/copilot"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create and configure the WKWebView with script messaging
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        config.userContentController = userContentController

        let yOffset: CGFloat = 0.0
        let offsetBounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height - yOffset)
        webView = WKWebView(frame: offsetBounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        self.view.addSubview(webView)

        // Add leftHeaderGrabView to the view (lazy initialization will create it)
        self.view.addSubview(leftHeaderGrabView)

        // Set WKNavigationDelegate to self
        webView.navigationDelegate = self
        
        // Make titlebar transparent and allow content to extend into it
        self.view.window?.titlebarAppearsTransparent = true
        self.view.window?.titleVisibility = .hidden
        self.view.window?.isMovableByWindowBackground = true

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

        // Observe the underPageBackgroundColor to keep self.view's background in sync
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.underPageBackgroundColor), options: [.new], context: nil)
    }

    override func viewWillLayout() {
        super.viewWillLayout()
        leftHeaderGrabView.frame = NSRect(x: 0,
                                          y: self.view.frame.height - self.view.safeAreaInsets.top,
                                          width: 78,
                                          height: 55)
        updateHeaderGrabbableViewFrame()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == #keyPath(WKWebView.underPageBackgroundColor) else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        updateBackgroundColor()
    }

    func updateBackgroundColor() {
        // Check if the view controller is using light mode
        var isUsingLightMode = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua

        // if we can get the lightness of the underPageBackgroundColor, use it to determine if we should use light mode
        if let lightness = webView.underPageBackgroundColor.usingColorSpace(.deviceRGB)?.brightnessComponent {
            isUsingLightMode = lightness > 0.5
        }

        if isUsingLightMode {
            self.view.layer?.backgroundColor = CGColor(red: 246.0/255.0, green: 248.0/255.0, blue: 250.0/255.0, alpha: 1)
        } else {
            self.view.layer?.backgroundColor = CGColor(red: 1.0/255.0, green: 4.0/255.0, blue: 9.0/255.0, alpha: 1)
        }
    }

    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.underPageBackgroundColor))
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        self.view.window?.title = ""
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

    func modifyHeader() {
        // so it's more compact and we can fit the controls on the left
        let script = """
        {
            const element = document.querySelector('.AppHeader-globalBar-start');
            if (element) {
                element.style.setProperty('margin-left', '70px', 'important');
            }

            // <div class="AppHeader-globalBar  js-global-bar" style="padding-top: 5px !important; padding-bottom: 5px !important;">
            const element2 = document.querySelector('.AppHeader-globalBar');
            if (element2) {
                element2.style.setProperty('padding-top', '11px', 'important');
                element2.style.setProperty('padding-bottom', '11px', 'important');
            }
        }
        """
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript error: \(error)")
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateBackgroundColor()
        modifyHeader()
        updateHeaderGrabbableViewFrame()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        updateBackgroundColor()
        modifyHeader()
    }

    func updateHeaderGrabbableViewFrame() {
        let script = """
            {
                let rectObj = null;
                const headerElement = document.querySelector('.AppHeader-context-full');
                if (headerElement) {
                    const rect = headerElement.getBoundingClientRect();
                    rectObj = { x: rect.x, y: rect.y, width: rect.width, height: rect.height };
                }
                rectObj;
            }
            """
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript error: \(error)")
            }
            if let result = result as? [String: Any],
               let x = result["x"] as? CGFloat,
               let width = result["width"] as? CGFloat {
                // Use fixed y and height
                let frame = NSRect(x: x,
                                   y: self.view.frame.height - self.view.safeAreaInsets.top,
                                   width: width,
                                   height: 55)
                if let middleView = self.middleHeaderGrabView {
                    middleView.frame = frame
                } else {
                    // Use DraggableView for middleHeaderGrabView as well.
                    let middleView = DraggableView(frame: frame)
                    middleView.wantsLayer = true
                    middleView.layer?.backgroundColor = NSColor.red.withAlphaComponent(0.5).cgColor
                    self.view.addSubview(middleView)
                    self.middleHeaderGrabView = middleView
                }
            }
        }
    }
}
