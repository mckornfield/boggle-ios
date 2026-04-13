import SwiftUI

struct TableModeView: View {
    let playerNames: [String]

    @State private var grid: Grid = Grid(letters: GridGenerator.generate())
    @State private var timer = TimerService()
    @State private var isRunning = false
    @State private var showScoreEntry = false
    @State private var showScoringReference = false
    @State private var playerScores: [(name: String, score: Int)]

    init(playerNames: [String]) {
        self.playerNames = playerNames
        _playerScores = State(initialValue: playerNames.map { ($0, 0) })
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 24) {
                TimerView(timer: timer, large: true)
                    .padding(.top, 32)

                GridView(
                    grid: grid,
                    tracedPath: [],
                    onTileEntered: { _ in },
                    onCommit: {}
                )
                .frame(width: min(geo.size.width, geo.size.height) * 0.65)

                HStack(spacing: 24) {
                    if !isRunning && !timer.isRunning {
                        Button("Start Round") {
                            isRunning = true
                            timer.start()
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.title2.bold())
                    }

                    if timer.isExpired || !isRunning {
                        Button("New Round") {
                            grid = Grid(letters: GridGenerator.generate())
                            timer.reset()
                            isRunning = false
                        }
                        .buttonStyle(.bordered)
                        .font(.title2.bold())
                    }

                    Button("Scores") { showScoreEntry = true }
                        .buttonStyle(.bordered)
                        .font(.title2.bold())
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Table Mode")
        .navigationBarTitleDisplayMode(.inline)
        .muteButton()
        .onChange(of: timer.isExpired) { _, expired in
            if expired { showScoringReference = true }
        }
        .sheet(isPresented: $showScoreEntry) {
            ScoreEntryView(playerScores: $playerScores)
        }
        .sheet(isPresented: $showScoringReference) {
            ScoringReferenceView()
        }
    }
}

// MARK: - Scoring Reference

struct ScoringReferenceView: View {
    @Environment(\.dismiss) private var dismiss

    private let rows: [(length: String, points: String)] = [
        ("3 letters", "1 pt"),
        ("4 letters", "1 pt"),
        ("5 letters", "2 pts"),
        ("6 letters", "3 pts"),
        ("7 letters", "5 pts"),
        ("8+ letters", "11 pts"),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(rows, id: \.length) { row in
                        HStack {
                            Text(row.length)
                            Spacer()
                            Text(row.points)
                                .bold()
                                .foregroundStyle(.blue)
                        }
                    }
                }

                Section {
                    Label("\"QU\" counts as 2 letters", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Label("Proper nouns and abbreviations don't count", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Scoring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Score Entry

struct ScoreEntryView: View {
    @Binding var playerScores: [(name: String, score: Int)]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                ForEach($playerScores.indices, id: \.self) { idx in
                    HStack {
                        TextField("Name", text: Binding(
                            get: { playerScores[idx].name },
                            set: { playerScores[idx].name = $0 }
                        ))
                        Spacer()
                        Stepper("\(playerScores[idx].score)", value: Binding(
                            get: { playerScores[idx].score },
                            set: { playerScores[idx].score = $0 }
                        ), in: 0...999)
                    }
                }
                Button("Add Player") {
                    playerScores.append(("Player \(playerScores.count + 1)", 0))
                }
            }
            .navigationTitle("Scores")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
