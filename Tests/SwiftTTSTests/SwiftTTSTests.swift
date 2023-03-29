#if os(macOS)
#error("This library is not compatible with macOS")
#endif

import AVFoundation
import SwiftTTS
import XCTest

@MainActor
final class SwiftTTSTests: XCTestCase {
    func testLiveTTSWithoutCrashing() async {
        let tts = SwiftTTS.live
        tts.speak("Let's test that!")
    }

    func testTTSRateRatio() {
        let tts = SwiftTTS.live
        XCTAssertEqual(tts.rateRatio(), 1.0)
        tts.setRateRatio(0.5)
        XCTAssertEqual(tts.rateRatio(), 0.5)
    }

    func testTTSVoice() throws {
        let tts = SwiftTTS.live
        let britishVoice = try XCTUnwrap(AVSpeechSynthesisVoice(language: "en-GB"))
        let frenchVoice = try XCTUnwrap(AVSpeechSynthesisVoice(language: "fr-FR"))

        XCTAssertEqual(tts.voice(), britishVoice)
        tts.setVoice(frenchVoice)
        XCTAssertEqual(tts.voice(), frenchVoice)
    }

    func testTTSSpeak() {
        let tts = SwiftTTS.live

        let isSpeakingExpectation = expectation(description: "Expect is speaking to be true")
        let hasStoppedSpeakingExpectation = expectation(description: "Expect is speaking to be false after speaking")

        Task {
            var hasSpoken = false
            for await isSpeaking in tts.isSpeaking() {
                if isSpeaking {
                    hasSpoken = true
                    isSpeakingExpectation.fulfill()
                }

                if hasSpoken && !isSpeaking {
                    hasStoppedSpeakingExpectation.fulfill()
                }
            }
        }

        let isProgressZeroExpectation = expectation(description: "Expect progress to start at 0.0")
        let isProgressReachHalfExpectation = expectation(description: "Expect progress to be greater than at 0.5")
        let isProgressFinishCompletelyExpectation = expectation(description: "Expect progress to finish at 1.0")

        Task {
            for await progress in tts.speakingProgress() {
                if progress == 0.0 {
                    isProgressZeroExpectation.fulfill()
                }
                if progress > 0.5 && progress < 1.0 {
                    isProgressReachHalfExpectation.fulfill()
                }
                if progress == 1.0 {
                    isProgressFinishCompletelyExpectation.fulfill()
                }
            }
        }

        tts.speak("It's a test!")

        wait(
            for: [
                isSpeakingExpectation,
                hasStoppedSpeakingExpectation,
                isProgressZeroExpectation,
                isProgressReachHalfExpectation,
                isProgressFinishCompletelyExpectation
            ],
            timeout: 2.0
        )
    }
}
