import SwiftUI
import UniformTypeIdentifiers

extension View {
    /// 统一 PDF 导入入口。保留 SwiftUI 原生 `fileImporter` 和 `UTType.pdf`，
    /// 只集中 PaperClip 对 PDF 导入的单选配置。
    func paperClipPDFFileImporter(
        isPresented: Binding<Bool>,
        onCompletion: @escaping (Result<[URL], Error>) -> Void
    ) -> some View {
        fileImporter(
            isPresented: isPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false,
            onCompletion: onCompletion
        )
    }
}
