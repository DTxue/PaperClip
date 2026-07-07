import SwiftUI

struct FSRSExplanationItem: Identifiable {
    var id: String { title }

    let title: String
    let detail: String
    let systemImage: String
    var color: Color = .accentColor
}

enum FSRSExplanationContent {
    static let stateItems = [
        FSRSExplanationItem(
            title: "难度",
            detail: "表示该记忆内容本身有多难，会随评分逐步调整。",
            systemImage: "gauge.with.dots.needle.33percent"
        ),
        FSRSExplanationItem(
            title: "稳定度",
            detail: "表示记忆能够保持多久。稳定度越高，复习间隔通常越长。",
            systemImage: "waveform.path.ecg"
        ),
        FSRSExplanationItem(
            title: "可提取率",
            detail: "表示此刻成功回忆的预测概率，会随时间下降。",
            systemImage: "percent"
        ),
        FSRSExplanationItem(
            title: "目标保持率",
            detail: "目标越高，复习越频繁；目标越低，间隔越长。",
            systemImage: "scope"
        )
    ]

    static let ratingItems = [
        FSRSExplanationItem(
            title: "忘记",
            detail: "没有回忆起来，或需要关键提示。进入学习或重学步骤。",
            systemImage: "arrow.counterclockwise",
            color: .red
        ),
        FSRSExplanationItem(
            title: "困难",
            detail: "最终独立答对，但明显迟疑、费力或耗时较长。",
            systemImage: "brain",
            color: .orange
        ),
        FSRSExplanationItem(
            title: "记得",
            detail: "在正常时间内独立、正确地回忆出来。",
            systemImage: "checkmark",
            color: .green
        ),
        FSRSExplanationItem(
            title: "简单",
            detail: "快速、确定地回忆出来，几乎没有犹豫。",
            systemImage: "sparkles",
            color: .blue
        )
    ]

    static let implementationItems = [
        FSRSExplanationItem(title: "新内容使用 1 分钟和 10 分钟学习步骤", detail: "", systemImage: "clock"),
        FSRSExplanationItem(title: "复习失败后使用 10 分钟重学步骤", detail: "", systemImage: "arrow.clockwise"),
        FSRSExplanationItem(title: "单词 → 释义与释义 → 单词独立调度", detail: "", systemImage: "arrow.left.arrow.right"),
        FSRSExplanationItem(title: "长间隔加入可复现扰动，分散集中到期", detail: "", systemImage: "calendar.badge.clock"),
        FSRSExplanationItem(title: "每次作答记录评分、耗时和记忆状态变化", detail: "", systemImage: "list.bullet.clipboard")
    ]
}
