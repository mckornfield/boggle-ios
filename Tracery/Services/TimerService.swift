import Foundation
import Combine
import AudioToolbox

@Observable
class TimerService {
    static let roundDuration: TimeInterval = {
        #if targetEnvironment(simulator)
        return 10
        #else
        return 180  // 3 minutes
        #endif
    }()

    private(set) var secondsRemaining: Int = Int(roundDuration)
    private(set) var currentDuration: TimeInterval = TimerService.roundDuration
    private(set) var isRunning = false
    private(set) var isExpired = false
    var soundEnabled: Bool = true

    private var cancellable: AnyCancellable?
    var onExpiry: (() -> Void)?

    func start(duration: TimeInterval = TimerService.roundDuration) {
        currentDuration = duration
        secondsRemaining = Int(duration)
        isExpired = false
        isRunning = true
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stop() {
        isRunning = false
        cancellable = nil
    }

    func reset() {
        stop()
        secondsRemaining = Int(TimerService.roundDuration)
        isExpired = false
    }

    private func tick() {
        guard secondsRemaining > 0 else { return }
        secondsRemaining -= 1
        if secondsRemaining == 0 {
            isExpired = true
            isRunning = false
            cancellable = nil
            if soundEnabled { AudioServicesPlaySystemSound(1005) }  // audible alert
            onExpiry?()
        }
    }

    var formattedTime: String {
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    /// Color shifts green → yellow → red as time runs out
    var urgencyFraction: Double {
        guard currentDuration > 0 else { return 1.0 }
        return 1.0 - Double(secondsRemaining) / currentDuration
    }
}
