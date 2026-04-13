import SwiftUI

struct HomeView: View {
    @Environment(DictionaryService.self) private var dictionary
    @State private var sessionVM = SessionViewModel()
    @State private var destination: Destination?

    enum Destination: Identifiable {
        case solo, multiplayer, tableMode
        var id: Self { self }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                Text("Tracery")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                Text("Find words. Trace paths.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack(spacing: 16) {
                    modeButton("Solo", systemImage: "person.fill", color: .blue) {
                        destination = .solo
                    }
                    modeButton("Multiplayer", systemImage: "person.3.fill", color: .green) {
                        destination = .multiplayer
                    }
                    modeButton("Table Mode", systemImage: "ipad.landscape", color: .orange) {
                        destination = .tableMode
                    }
                }
                .padding(.horizontal, 32)
                Spacer()
            }
            .navigationDestination(item: $destination) { dest in
                switch dest {
                case .solo:
                    SessionSetupView(mode: .solo, sessionVM: sessionVM)
                        .environment(dictionary)
                case .multiplayer:
                    SessionSetupView(mode: .multiplayer, sessionVM: sessionVM)
                        .environment(dictionary)
                case .tableMode:
                    TableModeView()
                }
            }
        }
    }

    private func modeButton(_ title: String, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(color.gradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
