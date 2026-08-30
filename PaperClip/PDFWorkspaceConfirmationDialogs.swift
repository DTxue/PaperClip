import SwiftUI

extension View {
    func pdfWorkspaceConfirmationDialogs(owner: PDFWorkspaceView) -> some View {
        let isRetryingPage = owner.session.activeAttempt?.status == ExamAttemptStatus.submitted.rawValue
            || owner.session.isCurrentPageAwaitingGrading()
        return self
            .confirmationDialog(
                "清除当前页答题？",
                isPresented: owner.$session.isClearAnswersConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("清除当前页答题", role: .destructive) {
                    owner.clearAllAnswers()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("只清除当前尚未提交页面的手写内容；已经提交页面的答案和批阅结果不会受影响。")
            }
            .confirmationDialog(
                isRetryingPage ? "确认重试单页批阅？" : "确认提交当前页？",
                isPresented: owner.$session.isSubmitConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button(
                    isRetryingPage ? "重试批阅" : "提交本页",
                    role: .destructive
                ) {
                    owner.submitExam()
                }
                Button("取消", role: .cancel) {}
            } message: {
                if isRetryingPage {
                    Text("只重新提交一张待批阅页面，已经完成的页面和源 PDF 不会被修改。")
                } else {
                    Text("只保存并批阅当前页面；提交成功后该页答案会锁定，历史页面的批阅结果仍可查看。")
                }
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
    }
}
