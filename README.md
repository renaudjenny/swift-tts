# SwiftTTS

[![Swift Test](https://github.com/renaudjenny/swift-tts/actions/workflows/test.yml/badge.svg)](https://github.com/renaudjenny/swift-tts/actions/workflows/test.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Frenaudjenny%2Fswift-tts%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/renaudjenny/swift-tts)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Frenaudjenny%2Fswift-tts%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/renaudjenny/swift-tts)

This package contains some very straightforward wrappers around TTS part of AVFoundation/AVSpeechSynthesizer to allow you using Text to Speech with ease.

* `SwiftTTS` Using **Swift Concurrency** with `async` `await`, a couple of `AsyncStream`
* `SwiftTTSDependency` A wrapper around the library above facilitating the integration with [Point-Free Dependencies](https://github.com/pointfreeco/swift-dependencies) library or a project made with The Composable Architecture (TCA).
* `SwiftTTSCombine` the OG library still available in this package

## Modern concurrency usage

* `speak(String) -> Void` - call this method when you simply want to use the TTS with a simple String
  * `isSpeaking() -> AsyncStream<Bool>` - to know when the utterance starts to be heard, and when it's stopped
  * `speakingProgress() -> AsyncStream<Double>` - to know the progress, from 0 to 1
* `rateRatio() -> Float` - set the rate to slow down or accelerate the TTS engine
* `setRateRatio(Float) -> Void` - set the rate to slow down or accelerate the TTS engine
* `voice() -> AVSpeechSynthesisVoice?` - the voice of the TTS engine, by default, it's the voice for `en-GB`
* `setVoice(AVSpeechSynthesisVoice) -> Void` - set the voice of the TTS engine

### Example

```swift
import SwiftTTS

let tts = SwiftTTS.live

tts.speak("Hello World!")

Task {
    for await isSpeaking in tts.isSpeaking() {
        print("TTS is currently \(isSpeaking ? "speaking" : "not speaking")")
    }
}

Task {
    for await progress in tts.speakingProgress() {
        print("Progress: \(Int(progress * 100))%")
    }
}

tts.setRateRatio(3/4)

tts.speak("Hello World! But slower")
```

## [Point-Free Dependencies](https://github.com/pointfreeco/swift-dependencies) usage

Add `@Dependency(\.tts) var tts` in your `Reducer`, you will have access to all functions mentioned above.

### Example

```swift
import ComposableArchitecture
import Foundation
import SwiftTTSDependency

public struct TTS: ReducerProtocol {
    public struct State: Equatable {
        public var text = ""
        public var isSpeaking = false
        public var speakingProgress = 1.0
        public var rateRatio: Float = 1.0

        public init(
            text: String = "",
            isSpeaking: Bool = false,
            speakingProgress: Double = 1.0,
            rateRatio: Float = 1.0
        ) {
            self.text = text
            self.isSpeaking = isSpeaking
            self.speakingProgress = speakingProgress
            self.rateRatio = rateRatio
        }
    }

    public enum Action: Equatable {
        case changeRateRatio(Float)
        case speak
        case startSpeaking
        case stopSpeaking
        case changeSpeakingProgress(Double)
    }

    @Dependency(\.tts) var tts

    public init() {}

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case let .changeRateRatio(rateRatio):
                state.rateRatio = rateRatio
                tts.setRateRatio(rateRatio)
                return .none
            case .speak:
                tts.speak(state.text)
                return .run { send in
                    for await isSpeaking in tts.isSpeaking() {
                        if isSpeaking {
                            await send(.startSpeaking)
                        } else {
                            await send(.stopSpeaking)
                        }
                    }
                }
            case .startSpeaking:
                state.isSpeaking = true
                return .run { send in
                    for await progress in tts.speakingProgress() {
                        await send(.changeSpeakingProgress(progress))
                    }
                }
            case .stopSpeaking:
                state.isSpeaking = false
                return .none
            case let .changeSpeakingProgress(speakingProgress):
                state.speakingProgress = speakingProgress
                return .none
            }
        }
    }
}

```

## Combine Usage

You can instantiate/inject `TTSEngine` object, it has this behavior

* `func speak(string: String)`: call this method when you simply want to use the TTS with a simple String
  * subscribe to `isSpeakingPublisher` to know when the utterance starts to be heard, and when it's stopped
  * subscribe to `speakingProgressPublisher` to know the progress, from 0 to 1
* `var rateRatio: Float`: set the rate to slow down or accelerate the TTS engine
* `var voice: AVSpeechSynthesisVoice?`: set the voice of the TTS engine, by default, it's the voice for `en-GB`

### Example

```swift
import Combine
import SwiftTTSCombine

let engine: TTSEngine = SwiftTTSCombine.Engine()
var cancellables = Set<AnyCancellable>()

engine.speak(string: "Hello World!")

engine.isSpeakingPublisher
    .sink { isSpeaking in
        print("TTS is currently \(isSpeaking ? "speaking" : "not speaking")")
    }
    .store(in: &cancellables)

engine.speakingProgressPublisher
    .sink { progress in
        print("Progress: \(Int(progress * 100))%")
    }
    .store(in: &cancellables)

engine.rateRatio = 3/4

engine.speak(string: "Hello World! But slower")
```

## Installation

### Xcode

You can add SwiftTTS libs to an Xcode project by adding it as a package dependency.

1. From the **File** menu, select **Swift Packages › Add Package Dependency...**
2. Enter "https://github.com/renaudjenny/swift-tts" into the package repository URL test field
3. Select one of the three package that your are interested in. See [above](#swifttts)

### As package dependency

Edit your `Package.swift` to add one of the library you want among the three available.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/renaudjenny/swift-tts", from: "2.0.0"),
        ...
    ],
    targets: [
        .target(
            name: "<Your project name>",
            dependencies: [
                .product(name: "SwiftTTS", package: "swift-tts"), // <-- Modern concurrency
                .product(name: "SwiftTTSDependency", package: "swift-tts"), // <-- Point-Free Dependencies library wrapper
                .product(name: "SwiftTTSCombine", package: "swift-tts"), // <-- Combine wrapper
            ]),
        ...
    ]
)
```

## App using this library

* [📲 Tell Time UK](https://apps.apple.com/gb/app/tell-time-uk/id1496541173): https://github.com/renaudjenny/telltime
