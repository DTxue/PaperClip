import SwiftUI
import SwiftData

@main
struct PaperClipApp: App {
    private let container: ModelContainer
    private let startupError: AppAlert?

    init() {
        let launchStore = PaperClipModelContainerFactory.makeLaunchStore()
        container = launchStore.container
        startupError = launchStore.startupError
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(startupError: startupError)
                .task {
                    PaperClipStartup.runOnce(for: container)
                }
        }
        .modelContainer(container)
    }
}
