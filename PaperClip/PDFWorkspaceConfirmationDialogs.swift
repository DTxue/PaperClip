import SwiftUI

extension View {
    func pdfWorkspaceConfirmationDialogs(owner: PDFWorkspaceView) -> some View {
        self
            .confirmationDialog(
                "清除全部答题？",
                isPresented: owner.$session.isClearAnswersConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("清除本次答题", role: .destructive) {
                    owner.clearAllAnswers()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("将清除当前考试的所有手写内容，源 PDF 和其他考试记录不受影响。此操作不可撤销。")
            }
            .confirmationDialog(
                "确认交卷？",
                isPresented: owner.$session.isSubmitConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("交卷", role: .destructive) {
                    owner.submitExam()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("交卷后会按本次选择的页面和手写内容生成批阅图片，源 PDF 不会被修改。")
            }
            .confirmationDialog(
                "退出考试？",
                isPresented: owner.$session.isExitExamConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("保存并退出", role: .destructive) {
                    owner.exitActiveExam()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("当前答题内容会保存到本次考试记录，可稍后从最近考试继续。")
            }
            .confirmationDialog(
                "分享题目截图",
                isPresented: Binding(isPresenting: owner.$session.shareImageRequest),
                titleVisibility: .visible
            ) {
                if let shareImageRequest = owner.session.shareImageRequest {
                    ShareImageLink(request: shareImageRequest, previewTitle: "PaperClip 题目截图") {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                }
                Button("取消", role: .cancel) {
                    owner.session.shareImageRequest = nil
                }
            } message: {
                Text("使用系统分享菜单发送当前框选截图。")
            }
    }
}
