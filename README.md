# Voice Assistant for macOS

Native macOS Voice Assistant mit lokaler Spracherkennung (WhisperKit), Waveform-Overlay und n8n Webhook-Integration.

**Basiert auf [Super Voice Assistant](https://github.com/ykdojo/super-voice-assistant) von ykdojo.**

## Features

- **2x Ctrl** - Aufnahme starten/stoppen (wie gewohnt)
- **Lokale Transkription** - WhisperKit mit Deutsch voreingestellt
- **Waveform-Overlay** - Animierte Audio-Balken unten mittig
- **Sound-Feedback** - Glass.aiff beim Start, Tink.aiff beim Stop
- **Zwischenablage** - Transkript bleibt in der Ablage verfügbar
- **n8n Webhooks** - Integration mit Bruce/Nexa Assistenten
- **Menu Bar App** - Läuft diskret in der Menüleiste

## Schnell-Installation

```bash
# 1. Repository klonen
git clone https://github.com/Kre8ive-Evolution/LocalVoiceTranscriber.git
cd LocalVoiceTranscriber

# 2. App bauen
swift build

# 3. Whisper-Modell herunterladen (Large v3 Turbo - 99 Sprachen)
.build/debug/TestDownload 2

# 4. App starten
.build/debug/SuperVoiceAssistant
```

## Berechtigungen einrichten

Die App benötigt folgende Berechtigungen in **Systemeinstellungen > Datenschutz & Sicherheit**:

### 1. Mikrofon
- Systemeinstellungen > Datenschutz & Sicherheit > Mikrofon
- Terminal (oder die App) hinzufügen

### 2. Bedienungshilfen (Accessibility)
- Systemeinstellungen > Datenschutz & Sicherheit > Bedienungshilfen
- Terminal hinzufügen (für 2x Ctrl Hotkey)

### 3. Eingabeüberwachung (Input Monitoring)
- Systemeinstellungen > Datenschutz & Sicherheit > Eingabeüberwachung
- Terminal hinzufügen

**Tipp:** Nach dem Hinzufügen Terminal neu starten.

## Verwendung

| Aktion | Tastenkürzel |
|--------|--------------|
| Aufnahme starten | 2x Ctrl schnell drücken |
| Aufnahme stoppen | 1x Ctrl drücken |
| Abbrechen | Escape |

### Webhook-Integration (Bruce/Nexa)

Wenn das Transkript "Bruce" oder "Nexa" enthält, wird es automatisch an den entsprechenden n8n Webhook gesendet:

- `http://localhost:5678/webhook/bruce`
- `http://localhost:5678/webhook/nexa`

Die Antwort wird in die Zwischenablage kopiert und eingefügt.

## Konfiguration

### Webhook URLs ändern

Bearbeite `Sources/WebhookHandler.swift`:

```swift
private let nexaURL = "http://localhost:5678/webhook/nexa"
private let bruceURL = "http://localhost:5678/webhook/bruce"
```

### Sprache ändern

Bearbeite `Sources/AudioTranscriptionManager.swift` (Zeile ~305):

```swift
language: "de",  // German -> "en" für Englisch
```

### Verfügbare Whisper-Modelle

```bash
.build/debug/ListModels
```

| Modell | Größe | Sprachen | Geschwindigkeit |
|--------|-------|----------|-----------------|
| 1. Distil Large v3 | 756 MB | Nur Englisch | 6.3x schneller |
| 2. Large v3 Turbo | 809 MB | 99 Sprachen | 8x schneller |
| 3. Large v3 | 1.54 GB | 99 Sprachen | Beste Qualität |

## Systemanforderungen

- macOS 14.0 (Sonoma) oder neuer
- Apple Silicon (M1/M2/M3) empfohlen
- ~1-2 GB Speicherplatz für Whisper-Modell

## Troubleshooting

### App reagiert nicht auf 2x Ctrl
- Bedienungshilfen-Berechtigung für Terminal prüfen
- Terminal neu starten

### Kein Ton bei Aufnahme
- Mikrofon-Berechtigung prüfen
- Richtiges Mikrofon in Systemeinstellungen > Ton > Eingabe auswählen

### Overlay erscheint nicht
- App beenden und neu starten: `pkill -f SuperVoiceAssistant`

### Transkription auf Englisch statt Deutsch
- Falsches Modell: Distil ist nur Englisch
- Large v3 Turbo herunterladen: `.build/debug/TestDownload 2`

## App beenden

- Klick auf Waveform-Symbol in Menüleiste → "Quit"
- Oder: `pkill -f SuperVoiceAssistant`

## Anpassungen (Kre8ive Evolution)

Diese Version enthält folgende Anpassungen:

1. **DoubleTapCtrlDetector.swift** - 2x Ctrl für Start, 1x Ctrl für Stop
2. **WebhookHandler.swift** - n8n Integration für Bruce/Nexa
3. **SoundPlayer.swift** - System-Sounds für Feedback
4. **WaveformOverlay.swift** - Animiertes Overlay unten mittig
5. **AudioTranscriptionManager.swift** - Deutsch voreingestellt
6. **main.swift** - Alle Integrationen zusammengeführt

## Lizenz

MIT License - siehe [LICENSE](LICENSE)

## Credits

- Original: [Super Voice Assistant](https://github.com/ykdojo/super-voice-assistant) by ykdojo
- WhisperKit: [argmaxinc/WhisperKit](https://github.com/argmaxinc/WhisperKit)
- Anpassungen: Kre8ive Evolution
