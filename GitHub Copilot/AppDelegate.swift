//
//  AppDelegate.swift
//  GitHub Copilot
//
//  Created by Felix Lapalme on 2025-01-16.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var preferencesWindow: PreferencesWindow?
    private var viewController: ViewController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Get the view controller reference
        if let window = NSApplication.shared.windows.first,
           let viewController = window.contentViewController as? ViewController {
            self.viewController = viewController
        }
    }
    
    @IBAction func showPreferences(_ sender: Any) {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindow()
            
            // Set up hotkey change handler
            preferencesWindow?.onHotKeyChange = { [weak self] key, modifiers in
                // Convert NSEvent.ModifierFlags to HotKey.ModifierFlags
                var hotKeyModifiers: NSEvent.ModifierFlags = []
                if modifiers.contains(.command) { hotKeyModifiers.insert(.command) }
                if modifiers.contains(.option) { hotKeyModifiers.insert(.option) }
                if modifiers.contains(.control) { hotKeyModifiers.insert(.control) }
                if modifiers.contains(.shift) { hotKeyModifiers.insert(.shift) }
                
                // Update the hotkey
                self?.viewController?.updateHotKey(key: key, modifiers: hotKeyModifiers)
                
                // Save to UserDefaults
                UserDefaults.standard.set(key.carbonKeyCode, forKey: "HotKeyCode")
                UserDefaults.standard.set(modifiers.rawValue, forKey: "HotKeyModifiers")
            }
        }
        
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up if needed
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

