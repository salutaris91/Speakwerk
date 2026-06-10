import Carbon
import AppKit
import os

// Helper function to create FourCharCode from a 4-character string
func makeFourCharCode(_ string: String) -> FourCharCode {
    var result: FourCharCode = 0
    guard string.utf8.count == 4 else { return 0 }
    for char in string.utf8 {
        result = (result << 8) + FourCharCode(char)
    }
    return result
}

// Global C-style callback for Carbon Hotkeys
private let handlerCallback: EventHandlerProcPtr = { (nextHandler, event, userData) -> OSStatus in
    MainActor.assumeIsolated {
        HotkeyManager.shared.trigger()
    }
    return noErr
}

@MainActor
class HotkeyManager {
    static let shared = HotkeyManager()
    
    private let logger = Logger(subsystem: "com.alex.Speakwerk", category: "HotkeyManager")
    private var hotkeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var onTrigger: (@MainActor () -> Void)?
    
    func register(keyCode: UInt32, carbonModifiers: UInt32, onTrigger: @escaping @MainActor () -> Void) -> Bool {
        self.onTrigger = onTrigger
        
        // 1. Install application event handler for hotkeys
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        var handlerRef: EventHandlerRef?
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            handlerCallback,
            1,
            &eventType,
            nil,
            &handlerRef
        )
        
        guard status == noErr else {
            logger.error("Failed to install Carbon event handler: \(status)")
            return false
        }
        self.eventHandlerRef = handlerRef
        
        // 2. Define unique Hotkey ID
        let hotkeyID = EventHotKeyID(signature: makeFourCharCode("SWRK"), id: 1)
        
        // 3. Register hotkey
        var keyRef: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &keyRef
        )
        
        guard registerStatus == noErr else {
            logger.error("Failed to register global hotkey: \(registerStatus)")
            unregister()
            return false
        }
        
        self.hotkeyRef = keyRef
        logger.info("Successfully registered global hotkey (Keycode: \(keyCode))")
        return true
    }
    
    func trigger() {
        onTrigger?()
    }
    
    func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
        logger.info("Unregistered global hotkey and event handler")
    }
}
