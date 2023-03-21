# SwiftTTS

This package contains some very straightforward wrappers around TTS part of AVFoundation/AVSpeechSynthesizer to allow you using Text to Speech with ease.

* `SwiftTTS` Using **Swift Concurrency** with `async` `await`, a couple of `AsyncStream`
* `SwiftTTSDependency` A wrapper around the library above facilitating the integration with [Point-Free Dependencies](https://github.com/pointfreeco/swift-dependencies) library or a project made with The Composable Architecture (TCA).
* `SwiftTTSCombine` the OG library still available in this package

## Modern concurrency usage

🔨 TODO

## [Point-Free Dependencies](https://github.com/pointfreeco/swift-dependencies) usage

🔨 TODO

## Combine Usage

You can instantiate/inject `TTSEngine` object, it has this behavior

* `func speak(string: String)`: call this method when you simply want to use the TTS with a simple String
  * subscribe to `isSpeakingPublisher` to know when the utterance starts to be heard, and when it's stopped
  * subscribe to `speakingProgressPublisher` to know the progress, from 0 to 1
* `var rateRatio: Float`: set the rate to slow down or accelerate the TTS engine
* `var voice: AVSpeechSynthesisVoice?`: set the voice of the TTS engine, by default, it's the voice for `en-GB`

Example

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

You can add SwiftTTSCombine to an Xcode project by adding it as a package dependency.

1. From the **File** menu, select **Swift Packages › Add Package Dependency...**
2. Enter "https://github.com/renaudjenny/SwiftTTS" into the package repository URL test field

### As package dependency

Edit your `Package.swift` to add this library.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/renaudjenny/SwiftTTS", from: "2.0.0"),
        ...
    ],
    targets: [
        .target(
            name: "<Your project name>",
            dependencies: ["SwiftTTS"]), // <-- Modern concurrency
            dependencies: ["SwiftTTSDependency"]), // <-- Point-Free Dependencies library wrapper
            dependencies: ["SwiftTTSCombine"]), // <-- Combine wrapper
        ...
    ]
)
```

## App using this library

* [📲 Tell Time UK](https://apps.apple.com/gb/app/tell-time-uk/id1496541173): https://github.com/renaudjenny/telltime
