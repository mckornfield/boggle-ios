import SwiftUI

private struct MuteButtonModifier: ViewModifier {
    @Environment(MusicService.self) private var music

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    music.toggleMute()
                } label: {
                    Image(systemName: music.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                }
            }
        }
    }
}

extension View {
    func muteButton() -> some View {
        modifier(MuteButtonModifier())
    }
}
