#if os(macOS)
#error("This library is not compatible with macOS")
#endif

import Foundation
import Combine
import AVFoundation

public protocol TTSEngine: AnyObject {
    var rateRatio: Float { get set }
    var voice: AVSpeechSynthesisVoice? { get set }
    func speak(string: String)
    var isSpeakingPublisher: AnyPublisher<Bool, Never> { get }
    var speakingProgressPublisher: AnyPublisher<Double, Never> { get }
}

public final class Engine: NSObject, ObservableObject {
    @Published private var isSpeaking: Bool = false
    @Published private var speakingProgress: Double = 0.0
    public var rateRatio: Float
    public var voice: AVSpeechSynthesisVoice?
    private let speechSynthesizer = AVSpeechSynthesizer()

    public init(
        rateRatio: Float = 1.0,
        voice: AVSpeechSynthesisVoice? = AVSpeechSynthesisVoice(language: "en-GB")
    ) {
        self.rateRatio = rateRatio
        self.voice = voice
        super.init()
        self.speechSynthesizer.delegate = self
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        #endif
    }
}

extension Engine: AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {
        self.speakingProgress = 0.0
    }

    public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        self.isSpeaking = false
        self.speakingProgress = 1.0
    }

    public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        let total = Double(utterance.speechString.count)
        let averageBound = [Double(characterRange.lowerBound), Double(characterRange.upperBound)]
            .reduce(0, +)/2
        self.speakingProgress = averageBound/total
    }
}

extension Engine: TTSEngine {
    public func speak(string: String) {
        let speechUtterance = AVSpeechUtterance(string: string)
        speechUtterance.voice = voice
        speechUtterance.rate *= rateRatio
        self.speechSynthesizer.speak(speechUtterance)
        self.isSpeaking = true
    }

    public var isSpeakingPublisher: AnyPublisher<Bool, Never> {
        $isSpeaking.eraseToAnyPublisher()
    }

    public var speakingProgressPublisher: AnyPublisher<Double, Never> {
        $speakingProgress.eraseToAnyPublisher()
    }
}
