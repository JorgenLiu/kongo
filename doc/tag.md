任务 1：DB Schema DDL
文件： database_schema.dart

 末尾添加：
验收： 常量可被迁移文件引用，无语法错误

任务 2：DB 迁移 v10 → v11
文件： database_migrations.dart，database_service.dart

 database_migrations.dart onUpgradeDatabase 末尾加：
 添加迁移函数：
 database_service.dart：
databaseVersion 改为 11，加常量：
验收： flutter analyze 无错误；重新运行 flutter test test/config/ 中的 DB 初始化测试不报错

任务 3：InfoTag 模型
文件： lib/models/info_tag.dart（新建）

验收： flutter analyze 无错误

任务 4：InfoTagRepository
文件： lib/repositories/info_tag_repository.dart（新建）

 抽象接口：
 SqliteInfoTagRepository 实现：
findOrCreate：先按 name 查，存在则返回，不存在则 insert（uuid.v4(), name, now）
addToContact：insert into contact_info_tags，ConflictAlgorithm.ignore
getForContact：JOIN 查询返回 List<InfoTag>
getNamesByContactIds：批量 JOIN 查询返回 Map<contactId, List<String>>（供 ContactRepository 使用）
验收： flutter analyze 无错误

任务 5：InfoTagService
文件： lib/services/info_tag_service.dart（新建）

实现：遍历 names，对每个 name 调 findOrCreate，再调 addToContact(contactId, tag.id, source: 'ai')。空 names 直接返回。

验收： flutter analyze 无错误

任务 6：Contact 模型加 infoTags
文件： contact.dart

 构造、fromMap、toMap、copyWith 均加 infoTags: List<String>, 默认 const []
fromMap 不从 map 读取（由 repository 注入），默认空列表即可
toMap 不序列化（不是 contacts 表的列）
验收： flutter analyze 无编译错误；现有 Contact.fromMap 调用无需修改

任务 7：ContactRepository 批量加载 infoTags
文件： contact_repository.dart

 添加私有方法，与 _loadTagsByContactIds 结构相同：
 _hydrateContacts：在 tagsByContactId 之后调 _loadInfoTagsByContactIds，传入 Contact.fromMap(..., infoTags: infoTagsByContactId[id] ?? [])
 getById：类似地单条加载（简化：可用 _loadInfoTagsByContactIds(db, [id]) 再取第一项）
验收： flutter test test/repositories/ 全部通过

任务 8：AppDependencies 注册
文件： app_dependencies.dart

 加 final InfoTagRepository infoTagRepository 和 final InfoTagService infoTagService
 bootstrap 中实例化并注入：
验收： flutter analyze 无错误；flutter run -d macos 启动不报错

任务 9：QuickCaptureService 加 aiMetadata 参数
文件： quick_capture_service.dart

 saveNote 签名加 Map<String, dynamic>? aiMetadata
 insert 语句中 'aiMetadata': aiMetadata != null ? json.encode(aiMetadata) : null
验收： flutter analyze 无错误；现有调用不传该参数则默认 null，行为不变

任务 10：AI Prompt 重命名与精化
文件： quick_capture_router.dart

JSON schema 部分将 tags 字段整体替换为：

 prompt 中 schema 里 "tags": string[] | null → "contactInfoTags": string[] | null
 Field rules 段落：删除原来混合 domain/topic + contact attributes 的描述，替换为上述单一语义
 response 构建处：
response['tags'] → response['contactInfoTags']
raw key: parsed['tags'] → parsed['contactInfoTags']
验收： flutter analyze 无错误；flutter test test/services/quick_capture_router_test.dart 通过

任务 11：main.dart _handleSave 写入 infoTags
文件： main.dart

在 _handleSave 中：

 读取 infoTags：
 在确定 linkedContactId 后（create 或 link 均处理后）：
 saveNote 加 aiMetadata：
验收： flutter analyze 无错误

任务 12：Swift 确认 UI 信息标签区域
文件： QuickCaptureStatusItem.swift

 QuickCaptureViewController 加实例变量：
 showConfirm：在 contactAction 重置处之后加：
在 hasContact 判断之后（contactSection 之后），若 !pendingInfoTags.isEmpty 则：

 实现 buildInfoTagsSection() -> NSView：

顶部标签 NSTextField(labelWithString: "🏷 信息标签")，字体 size 11 secondaryLabel
横向 wrap 的 NSStackView（orientation = .horizontal, spacing = 4）
每个 tag name 生成一个圆角 NSButton（bezelStyle = .roundedRect / 自绘圆角 NSTextField）+ "×" 文字，action = infoTagDeleteTapped(_:)，tag 记 index
@objc func infoTagDeleteTapped(_ sender: NSButton) → 从 pendingInfoTags 移除对应条目 → 移除旧 section → 若还有标签则重建并插入 stack
 preferredContentHeight 加：

 buildButtonBar → confirm 按钮的 action confirmTapped 中，saveArgs 加：
 clearConfirmUI 或 resetToInput 中清理：
验收： 快速输入 "张丽，33岁，右附件占位" 后确认界面出现标签 "33岁" "右附件占位"，点 × 可删除，点确认后联系人绑定该标签

任务 13：更新 Router 测试
文件： quick_capture_router_test.dart

 将所有 response['tags'] / result['tags'] 断言改为 response['contactInfoTags'] / result['contactInfoTags']
验收： flutter test test/services/quick_capture_router_test.dart 全部通过

任务 14：联系人详情展示 infoTags（可选，建议随此任务一起做）
文件： lib/widgets/contact/contact_detail_info_tags_section.dart（新建），contact_detail_screen.dart

 新建 widget，渲染 infoTags: List<String> 为 Chip 行（复用 AppColors.cyan 调色，与 group tags 区分开）
 在 contact_detail_screen.dart 的 tag section 之后插入 ContactDetailInfoTagsSection(infoTags: data.contact.infoTags)，仅 infoTags.isNotEmpty 时渲染
验收： 联系人详情页有 infoTags 时可见标签行，无时不显示空区域
