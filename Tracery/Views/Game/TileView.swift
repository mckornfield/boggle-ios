import SwiftUI

enum TileState {
    case idle
    case highlighted   // currently in trace path
    case submitted     // recently submitted (brief flash)
}

struct TileView: View {
    let tile: Tile
    let state: TileState
    let isPathStart: Bool

    private var background: Color {
        switch state {
        case .idle: return Color(.secondarySystemBackground)
        case .highlighted: return isPathStart ? .blue : .blue.opacity(0.7)
        case .submitted: return .green
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(background)
                .shadow(color: state == .highlighted ? .blue.opacity(0.4) : .clear, radius: 6)
            Text(tile.letter)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(state == .idle ? Color.primary : Color.white)
                .minimumScaleFactor(0.6)
        }
        .animation(.easeInOut(duration: 0.1), value: state)
    }
}
