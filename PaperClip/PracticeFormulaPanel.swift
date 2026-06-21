import SwiftUI
import WebKit

// MARK: - Data Models

enum StepType: String, Codable, CaseIterable {
    case numbered
    case because
    case conclusion
    case plain

    var menuLabel: String {
        switch self {
        case .numbered:   return "编号步骤 ①②③"
        case .because:    return "因为 ∵"
        case .conclusion: return "所以 ∴"
        case .plain:      return "无编号"
        }
    }

    func prefix(at index: Int) -> String {
        switch self {
        case .numbered:
            let symbols = ["①","②","③","④","⑤","⑥","⑦","⑧","⑨","⑩"]
            return index < symbols.count ? symbols[index] : "\(index + 1)."
        case .because:    return "∵"
        case .conclusion: return "∴"
        case .plain:      return ""
        }
    }
}

struct StepEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var type: StepType = .numbered
    var content: String = ""
}

// MARK: - Formula Step Editor

/// 公式步骤编辑区：行列表 + 底部符号面板。
struct FormulaStepEditorView: View {
    @Binding var steps: [StepEntry]
    @State private var activeID: UUID? = nil
    @State private var showPreview = false
    @FocusState private var focusedID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                Text("解题过程")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showPreview = true
                } label: {
                    Label("预览", systemImage: "eye")
                        .font(.subheadline)
                }
                .disabled(steps.allSatisfy { $0.content.isEmpty })
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .overlay(alignment: .bottom) { Divider() }

            // 行列表
            ScrollView {
                LazyVStack(spacing: 0) {
                    if steps.isEmpty {
                        Text("点击下方「新增步骤」开始输入解题过程")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(32)
                    }
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        StepRowView(
                            step: stepBinding(id: step.id),
                            index: index,
                            isActive: activeID == step.id,
                            focusedID: $focusedID,
                            onTap: {
                                activeID = step.id
                                focusedID = step.id
                            },
                            onDelete: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    steps.removeAll { $0.id == step.id }
                                    if activeID == step.id { activeID = nil }
                                }
                            },
                            onChangeType: { newType in
                                if let i = steps.firstIndex(where: { $0.id == step.id }) {
                                    steps[i].type = newType
                                }
                            }
                        )
                        if index < steps.count - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .padding(.bottom, 8)
            }

            // 新增步骤
            Divider()
            Button {
                let newStep = StepEntry()
                withAnimation(.easeInOut(duration: 0.2)) {
                    steps.append(newStep)
                }
                activeID = newStep.id
                focusedID = newStep.id
            } label: {
                Label("新增步骤", systemImage: "plus.circle")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .foregroundStyle(Color.accentColor)

            // 符号输入面板（激活某行时显示）
            if activeID != nil {
                Divider()
                SymbolInputPanelView { symbol in
                    guard let id = activeID,
                          let i = steps.firstIndex(where: { $0.id == id }) else { return }
                    steps[i].content += symbol
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: activeID)
        .sheet(isPresented: $showPreview) {
            StepsPreviewSheet(steps: steps)
        }
        .onTapGesture {
            // 点击空白区域取消激活
        }
    }

    private func stepBinding(id: UUID) -> Binding<StepEntry> {
        Binding(
            get: { steps.first(where: { $0.id == id }) ?? StepEntry() },
            set: { val in
                if let i = steps.firstIndex(where: { $0.id == id }) {
                    steps[i] = val
                }
            }
        )
    }
}

// MARK: - Step Row

private struct StepRowView: View {
    @Binding var step: StepEntry
    let index: Int
    let isActive: Bool
    var focusedID: FocusState<UUID?>.Binding
    let onTap: () -> Void
    let onDelete: () -> Void
    let onChangeType: (StepType) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 编号 / 前缀
            Menu {
                ForEach(StepType.allCases, id: \.self) { type in
                    Button(type.menuLabel) { onChangeType(type) }
                }
                Divider()
                Button(role: .destructive) { onDelete() } label: {
                    Label("删除此行", systemImage: "trash")
                }
            } label: {
                Text(step.type.prefix(at: index))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
                    .frame(width: 36, alignment: .center)
                    .padding(.vertical, 10)
            }

            // 输入框
            TextField(
                "输入内容，用 $…$ 包裹公式",
                text: $step.content,
                axis: .vertical
            )
            .font(.system(size: 15))
            .focused(focusedID, equals: step.id)
            .padding(.vertical, 10)
            .padding(.trailing, 12)
            .onTapGesture { onTap() }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActive ? Color.accentColor.opacity(0.06) : Color.clear)
        .overlay(alignment: .leading) {
            if isActive {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 3)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

// MARK: - Symbol Input Panel

struct SymbolInputPanelView: View {
    let onInsert: (String) -> Void

    @State private var selectedTab = 0

    private let choiceSymbols: [[String]] = [
        ["A", "B", "C", "D"],
        ["✓", "✕"]
    ]

    private let operatorRows: [[String]] = [
        ["7", "8", "9", "×", "÷"],
        ["4", "5", "6", "+", "−"],
        ["1", "2", "3", "=", "≠"],
        ["0", ".", "(", ")", "%"],
        ["^{}", "_{}", "²", "³", "≈"],
        [">", "<", "≥", "≤", "∞"]
    ]

    private let functionSymbols: [[String]] = [
        ["\\sqrt{}", "\\sqrt[3]{}", "\\frac{}{}", "π", "∞"],
        ["\\sin", "\\cos", "\\tan", "\\lg", "\\ln"],
        ["α", "β", "θ", "φ", "λ"],
        ["∵", "∴", "∈", "∉", "⊂"],
        ["∩", "∪", "∅", "→", "⟺"]
    ]

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("选判").tag(0)
                Text("运算").tag(1)
                Text("函数").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)

            ScrollView {
                switch selectedTab {
                case 0:
                    choicePanel
                case 1:
                    operatorPanel
                default:
                    functionPanel
                }
            }
            .frame(height: 160)
        }
        .background(Color(.secondarySystemBackground))
    }

    private var choicePanel: some View {
        VStack(spacing: 8) {
            ForEach(choiceSymbols, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { sym in
                        SymbolButton(label: sym) { onInsert(sym) }
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 8)
    }

    private var operatorPanel: some View {
        VStack(spacing: 6) {
            ForEach(operatorRows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { sym in
                        SymbolButton(label: displayLabel(sym), small: true) {
                            onInsert(sym)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 8)
    }

    private var functionPanel: some View {
        VStack(spacing: 6) {
            ForEach(functionSymbols, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { sym in
                        SymbolButton(label: displayLabel(sym), small: true) {
                            onInsert(sym)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 8)
    }

    private func displayLabel(_ sym: String) -> String {
        sym
            .replacingOccurrences(of: "\\sqrt{}", with: "√□")
            .replacingOccurrences(of: "\\sqrt[3]{}", with: "∛□")
            .replacingOccurrences(of: "\\frac{}{}", with: "a/b")
            .replacingOccurrences(of: "\\sin", with: "sin")
            .replacingOccurrences(of: "\\cos", with: "cos")
            .replacingOccurrences(of: "\\tan", with: "tan")
            .replacingOccurrences(of: "\\lg", with: "lg")
            .replacingOccurrences(of: "\\ln", with: "ln")
            .replacingOccurrences(of: "^{}", with: "xⁿ")
            .replacingOccurrences(of: "_{}", with: "xₙ")
    }
}

private struct SymbolButton: View {
    let label: String
    var small: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(small ? .system(size: 14, weight: .medium) : .system(size: 17, weight: .medium))
                .frame(minWidth: small ? 52 : 64, minHeight: small ? 36 : 44)
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - Preview Sheet (KaTeX WebView)

private struct StepsPreviewSheet: View {
    let steps: [StepEntry]
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 300

    var body: some View {
        NavigationStack {
            ScrollView {
                StepsWebView(steps: steps, contentHeight: $contentHeight)
                    .frame(height: max(contentHeight, 200))
                    .padding(16)
            }
            .navigationTitle("公式预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Steps Web View

/// 将所有步骤渲染为一个 HTML 文档（复用项目已有 KaTeX 基础）。
struct StepsWebView: UIViewRepresentable {
    let steps: [StepEntry]
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "paperClipHeight")
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.scrollView.isScrollEnabled = false
        wv.scrollView.bounces = false
        wv.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.backgroundColor = .clear
        wv.isInspectable = false
        return wv
    }

    func updateUIView(_ wv: WKWebView, context: Context) {
        context.coordinator.onHeight = { h in
            let v = ceil(h)
            guard abs(contentHeight - v) > 1 else { return }
            contentHeight = v
        }
        let html = StepsWebView.buildHTML(steps: steps)
        let newID = steps.map { $0.id.uuidString + $0.content }.joined().hashValue.description
        guard context.coordinator.loadedID != newID else { return }
        context.coordinator.loadedID = newID
        wv.loadHTMLString(html, baseURL: nil)
    }

    static func dismantleUIView(_ wv: WKWebView, coordinator: Coordinator) {
        wv.stopLoading()
        wv.configuration.userContentController.removeScriptMessageHandler(forName: "paperClipHeight")
    }

    @MainActor
    final class Coordinator: NSObject, WKScriptMessageHandler {
        var loadedID: String?
        var onHeight: ((CGFloat) -> Void)?

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            if let h = message.body as? NSNumber {
                onHeight?(CGFloat(truncating: h))
            }
        }
    }

    private static func numberedSteps(_ steps: [StepEntry]) -> [(prefix: String, content: String)] {
        var numberedIndex = 0
        return steps.map { step in
            let prefix: String
            if step.type == .numbered {
                prefix = step.type.prefix(at: numberedIndex)
                numberedIndex += 1
            } else {
                prefix = step.type.prefix(at: 0)
            }
            return (prefix, step.content)
        }
    }

    static func buildHTML(steps: [StepEntry]) -> String {
        let rows = numberedSteps(steps).map { row in
            let escapedContent = row.content
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            let prefix = row.prefix.isEmpty ? "" : "<span class='prefix'>\(row.prefix)</span>"
            return "<div class='step'>\(prefix)<span class='content'>\(escapedContent)</span></div>"
        }.joined()

        return """
        <!DOCTYPE html><html lang="zh-Hans"><head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css">
        <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>
        <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js"></script>
        <style>
        *{box-sizing:border-box;margin:0;padding:0}
        html,body{background:transparent;font-size:16px;line-height:1.8;color:#1c1c1e}
        @media(prefers-color-scheme:dark){body{color:#ebebf5}}
        .step{display:flex;gap:10px;padding:8px 0;border-bottom:1px solid rgba(0,0,0,0.06)}
        .step:last-child{border-bottom:none}
        .prefix{font-weight:600;color:#2563eb;min-width:24px;flex-shrink:0;padding-top:1px}
        @media(prefers-color-scheme:dark){.prefix{color:#93c5fd}}
        .content{flex:1;overflow-wrap:anywhere}
        .katex-display{margin:4px 0;overflow-x:auto;overflow-y:hidden}
        </style>
        </head><body>
        <div class="steps">\(rows)</div>
        <script>
        (()=>{
          const report=()=>window.webkit.messageHandlers.paperClipHeight.postMessage(
            Math.ceil(document.documentElement.scrollHeight));
          const render=()=>{
            window.renderMathInElement&&renderMathInElement(document.body,{
              delimiters:[{left:'$$',right:'$$',display:true},{left:'$',right:'$',display:false}],
              throwOnError:false});
            report();
          };
          new ResizeObserver(report).observe(document.documentElement);
          document.addEventListener('DOMContentLoaded',render);
          window.addEventListener('load',render);
          setTimeout(render,250);setTimeout(render,1200);
        })();
        </script>
        </body></html>
        """
    }
}
