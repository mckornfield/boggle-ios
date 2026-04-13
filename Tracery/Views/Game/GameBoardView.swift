import SwiftUI

struct GameBoardView: View {
    @Bindable var gameVM: GameViewModel
    var sessionVM: SessionViewModel
    @State private var showResults = false
    @State private var showGameOver = false

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Tracery")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: gameVM.phase) { _, phase in
            switch phase {
            case .roundOver: showResults = true
            case .sessionOver: showGameOver = true
            case .playing: showResults = false
            }
        }
        .navigationDestination(isPresented: $showResults) {
            RoundResultsView(gameVM: gameVM, sessionVM: sessionVM)
        }
        .navigationDestination(isPresented: $showGameOver) {
            GameOverView(session: gameVM.session, sessionVM: sessionVM)
        }
    }

    // MARK: - iPhone layout: stacked vertically

    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            TimerView(timer: gameVM.timer)
                .padding(.vertical, 12)

            GridView(
                grid: gameVM.grid,
                tracedPath: gameVM.tracedPath,
                onTileEntered: { gameVM.tileEntered($0) },
                onCommit: { gameVM.commitTrace() }
            )
            .padding(.horizontal, 12)

            // Current trace display — always occupies space to prevent layout bounce
            Text(gameVM.tracedWord.isEmpty ? " " : gameVM.tracedWord)
                .font(.title2.bold())
                .padding(.top, 8)

            // Word list
            List(gameVM.submittedWords) { entry in
                SubmittedWordRow(entry: entry)
            }
            .listStyle(.plain)
        }
    }

    // MARK: - iPad layout: grid on left, words on right

    private var iPadLayout: some View {
        HStack(spacing: 24) {
            VStack {
                TimerView(timer: gameVM.timer)
                    .padding(.bottom, 8)
                GridView(
                    grid: gameVM.grid,
                    tracedPath: gameVM.tracedPath,
                    onTileEntered: { gameVM.tileEntered($0) },
                    onCommit: { gameVM.commitTrace() }
                )
                Text(gameVM.tracedWord.isEmpty ? " " : gameVM.tracedWord)
                    .font(.title.bold())
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)

            List(gameVM.submittedWords) { entry in
                SubmittedWordRow(entry: entry)
            }
            .listStyle(.plain)
            .frame(maxWidth: 220)
        }
        .padding()
    }
}

struct SubmittedWordRow: View {
    let entry: GameViewModel.SubmittedWordEntry

    var body: some View {
        HStack {
            Text(entry.word)
                .strikethrough(!entry.isInDictionary)
                .foregroundStyle(entry.isInDictionary ? Color.primary : Color.secondary)
            Spacer()
            if entry.isInDictionary {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .font(.body)
    }
}
