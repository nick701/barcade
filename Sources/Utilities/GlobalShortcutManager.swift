import Carbon.HIToolbox
import Foundation

struct ShortcutDefinition: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
}

final class GlobalShortcutManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var action: (() -> Void)?

    init() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            Self.hotKeyHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }

    deinit {
        unregister()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    @discardableResult
    func register(shortcut: String, action: @escaping () -> Void) -> Bool {
        unregister()
        guard let definition = Self.definition(for: shortcut) else {
            return false
        }

        let hotKeyID = EventHotKeyID(
            signature: OSType(0x42415243),
            id: 1
        )
        let result = RegisterEventHotKey(
            definition.keyCode,
            definition.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard result == noErr else {
            hotKeyRef = nil
            return false
        }
        self.action = action
        return true
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nil
        action = nil
    }

    static func definition(for shortcut: String) -> ShortcutDefinition? {
        let normalized = shortcut
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
        guard let character = normalized.last,
              let keyCode = keyCodes[character] else {
            return nil
        }

        var modifiers: UInt32 = 0
        if normalized.contains("⌘") {
            modifiers |= UInt32(cmdKey)
        }
        if normalized.contains("⌥") {
            modifiers |= UInt32(optionKey)
        }
        if normalized.contains("⌃") {
            modifiers |= UInt32(controlKey)
        }
        if normalized.contains("⇧") {
            modifiers |= UInt32(shiftKey)
        }

        guard modifiers != 0 else {
            return nil
        }
        return ShortcutDefinition(keyCode: keyCode, modifiers: modifiers)
    }

    private static let hotKeyHandler: EventHandlerUPP = {
        _,
        _,
        userData in
        guard let userData else {
            return OSStatus(eventNotHandledErr)
        }
        let manager = Unmanaged<GlobalShortcutManager>
            .fromOpaque(userData)
            .takeUnretainedValue()
        manager.action?()
        return noErr
    }

    private static let keyCodes: [Character: UInt32] = [
        "A": UInt32(kVK_ANSI_A),
        "B": UInt32(kVK_ANSI_B),
        "C": UInt32(kVK_ANSI_C),
        "D": UInt32(kVK_ANSI_D),
        "E": UInt32(kVK_ANSI_E),
        "F": UInt32(kVK_ANSI_F),
        "G": UInt32(kVK_ANSI_G),
        "H": UInt32(kVK_ANSI_H),
        "I": UInt32(kVK_ANSI_I),
        "J": UInt32(kVK_ANSI_J),
        "K": UInt32(kVK_ANSI_K),
        "L": UInt32(kVK_ANSI_L),
        "M": UInt32(kVK_ANSI_M),
        "N": UInt32(kVK_ANSI_N),
        "O": UInt32(kVK_ANSI_O),
        "P": UInt32(kVK_ANSI_P),
        "Q": UInt32(kVK_ANSI_Q),
        "R": UInt32(kVK_ANSI_R),
        "S": UInt32(kVK_ANSI_S),
        "T": UInt32(kVK_ANSI_T),
        "U": UInt32(kVK_ANSI_U),
        "V": UInt32(kVK_ANSI_V),
        "W": UInt32(kVK_ANSI_W),
        "X": UInt32(kVK_ANSI_X),
        "Y": UInt32(kVK_ANSI_Y),
        "Z": UInt32(kVK_ANSI_Z),
        "0": UInt32(kVK_ANSI_0),
        "1": UInt32(kVK_ANSI_1),
        "2": UInt32(kVK_ANSI_2),
        "3": UInt32(kVK_ANSI_3),
        "4": UInt32(kVK_ANSI_4),
        "5": UInt32(kVK_ANSI_5),
        "6": UInt32(kVK_ANSI_6),
        "7": UInt32(kVK_ANSI_7),
        "8": UInt32(kVK_ANSI_8),
        "9": UInt32(kVK_ANSI_9)
    ]
}
