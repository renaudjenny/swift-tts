#if os(macOS)
#error("This library is not compatible with macOS")
#endif

import AVFoundation
import Dependencies
import SwiftTTS
import XCTestDynamicOverlay

extension SwiftTTS {
    static let test = Self(
        rateRatio: unimplemented("SwiftTTS.rateRatio"),
        setRateRatio: unimplemented("SwiftTTS.setRateRatio"),
        voice: unimplemented("SwiftTTS.voice"),
        setVoice: unimplemented("SwiftTTS.setVoice"),
        speak: unimplemented("SwiftTTS.speak"),
        isSpeaking: unimplemented("SwiftTTS.isSpeaking"),
        speakingProgress: unimplemented("SwiftTTS.speakingProgress")
    )
    static let preview = {
        var speakingCallbacks: [() -> Void] = []
        let speak: (String) -> Void = {
            print("Spoken utterance: \($0)")
            for callback in speakingCallbacks {
                callback()
            }
        }

        let isSpeaking = AsyncStream { continuation in
            speakingCallbacks.append {
                continuation.yield(true)
                Task {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    continuation.yield(false)
                }
            }
        }

        let speakingProgress = AsyncStream { continuation in
            speakingCallbacks.append {
                Task {
                    for seconds in 0...4 {
                        continuation.yield(Double(seconds) / 4)
                        try await Task.sleep(nanoseconds: 500_000_000)
                    }
                }
            }
        }

        return Self(
            rateRatio: { 1.0 },
            setRateRatio: { _ in },
            voice: { AVSpeechSynthesisVoice(language: "en-GB") },
            setVoice: { _ in },
            speak: speak,
            isSpeaking: { isSpeaking },
            speakingProgress: { speakingProgress }
        )
    }()
}

private enum SwiftTTSDependencyKey: DependencyKey {
    static let liveValue = SwiftTTS.live
    static let testValue = SwiftTTS.test
    static let previewValue = SwiftTTS.preview
}

public extension DependencyValues {
    var tts: SwiftTTS {
        get { self[SwiftTTSDependencyKey.self] }
        set { self[SwiftTTSDependencyKey.self] = newValue }
    }
}
