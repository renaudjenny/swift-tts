#if os(macOS)
#error("This library is not compatible with macOS")
#endif

import AVFoundation

public struct SwiftTTS {
    public var rateRatio: () -> Float
    public var setRateRatio: (Float) -> Void
    public var voice: () -> AVSpeechSynthesisVoice?
    public var setVoice: (AVSpeechSynthesisVoice) -> Void
    public var speak: (String) -> Void
    public var isSpeaking: () -> AsyncStream<Bool>
    public var speakingProgress: () -> AsyncStream<Double>

    public init(
        rateRatio: @escaping () -> Float,
        setRateRatio: @escaping (Float) -> Void,
        voice: @escaping () -> AVSpeechSynthesisVoice?,
        setVoice: @escaping (AVSpeechSynthesisVoice) -> Void,
        speak: @escaping (String) -> Void,
        isSpeaking: @escaping () -> AsyncStream<Bool>,
        speakingProgress: @escaping () -> AsyncStream<Double>
    ) {
        self.rateRatio = rateRatio
        self.setRateRatio = setRateRatio
        self.voice = voice
        self.setVoice = setVoice
        self.speak = speak
        self.isSpeaking = isSpeaking
        self.speakingProgress = speakingProgress
    }
}

private final class Engine: NSObject, AVSpeechSynthesizerDelegate {

    var rateRatio: Float
    var voice: AVSpeechSynthesisVoice?
    var isSpeaking: ((Bool) -> Void)?
    var speakingProgress: ((Double) -> Void)?
    private let speechSynthesizer = AVSpeechSynthesizer()

    init(
        rateRatio: Float,
        voice: AVSpeechSynthesisVoice?
    ) {
        self.rateRatio = rateRatio
        self.voice = voice
        super.init()
        speechSynthesizer.delegate = self
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        #endif
    }

    func speak(string: String) {
        let speechUtterance = AVSpeechUtterance(string: string)
        speechUtterance.voice = voice
        speechUtterance.rate *= rateRatio
        speechSynthesizer.speak(speechUtterance)
        isSpeaking?(true)
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {
        speakingProgress?(0.0)
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        isSpeaking?(false)
        speakingProgress?(1.0)
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        let total = Double(utterance.speechString.count)
        let averageBound = [Double(characterRange.lowerBound), Double(characterRange.upperBound)]
            .reduce(0, +)/2
        speakingProgress?(averageBound/total)
    }
}

public extension SwiftTTS {
    static var live: Self {
        let engine = Engine(rateRatio: 1.0, voice: AVSpeechSynthesisVoice(language: "en-GB"))

        let isSpeaking = AsyncStream { continuation in
            engine.isSpeaking = {
                if $0 {
                    continuation.yield(true)
                } else {
                    continuation.yield(false)
                }
            }
        }

        let speakingProgress = AsyncStream { continuation in
            engine.speakingProgress = {
                if $0 < 1.0 {
                    continuation.yield($0)
                } else {
                    continuation.yield(1)
                }
            }
        }

        return Self(
            rateRatio: { engine.rateRatio },
            setRateRatio: { engine.rateRatio = $0 },
            voice: { engine.voice },
            setVoice: { engine.voice = $0 },
            speak: engine.speak,
            isSpeaking: { isSpeaking },
            speakingProgress: { speakingProgress }
       )
    }
}
