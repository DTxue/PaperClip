import SwiftUI
import SwiftData

@main
struct PaperClipApp: App {
    private let container: ModelContainer
    private let startupError: AppAlert?

    init() {
        let schema = Schema([
            PDFDocumentItem.self,
            HandwritingLayer.self,
            MistakeCard.self,
            ExportRecord.self,
            MistakePracticeLayer.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            startupError = nil
        } catch let persistentError {
            do {
                let fallback = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                container = try ModelContainer(
                    for: schema,
                    configurations: [fallback]
                )
                startupError = AppAlert(
                    title: "本地数据库不可用",
                    message: """
                    应用已进入临时模式，本次运行的数据不会持久保存。\
                    请重新启动应用；如问题持续，请先备份应用数据。\
                    原因：\(persistentError.localizedDescription)
                    """
                )
            } catch {
                fatalError("无法创建数据库容器：\(error.localizedDescription)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(startupError: startupError)
                .task {
                    // 将 ModelContainer 注入识别服务，补跑上次未完成的识别任务
                    MistakeCardRecognitionService.shared.modelContainer = container
                    MistakeCardRecognitionService.shared.resumeUnfinished()
                }
        }
        .modelContainer(container)
    }
}

private struct AppRootView: View {
    @State private var startupError: AppAlert?

    init(startupError: AppAlert?) {
        _startupError = State(initialValue: startupError)
    }

    var body: some View {
        RootView()
            .appAlert($startupError)
    }
}
