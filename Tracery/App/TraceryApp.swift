import SwiftUI

@main
struct TraceryApp: App {
    @State private var dictionaryService = DictionaryService()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(dictionaryService)
        }
    }
}
