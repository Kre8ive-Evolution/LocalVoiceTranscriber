import Foundation
import AppKit

/// Plays macOS system sounds for recording feedback
class SoundPlayer {
    static let shared = SoundPlayer()

    private init() {}

    /// Play recording start sound (Glass)
    func playStartSound() {
        playSystemSound("Glass")
    }

    /// Play recording stop sound (Tink)
    func playStopSound() {
        playSystemSound("Tink")
    }

    /// Play success sound (Purr)
    func playSuccessSound() {
        playSystemSound("Purr")
    }

    /// Play error sound (Basso)
    func playErrorSound() {
        playSystemSound("Basso")
    }

    /// Play a macOS system sound by name
    private func playSystemSound(_ name: String) {
        let soundPath = "/System/Library/Sounds/\(name).aiff"

        // Use Process for non-blocking playback
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
            process.arguments = [soundPath]

            do {
                try process.run()
                // Don't wait - let it play in background
            } catch {
                print("Failed to play sound \(name): \(error)")
            }
        }
    }
}
