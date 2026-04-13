import SwiftUI

@main
struct TraceryApp: App {
    @State private var dictionaryService = DictionaryService()
    @State private var musicService = MusicService()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(dictionaryService)
                .environment(musicService)
        }
    }
}
