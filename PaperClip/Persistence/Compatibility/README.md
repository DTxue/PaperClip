# 历史存储兼容层

此目录只保存升级旧版 SwiftData 数据库所需的历史声明，不包含已下线功能的界面或运行逻辑。

| 声明 | 保留原因 |
|---|---|
| PDFDocumentItem、HandwritingLayer、Exam* | 识别旧存储并执行既有 V3→V4 迁移 |
| MistakeCard、MistakePracticeLayer、ExportRecord | 读取最早版本数据库并执行既有 V1→V2 迁移 |
| PaperClipSchemaV2/V3/V5 错题模型 | 仅用于识别旧数据库；V5→V6 会删除错题记录、附件元数据和复习记录 |
| VocabularyGeneratedArticle、VocabularyArticleRecitationHistory | 识别旧词生文存储并执行既有 V3→V4 迁移 |
| WritingPrompt、WritingDraft、WritingReview | 识别旧作文存储并执行既有 V4→V5 迁移 |
| VocabularyTestDraft 与序列化载荷 | V5 仍保留旧草稿数据；当前测验不创建或恢复它们，用户删除所属词集时仍处理关联记录 |

错题库已永久退役。升级到 V6 前，应用会先生成整库安全备份；迁移会删除错题数据库实体，启动清理会删除 `Cards`、`Exports` 和 `MistakeAttachments` 专属目录。词汇、日记和知识库实体继续保留。

`PaperClipLegacySchemas.swift` 和 `PaperClipMigrationPlan.swift` 保存历史 schema 与升级步骤；现行 V6 和容器创建留在 `PaperClipSchema.swift`。

旧日记 AI 结果和知识点 `aiExamPattern` 仍属于现有模型存储结构，继续保留以免影响这些领域的数据。错题数据由 V6 定向迁移删除。

既有迁移会移除先前已退役的实体，因此从旧版升级前仍需整库备份。安全备份、恢复及中断恢复逻辑属于数据保护基础设施，不能按旧功能代码一并删除。

验证入口为 `Tests/run-pure-swift-tests.sh`：静态旧库 fixture、V1/V2 到 V6 迁移、非错题数据与外部草稿笔迹的保存／重新打开。静态旧库 fixture 不随普通测试重新生成。
