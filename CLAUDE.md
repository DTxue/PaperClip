# PaperClip — Claude 行为约束

本文件约束 Claude 在此仓库内的所有操作。

## 全局侧边栏规范

凡使用 `NavigationSplitView` 实现的侧边栏，必须遵循以下统一规范：

### 结构要求

```swift
NavigationSplitView(columnVisibility: .constant(.all)) {
    // 侧边栏内容
    .navigationTitle("...")
    .navigationSplitViewColumnWidth(min: 180, ideal: 220)
    .toolbar(removing: .sidebarToggle)
} detail: {
    // 详情内容
}
.navigationSplitViewStyle(.balanced)
```

- `columnVisibility: .constant(.all)` — 固定展开，不可折叠
- `min: 180, ideal: 220` — 统一列宽
- `.toolbar(removing: .sidebarToggle)` — 移除折叠按钮
- `.navigationSplitViewStyle(.balanced)` — 平衡模式，两栏并排

### 选中样式

- **导航类侧边栏**（选项互斥，如设置页）：使用 `List(data, selection: $binding)`，由系统自动渲染高亮背景
- **筛选类侧边栏**（多维度独立筛选，如知识库学科筛选）：使用自定义行 + `.listRowBackground(isActive ? Color.accentColor.opacity(0.12) : Color.clear)`，文字用 `Color.accentColor` + `.semibold`，右侧加 `checkmark` 图标
- 两种场景均不得自制高亮组件替代上述方案

### 禁止事项

- 禁止使用 `@State var columnVisibility + .onChange` 替代 `.constant(.all)`
- 禁止侧边栏宽度与规范值不一致
- 禁止保留折叠按钮或允许侧边栏折叠
- 新增带侧边栏的页面必须复用上述结构，不得另起一套实现

## 修改范围约束

**每次对话只修改用户明确提出的问题，严禁触碰任何未被要求的功能或代码。**

具体规则：

- 只改动与用户请求直接相关的最小代码范围
- 禁止借修复某处问题顺手重构、清理或"顺便优化"周边代码
- 禁止在未被要求的文件中添加、删除或修改任何内容
- 发现其他潜在问题时，仅以文字提示用户，不擅自动手修改
- 若修复某个问题必须同时改动其他代码，须先向用户说明原因并征得同意

## 技术选型规则

实现任何 UI 或系统能力前，必须按以下优先级检查：

1. SwiftUI 原生组件
2. Apple 官方框架（PDFKit、PencilKit、SwiftData、UniformTypeIdentifiers 等）
3. 系统修饰器与组件组合
4. 仅在前三项均无法满足业务需求时，才允许自定义实现

**禁止**为了样式差异、个人偏好或实现方便绕过系统能力。

## 必须使用系统实现的能力

以下功能存在系统等价实现，不得自行重写：

| 能力 | 必须使用的 API |
|------|---------------|
| 导航 | `NavigationStack`、`NavigationSplitView`、Toolbar |
| 菜单与操作 | `Menu`、`contextMenu`、`Command`、系统 Button Style |
| 弹窗/确认 | `alert`、`confirmationDialog`、`sheet`、`popover` |
| 文件导入导出 | `fileImporter`、`fileExporter`、`FileDocument` |
| 分享 | `ShareLink`、`Transferable` |
| 搜索 | `searchable` |
| 空状态 | `ContentUnavailableView` |
| 表单控件 | `Form`、`Picker`、`Slider`、`Toggle`、`TextField` |
| 日期/颜色 | `DatePicker`、`ColorPicker` |
| 文档扫描 | VisionKit |
| 手写/画笔/橡皮 | `PKCanvasView`、`PKToolPicker` |
| 数据持久化 | SwiftData |
| 图标 | SF Symbols |

禁止在 SwiftUI 已提供等价能力时创建 `UIViewControllerRepresentable` / `UIViewRepresentable` 包装。

## 实施顺序

每项 UI 或交互任务必须按以下顺序执行：

1. 查阅当前项目最低系统版本对应的 Apple API；
2. 确认是否已有 SwiftUI 原生组件；
3. 确认是否已有 Apple 官方框架组件；
4. 优先通过系统修饰器、容器和组合实现需求；
5. 仅在原生方案确实无法满足时设计自定义实现；
6. 完成后检查是否存在重复实现系统能力的代码；
7. 使用项目支持的设备 SDK 完整编译。

## 允许保留的自定义实现

以下业务能力暂无系统等价方案，可保留自定义代码，但内部仍须使用系统基础组件：

- 相册／扫描图片上的单题框选，不修改输入原图
- 错题与词汇测验的 PencilKit 桥接、作答状态及笔迹快照
- 使用系统 WebKit 与本地 KaTeX 的只读公式排版

即使属于允许自定义范围，也应继续使用系统基础能力：

- 手写答题使用 `PKCanvasView`
- 画笔工具使用 `PKToolPicker`
- 分享使用 `ShareLink`
- 文件导入使用 `fileImporter`
- 状态提示、菜单和确认使用 SwiftUI 系统组件

PDF 工作区、独立考试、词生文、作文和旧整篇日记 AI 整理已下线。升级所需模型与迁移保存在 `PaperClip/Persistence/Compatibility`，保持旧存储身份；历史数据和源 PDF 的保护要求不因功能下线而取消。

## 新增自定义实现的准入条件

同时满足以下全部条件才能新增自定义组件：

1. Apple 没有提供等价组件
2. 原生组件无法满足关键业务需求（不仅仅是样式不同）
3. 已评估辅助功能、Dynamic Type、深色模式、键盘、多窗口和系统手势
4. 维护成本可接受

代码注释或 PR 说明必须包含：检查过的原生 API、无法采用的具体原因、自定义实现承担的业务职责、已验证的无障碍与系统交互行为。

## 每次编写/修改代码时必须自检

- 是否有可直接替代的 SwiftUI 原生组件？
- 是否重复实现了导航、弹窗、菜单、分享、导入、搜索或手写工具？
- 是否优先使用了 SF Symbols？
- 是否保留了系统默认手势和平台行为？
- 是否支持 VoiceOver、Dynamic Type、深色模式和 iPad 多窗口？
- 是否存在不必要的 UIKit 包装层？
- 自定义实现是否有明确且可验证的业务理由，且代码集中可维护？

发现可用原生方案替代的代码，直接替换，不保留两套并行实现。

## 禁止事项

- 禁止自制画笔选择器、颜色选择器或粗细选择器
- 禁止自制分享面板、文件选择器、搜索框、日期选择器、系统弹窗或导航栏
- 禁止用自定义图形替代 SF Symbols（品牌资产除外）
- 禁止仅为改变圆角/阴影/颜色而重写系统控件
- 禁止在未说明原生方案缺陷的情况下引入新自定义手势
- 禁止修改系统手势后不验证 Apple Pencil、手指滚动和缩放行为

## 验证清单

涉及 UI 或交互的改动，提交前必须验证：

- [ ] iPad 真机或模拟器布局
- [ ] Apple Pencil 与手指输入分流
- [ ] 图片框选与文档扫描
- [ ] 深色模式
- [ ] 横竖屏 / 窗口尺寸变化
- [ ] VoiceOver 标签
- [ ] 数据保存后重新打开的恢复
- [ ] 原 PDF 文件未被修改
- [ ] 设备 SDK 完整编译无错误
