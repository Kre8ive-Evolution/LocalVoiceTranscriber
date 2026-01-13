import Cocoa
import Carbon.HIToolbox

/// Detects double-tap Ctrl (like LocalVoiceTranscriber)
/// Double-tap Ctrl = Start recording
/// Single Ctrl (while recording) = Stop recording
class DoubleTapCtrlDetector {
    static let shared = DoubleTapCtrlDetector()

    private var lastCtrlPressTime: Date?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // Callbacks
    var onDoubleTapCtrl: (() -> Void)?
    var onSingleCtrl: (() -> Void)?

    // Double-tap threshold (300ms)
    private let doubleTapThreshold: TimeInterval = 0.3

    private init() {}

    func start() {
        guard eventTap == nil else { return }

        // Create event tap for key events
        let eventMask = (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let detector = Unmanaged<DoubleTapCtrlDetector>.fromOpaque(refcon).takeUnretainedValue()
                detector.handleFlagsChanged(event)
                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("⚠️ Failed to create event tap. Grant Accessibility permission.")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            print("✅ Double-tap Ctrl detector started")
        }
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        print("🛑 Double-tap Ctrl detector stopped")
    }

    private func handleFlagsChanged(_ event: CGEvent) {
        let flags = event.flags

        // Check if Ctrl was pressed (not released)
        let ctrlPressed = flags.contains(.maskControl)

        if ctrlPressed {
            let now = Date()

            if let lastPress = lastCtrlPressTime {
                let elapsed = now.timeIntervalSince(lastPress)

                if elapsed < doubleTapThreshold {
                    // Double-tap detected!
                    print("🎤 Double-tap Ctrl detected!")
                    lastCtrlPressTime = nil
                    DispatchQueue.main.async {
                        self.onDoubleTapCtrl?()
                    }
                    return
                }
            }

            lastCtrlPressTime = now

            // Schedule single-tap check
            DispatchQueue.main.asyncAfter(deadline: .now() + doubleTapThreshold + 0.05) { [weak self] in
                guard let self = self else { return }
                // If lastCtrlPressTime wasn't cleared, it was a single tap
                if self.lastCtrlPressTime != nil {
                    print("👆 Single Ctrl detected")
                    self.lastCtrlPressTime = nil
                    self.onSingleCtrl?()
                }
            }
        }
    }
}
