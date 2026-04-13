import SwiftUI

struct GridView: View {
    let grid: Grid
    let tracedPath: [Tile]
    let onTileEntered: (Tile) -> Void
    let onCommit: () -> Void

    private let spacing: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let total = min(geo.size.width, geo.size.height)
            let tileSize = (total - spacing * CGFloat(Grid.size - 1)) / CGFloat(Grid.size)

            ZStack(alignment: .topLeading) {
                // Tile grid
                VStack(spacing: spacing) {
                    ForEach(0..<Grid.size, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<Grid.size, id: \.self) { col in
                                let tile = grid[row, col]
                                TileView(
                                    tile: tile,
                                    state: tileState(for: tile),
                                    isPathStart: tracedPath.first?.id == tile.id
                                )
                                .frame(width: tileSize, height: tileSize)
                            }
                        }
                    }
                }

                // Connection lines between traced tiles
                if tracedPath.count > 1 {
                    Path { path in
                        for (i, tile) in tracedPath.enumerated() {
                            let center = tileCenter(row: tile.row, col: tile.col, tileSize: tileSize)
                            if i == 0 { path.move(to: center) } else { path.addLine(to: center) }
                        }
                    }
                    .stroke(Color.blue.opacity(0.6), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .allowsHitTesting(false)
                }

                // Invisible gesture layer on top
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                let tile = tileAt(point: value.location, tileSize: tileSize)
                                if let tile { onTileEntered(tile) }
                            }
                            .onEnded { _ in onCommit() }
                    )
            }
            .frame(width: total, height: total)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func tileState(for tile: Tile) -> TileState {
        tracedPath.contains(where: { $0.id == tile.id }) ? .highlighted : .idle
    }

    private func tileCenter(row: Int, col: Int, tileSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(col) * (tileSize + spacing) + tileSize / 2,
            y: CGFloat(row) * (tileSize + spacing) + tileSize / 2
        )
    }

    private func tileAt(point: CGPoint, tileSize: CGFloat) -> Tile? {
        let step = tileSize + spacing
        let col = Int(point.x / step)
        let row = Int(point.y / step)
        guard row >= 0, row < Grid.size, col >= 0, col < Grid.size else { return nil }
        // Only register when the touch is within the tile itself — gap is dead space.
        // Larger spacing means a clear gap to pass through on diagonal swipes.
        let tileOriginX = CGFloat(col) * step
        let tileOriginY = CGFloat(row) * step
        guard point.x - tileOriginX <= tileSize, point.y - tileOriginY <= tileSize else { return nil }
        return grid[row, col]
    }
}
