# Task Plan

## Goal
为 Kongo 的文件库模块继续落地增强 feature，在已完成排序与组合筛选的基础上补齐批量选择删除与深度预览能力，并保持现有 Provider / Screen / Widget 分层模式。

## Phases
- [completed] 梳理现状与首批 feature 切入点
- [completed] 确认设计与实现范围
- [completed] 实现首批文件库 feature
- [completed] 验证测试与更新文档
- [completed] 实现第二批文件库 feature（批量选择删除 + 深度预览）
- [completed] 验证第二批 feature 与更新文档

## Constraints
- 遵循现有架构：screens -> widgets/actions -> providers -> services -> repositories
- screen 文件保持薄层，新增交互优先放到 sibling actions 或 widgets
- 变更应尽量增量，不重写整个文件库模块
- 优先补齐文档已明确列出的缺口

## Open Questions
- 首批切入是排序、组合筛选、批量操作还是深度预览
- 是否需要同时补对应的 provider/widget 测试

## Decisions
- 首批文件库增强聚焦“排序 + 更完整筛选”，不在本轮引入批量操作或深度预览重构。
- 继续复用现有 `FilesOverviewScreen` 与 `FilesProvider`，以增量扩展方式落地。
- 过滤模型调整为“存储模式过滤 + 缺失来源开关”的组合模式。
- 排序优先提供文件名、更新时间、文件大小三个维度。
- 第二批文件库增强聚焦“批量选择删除 + 深度预览”，继续复用现有文件库总览页，不新增独立导航页。
- 批量删除仅对孤立附件开放，若所选文件仍存在关联，则在 UI 层明确阻止并提示。
- 深度预览优先复用已有 `snapshotPath`、`previewText`、`previewStatus` 与 `refreshAttachmentPreview` 能力，不新增新的预览生成管线。

## Verification
- `flutter analyze` 通过。
- `flutter test test/providers/files_provider_test.dart` 通过。
- `flutter test` 通过。
- 第二批 feature 验证：`flutter analyze` 通过。
- 第二批 feature 验证：`flutter test test/providers/files_provider_test.dart` 通过。
- 第二批 feature 验证：`flutter test` 通过（104 passed）。

## File Map
- Modify: `lib/providers/files_provider.dart`
- Modify: `lib/screens/files/files_overview_screen.dart`
- Modify: `lib/screens/files/files_overview_actions.dart`
- Modify: `lib/widgets/common/file_library_item_card.dart`
- Modify: `lib/widgets/files/file_preview_thumbnail.dart`
- Create: `lib/widgets/files/file_library_selection_bar.dart`
- Create: `lib/widgets/files/file_preview_dialog.dart`
- Modify: `test/providers/files_provider_test.dart`
- Potential Test: `test/widgets/...`（如有必要补文件库交互测试）

## Error History
- 暂无
