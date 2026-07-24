import AVFoundation

final class SoundManager {
    enum Effect: Hashable {
        case shoot
        case hit
        case pickup
        case purchase
        case boss
        case gameOver
        case victory

        var minimumInterval: TimeInterval {
            switch self {
            case .shoot: 0.075
            case .hit: 0.055
            case .pickup: 0.045
            default: 0.12
            }
        }

        var configuration: (
            startFrequency: Double,
            endFrequency: Double,
            duration: Double,
            volume: Float
        ) {
            switch self {
            case .shoot: (720, 470, 0.045, 0.075)
            case .hit: (180, 95, 0.07, 0.12)
            case .pickup: (760, 1_160, 0.075, 0.09)
            case .purchase: (410, 780, 0.16, 0.12)
            case .boss: (115, 58, 0.42, 0.18)
            case .gameOver: (260, 72, 0.52, 0.17)
            case .victory: (520, 1_060, 0.62, 0.15)
            }
        }
    }

    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private var isPrepared = false
    private var lastPlayed: [Effect: TimeInterval] = [:]

    private init() {}

    func prepare() {
        guard !isPrepared else { return }
        isPrepared = true

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)

            let format = AVAudioFormat(
                standardFormatWithSampleRate: sampleRate,
                channels: 1
            )!
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            engine.mainMixerNode.outputVolume = 0.8
            try engine.start()
        } catch {
            isPrepared = false
        }
    }

    func play(_ effect: Effect) {
        prepare()
        guard isPrepared else { return }

        let now = ProcessInfo.processInfo.systemUptime
        if let last = lastPlayed[effect], now - last < effect.minimumInterval {
            return
        }
        lastPlayed[effect] = now

        if !engine.isRunning {
            try? engine.start()
        }

        let configuration = effect.configuration
        let frameCount = AVAudioFrameCount(configuration.duration * sampleRate)
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        ),
        let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ),
        let samples = buffer.floatChannelData?[0] else { return }

        buffer.frameLength = frameCount
        var phase = 0.0
        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / Double(max(1, Int(frameCount) - 1))
            let frequency = configuration.startFrequency
                + (configuration.endFrequency - configuration.startFrequency) * progress
            phase += 2 * Double.pi * frequency / sampleRate
            let envelope = pow(1 - progress, 2.2)
            let tone = sin(phase)
            let overtone = sin(phase * 2.03) * 0.18
            samples[frame] = Float((tone + overtone) * envelope) * configuration.volume
        }

        player.scheduleBuffer(buffer)
        if !player.isPlaying {
            player.play()
        }
    }
}
