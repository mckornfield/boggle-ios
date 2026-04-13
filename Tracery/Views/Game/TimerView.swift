import SwiftUI

struct TimerView: View {
    let timer: TimerService
    var large: Bool = false

    private var timerColor: Color {
        let f = timer.urgencyFraction
        if f < 0.5 { return .green }
        if f < 0.83 { return .yellow }
        return .red
    }

    var body: some View {
        Text(timer.formattedTime)
            .font(large
                ? .system(size: 72, weight: .bold, design: .monospaced)
                : .system(size: 36, weight: .bold, design: .monospaced))
            .foregroundStyle(timerColor)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.3), value: timer.secondsRemaining)
    }
}
