# PaperClip 开发约束

本文件适用于整个仓库。所有新增功能、重构、修复和代码审查都必须遵守以下规则。

## 1. 原生优先原则

实现任何界面、交互或系统能力前，必须先检查 Apple 是否已提供对应 API。

技术选型优先级：

1. SwiftUI 原生组件；
2. Apple 官方框架组件，包括 UIKit、PDFKit、PencilKit、SwiftData、UniformTypeIdentifiers 等；
3. 官方组件的轻量组合；
4. 仅在没有等价系统能力时使用自定义实现。

不得为了视觉差异、个人偏好或短期实现方便，重新实现系统已有能力。

## 2. 必须优先使用的系统能力

以下功能存在系统实现时，禁止自行重新实现：

- 导航：`NavigationStack`、`NavigationSplitView`、系统 Toolbar；
- 菜单与操作：`Menu`、`contextMenu`、`Command`、系统 Button Style；
- 弹窗与确认：`alert`、`confirmationDialog`、`sheet`、`popover`；
- 文件导入导出：`fileImporter`、`fileExporter`、`FileDocument`；
- 分享：`ShareLink`、`Transferable`；
- 搜索：`searchable`；
- 空状态：`ContentUnavailableView`；
- 表单：`Form`、`Section`、`Picker`、`Slider`、`Toggle`、`TextField`；
- 日期和颜色选择：`DatePicker`、`ColorPicker`；
- PDF 阅读：PDFKit；
- 手写、颜色、粗细、橡皮、套索：PencilKit 的 `PKCanvasView` 和 `PKToolPicker`；
- 数据持久化：SwiftData 或 Apple 官方持久化框架；
- 系统图标：SF Symbols；
- 辅助功能、动态字体、深色模式和系统手势。

禁止在 SwiftUI 已提供等价能力时，仅为调用 UIKit 而创建 `UIViewControllerRepresentable` 或 `UIViewRepresentable` 包装。

## 3. 自定义组件准入条件

只有同时满足以下条件，才能新增自定义 UI 或手势实现：

1. Apple 没有提供等价组件；
2. 原生组件无法满足关键业务需求，而非仅仅样式不同；
3. 已明确评估辅助功能、Dynamic Type、深色模式、键盘操作、多窗口和系统手势；
4. 自定义实现的维护成本与风险可接受。

新增自定义实现时，代码注释或交付说明必须包含：

- 检查过的原生 API；
- 无法采用原生 API 的具体原因；
- 自定义实现承担的业务职责；
- 已验证的无障碍和系统交互行为。

如果无法说明上述内容，应回退到系统原生方案。

## 4. 实施顺序

每项 UI 或交互任务必须按以下顺序执行：

1. 查阅当前项目最低系统版本对应的 Apple API；
2. 确认是否已有 SwiftUI 原生组件；
3. 确认是否已有 Apple 官方框架组件；
4. 优先通过系统修饰器、容器和组合实现需求；
5. 仅在原生方案确实无法满足时设计自定义实现；
6. 完成后检查是否存在重复实现系统能力的代码；
7. 使用项目支持的设备 SDK 完整编译。

## 5. 代码审查清单

每次审查 UI、交互或平台能力变更时，必须检查：

- 是否存在可直接替代的 SwiftUI 原生组件？
- 是否存在对应的 Apple 官方框架 API？
- 是否重复实现了系统导航、弹窗、菜单、分享、导入、搜索或手写工具？
- 是否优先使用 SF Symbols？
- 是否保留系统默认手势和平台行为？
- 是否支持 VoiceOver、Dynamic Type、深色模式和 iPad 多窗口？
- 是否存在不必要的 UIKit 包装层？
- 自定义实现是否有明确且可验证的业务理由？
- 自定义实现是否集中、可维护，且没有散落在业务页面中？

发现可使用系统原生能力替代的实现时，应直接使用原生方案，不保留两套并行实现。

## 6. PaperClip 当前允许的自定义实现

以下能力目前没有符合需求的系统等价实现，可以保留自定义代码：

- 可创建、移动并通过边角调整范围的错题框选；
- 跟随 PDF 页面坐标、独立持久化且不修改原 PDF 的答题图层；
- 可移动、可调整尺寸的浮动草稿板容器；
- 错题卡业务展示；
- A4 错题集的业务排版和 PDF 生成。

即使属于允许自定义范围，也应继续使用系统基础能力：

- 答题与草稿板使用 `PKCanvasView`；
- 画笔工具使用 `PKToolPicker`；
- PDF 显示和坐标转换使用 PDFKit；
- 分享使用 `ShareLink`；
- 文件导入使用 `fileImporter`；
- 状态提示、菜单和确认使用 SwiftUI 系统组件。

## 7. 禁止事项

- 禁止自制系统已有的画笔选择器、颜色选择器或粗细选择器；
- 禁止自制分享面板；
- 禁止自制文件选择器；
- 禁止自制搜索框、日期选择器、系统弹窗或导航栏；
- 禁止用自定义图形替代已有的 SF Symbols，除非属于品牌资产；
- 禁止仅为改变圆角、阴影或颜色而重写系统控件；
- 禁止在没有说明原生方案缺陷的情况下引入新的自定义手势；
- 禁止修改系统默认手势后不验证 Apple Pencil、手指滚动和缩放行为。

## 8. 验证要求

涉及 UI 或交互的改动至少需要验证：

- iPad 真机或对应模拟器布局；
- Apple Pencil 与手指输入分流；
- PDF 滚动和缩放；
- 深色模式；
- 横竖屏或窗口尺寸变化；
- VoiceOver 标签；
- 数据保存和重新打开后的恢复；
- 原 PDF 文件未被修改；
- 设备 SDK 完整编译无错误。
