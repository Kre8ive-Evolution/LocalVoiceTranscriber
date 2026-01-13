import AppKit
import Foundation

/// Floating overlay window that shows animated waveform bars during recording
class WaveformOverlay {
    static let shared = WaveformOverlay()

    private var window: NSWindow?
    private var waveformView: WaveformView?
    private var animationTimer: Timer?
    private var isShowing = false

    // Audio level for animation
    private var currentAudioLevel: Float = 0.0

    private init() {
        // Pre-create window on init for faster show
        DispatchQueue.main.async { [weak self] in
            self?.createWindow()
        }
    }

    /// Show the overlay at bottom center (thread-safe)
    func show() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard !self.isShowing else { return }  // Check on main thread
            self.isShowing = true
            self.window?.orderFront(nil)
            self.startAnimation()
        }
    }

    /// Hide the overlay (thread-safe)
    func hide() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard self.isShowing else { return }  // Check on main thread
            self.isShowing = false
            self.stopAnimation()
            self.window?.orderOut(nil)
        }
    }

    /// Check if overlay is currently visible
    var isCurrentlyShowing: Bool {
        return isShowing
    }

    /// Update with audio level (dB value, typically -60 to 0)
    func updateAudioLevel(_ db: Float) {
        // Normalize dB to 0-1 range (-60dB = 0, 0dB = 1)
        let normalized = max(0, min(1, (db + 60) / 60))
        currentAudioLevel = normalized
    }

    private func createWindow() {
        guard window == nil else { return }

        // Get main screen dimensions
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame

        // Overlay dimensions
        let overlayWidth: CGFloat = 200
        let overlayHeight: CGFloat = 60

        // Position at bottom center
        let x = (screenFrame.width - overlayWidth) / 2
        let y: CGFloat = 80

        let frame = NSRect(x: x, y: y, width: overlayWidth, height: overlayHeight)

        // Create borderless, floating window
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = NSColor.clear
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hasShadow = false
        panel.ignoresMouseEvents = true

        // Create waveform view
        let contentFrame = NSRect(x: 0, y: 0, width: overlayWidth, height: overlayHeight)
        let waveform = WaveformView(frame: contentFrame)
        panel.contentView = waveform

        self.window = panel
        self.waveformView = waveform
    }

    private func startAnimation() {
        // Stop existing timer first
        animationTimer?.invalidate()

        // Create new timer on main run loop
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/24.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isShowing else { return }
            self.waveformView?.audioLevel = self.currentAudioLevel
            self.waveformView?.needsDisplay = true
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        currentAudioLevel = 0
        waveformView?.audioLevel = 0
    }
}


/// Custom view that draws animated waveform bars
class WaveformView: NSView {

    var audioLevel: Float = 0.0
    private let barCount = 9
    private var barHeights: [CGFloat]
    private var targetHeights: [CGFloat]

    override init(frame frameRect: NSRect) {
        barHeights = Array(repeating: 0.2, count: barCount)
        targetHeights = Array(repeating: 0.2, count: barCount)
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        barHeights = Array(repeating: 0.2, count: 9)
        targetHeights = Array(repeating: 0.2, count: 9)
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Clear background
        NSColor.clear.setFill()
        dirtyRect.fill()

        // Draw rounded background
        let bgPath = NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12)
        NSColor(white: 0.1, alpha: 0.85).setFill()
        bgPath.fill()

        // Calculate bar dimensions
        let barWidth: CGFloat = 8
        let barSpacing: CGFloat = 6
        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
        let startX = (bounds.width - totalWidth) / 2
        let maxBarHeight = bounds.height - 20
        let minBarHeight: CGFloat = 8
        let centerY = bounds.height / 2

        // Update target heights based on audio level
        updateTargetHeights()

        // Smooth animation towards target
        for i in 0..<barCount {
            barHeights[i] += (targetHeights[i] - barHeights[i]) * 0.25
        }

        // Draw bars - cyan color
        let barColor = NSColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)

        for i in 0..<barCount {
            let x = startX + CGFloat(i) * (barWidth + barSpacing)
            let barHeight = minBarHeight + (maxBarHeight - minBarHeight) * barHeights[i]
            let y = centerY - barHeight / 2

            let barRect = NSRect(x: x, y: y, width: barWidth, height: barHeight)
            let barPath = NSBezierPath(roundedRect: barRect, xRadius: barWidth/2, yRadius: barWidth/2)
            barColor.setFill()
            barPath.fill()
        }
    }

    private func updateTargetHeights() {
        let baseLevel = CGFloat(audioLevel)

        for i in 0..<barCount {
            // Middle bars taller, edges shorter
            let distanceFromCenter = abs(CGFloat(i) - CGFloat(barCount - 1) / 2)
            let centerFactor = 1.0 - (distanceFromCenter / (CGFloat(barCount) / 2)) * 0.5

            // Slight randomness for natural look
            let randomFactor = CGFloat.random(in: 0.9...1.1)

            var height = baseLevel * centerFactor * randomFactor
            height = max(0.1, min(1.0, height))

            // Idle animation when quiet
            if audioLevel < 0.05 {
                height = 0.15 + CGFloat.random(in: -0.03...0.03)
            }

            targetHeights[i] = height
        }
    }
}
