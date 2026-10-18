# PaperClip

面向 iPadOS 26 的本地学习应用。

## 当前实现

- SwiftData 词集、句集与文件夹，条目编辑、搜索、删除和 AI 拆分；
- 文件或粘贴文本导入，支持 Tab、每两行一组和 CSV 逗号分隔，支持重复项处理；
- 标准 FSRS-6 双向记忆调度：21 参数、目标保持率、短期学习/重学步进、间隔扰动和完整复习日志；
- 闪卡、词块学习、语境浏览、常规／调试测验、系统发音和 Apple Pencil 手写拼写／英文释义；
- 日记、知识点提取与解析、按学科浏览知识库；
- 今日 ENG 统计、应用／阅读主题、整库备份与恢复。

闪卡和语境浏览只用于当前轮学习，不更新 FSRS 或成绩；词块学习和常规手写测验写入学习记录。未完成的手写测验目前没有退出后续做功能。

错题库、PDF 做题、独立考试、词生文、作文和旧整篇日记 AI 整理已下线。V6 升级会清除错题记录与附件；升级前请先从“设置 → 数据备份”保存整库备份。其它历史存储兼容声明集中在[兼容层说明](PaperClip/Persistence/Compatibility/README.md)。

## 开发环境

- Xcode 26.5
- Swift 6
- 最低系统版本 iPadOS 26.0
- 仅支持 iPad

打开 `PaperClip.xcodeproj`，选择 iPadOS 26 模拟器或真机运行。

## AI 解析配置

在应用的“设置 → AI 解析设置”中填写所需 API Key。密钥仅保存在设备 Keychain 中。

## 验证

执行 `bash Tests/run-pure-swift-tests.sh` 运行逻辑、持久化和旧库兼容测试。
使用项目支持的 iPad SDK 完整构建；真实 PencilKit 交互按 [iPad 验收清单](Tests/MANUAL_IPAD_QA.md) 验证。
