# Kongo 产品战略与技术路线图

> 撰写时间：2026-03  
> 本文档记录了一次完整的产品战略讨论，涵盖产品定位、AI 接入路线、数据导入策略、云同步方向，以及各项决策的推理过程。  
> 这是当前阶段的事实决策文档，应优先于 `AI_INTEGRATION_ANALYSIS.md` 中的旧分析。

---

## 一、产品定位

### 核心定位

**Kongo 是个人职业人脉的长期资产管理工具——数据归你，关系是你的。**

### 与同类工具的本质区别

| 工具 | 本质 | 根本缺陷 |
|------|------|---------|
| 企业微信 / Salesforce | 公司 CRM | 数据归公司，离职清零；管理员可见所有沟通 |
| 手机通讯录 | 联系方式存储 | 无 context，无互动历史 |
| 微信 | 即时通讯 | 碎片化，无法跨时间沉淀 |
| Excel / Notion | 手动维护 | 无结构，更新全靠自律 |
| LinkedIn | 弱关系展示 | 无法记录深度互动，互动历史不归你管 |

**没有任何现有工具在做"跨越职业生涯的个人关系资产管理"**——这是 Kongo 的核心空白地带。

### 目标用户

主要面向**有主动经营个人人脉需求的个人用户**：

- 销售总监 / BD / 猎头：人脉是核心生产资料，跨越多家公司积累
- 创业者 / 合伙人：每个联系人背后都有数年故事，不能丢
- 有职业规划意识的个人：希望自己的关系网络随时间增值而非贬值

买单人是**个人**，不是公司。这和企业微信不是竞争关系，是两个完全不同的市场。

### "本地优先"的含义

采用**含义一**：数据存储在用户本机，不依赖 Kongo 服务器。允许用户自行授权第三方服务（如 Outlook），数据从第三方直接拉到本地，不经 Kongo 服务器中转。AI 调用使用用户自己的 API key，Kongo 不做 AI 代理。

---

## 二、核心交互模型：AI 秘书视图

### 产品原点

本产品源自一个明确的需求：**AI 能像私人秘书一样，为用户主动处理人际关系**。

这决定了 Kongo 的核心交互模型不是"用户操作数据库"，而是"秘书在等你"。

### 两种模式的本质区别

| 档案室模式（放弃）| 秘书模式（选定）|
|----------------|--------------|
| 用户打开 app → 看数据 → 找联系人 → 看洞察 | 用户打开 app → 秘书已经准备好了今天需要做的事 |
| AI 是功能点缀 | AI 是主入口 |
| 用户拉取信息 | 秘书主动推送 |

### 首页形态：结构化 Briefing 卡片（方向 X）

首页不再是"工作台数据摘要"，而是**秘书的每日简报**：

```
──────────────────────────────
  今日简报（3月26日 星期四）
──────────────────────────────
  [!] 张三：45天未联系，今天有共同会议
      → 查看张三  → 标记已处理

  [生日] 李四生日还有2天
      → 记录跟进建议

  [待跟进] 王五上周会议有2个未完成事项
      → 查看详情
──────────────────────────────
```

每条卡片均可操作，用户逐条响应。这是**方向 X**（结构化卡片）——简报由 AI 生成结构化 JSON，前端渲染为可操作卡片。

**对话式助手（方向 Y）** 作为长期演进方向预留，不在当前迭代实现。Y 方向需要完整的对话状态机，是独立的大型项目。方向 X 的组件设计应预留升级接口。

### 主动推送架构预留

秘书的核心是**主动**，不是被动等用户打开 app。近期实施计划中需同步预留：

- 定时任务触发器（每日生成 briefing，不依赖用户打开 app）
- 系统通知推送（macOS / Windows 桌面通知）
- briefing 缓存机制（同日只生成一次，避免重复调用）

---

## 三、AI 接入路线

### 现有基础设施（已完成，无需重建）

以下内容已在代码库中全部实现，与旧版 `AI_INTEGRATION_ANALYSIS.md` 的"缺失"列表不符：

- `AiProvider` 抽象接口（`lib/ai/ai_provider.dart`）
- `AiService` + `DefaultAiService` 编排层（`lib/ai/ai_service.dart`）
- `MockAiProvider` 测试双（`lib/ai/mock_ai_provider.dart`）
- `AiJob` / `AiOutput` 模型（`lib/models/ai_job.dart`）
- `SqliteAiJobRepository` 持久化层（`lib/repositories/ai_job_repository.dart`）
- `ai_jobs` / `ai_outputs` 数据库表（已在 schema 中）
- `AppDependencies` 中的 `DefaultAiService` 布线（但 `provider: null`，即 `isAvailable = false`）
- `Provider<AiService>` 已在 widget tree 中

**唯一阻塞实际 AI 调用的缺口**：没有真实的 HTTP provider 实现 + 没有设置页让用户填写 API key。

### AI Provider 策略：预设列表 + 自定义

设置页提供预设 provider 选项，用户选择后只需填对应 API key，baseUrl 自动填充：

| Provider | baseUrl | 默认模型 |
|----------|---------|---------|
| 硅基流动 | `https://api.siliconflow.cn/v1` | `deepseek-ai/DeepSeek-V3` |
| DeepSeek 官方 | `https://api.deepseek.com/v1` | `deepseek-chat` |
| 通义千问（DashScope） | `https://dashscope.aliyuncs.com/compatible-mode/v1` | `qwen-plus` |
| 自定义 | 用户填写 | 用户填写 |

所有 provider 均为 OpenAI 兼容格式，共用同一套 HTTP 实现（`OpenAiCompatibleProvider`），只是初始化参数不同。这是单一实现，不需要每个 provider 单独维护一个类。

### AI 功能接入优先级

#### Phase 1：AI 基础设施通路（前置，不可跳过）

1. `pubspec.yaml` 新增 `http` 依赖
2. 实现 `OpenAiCompatibleProvider`（`lib/ai/openai_compatible_provider.dart`）
3. 设置页新增"AI 能力"section：provider 选择 + API key 输入（带密码遮罩）+ 连接测试按钮
4. API key 使用 `flutter_secure_storage` 存储（macOS Keychain / Windows Credential Store 自动适配，跨平台）
5. `AppDependencies.bootstrap()` 启动时从存储读取配置，有 key 则初始化 provider

#### Phase 2：首页智能日报（高频、高感知、首选落地点）

**场景**：用户每天打开 app，首页展示一段 AI 生成的"今日行动建议"，基于当天事件、近期里程碑、未完成行动项。

**呈现形式**：混合风格（C 方案）——一句引导语 + 下方可交互的建议卡片列表（每条卡片可点击跳转到对应联系人/事件）。

AI 输出结构化 JSON，格式如：
```json
{
  "summary": "今天有 2 个会议，建议重点跟进张三",
  "items": [
    { "type": "follow_up", "contactId": "...", "reason": "45天未联系，上次谈到项目X" },
    { "type": "milestone", "contactId": "...", "reason": "李四生日还有3天" }
  ]
}
```

**缓存策略**：按当天日期缓存，同一天只生成一次；对 `HomeReadModel` 做 hash，数据无变化时复用前一条；异步生成不阻塞页面加载。

**技术路径**：
- `HomeProvider` 新增 `generateDailyBrief()` 方法
- 首页新增 `AiDailyBriefCard` widget（折叠展开，loading 骨架态）
- `HomeReadService` 已有所需上下文，无需改动

#### Phase 3：联系人关系洞察（产品核心差异化）

**场景**：联系人详情页，AI 根据该联系人的事件历史、备注、标签、里程碑，生成跟进提示和关系摘要。

**呈现位置**：详情页顶部折叠卡片，默认收起，标题显示"AI 洞察 · 数据截至 YYYY-MM-DD"，点击展开。

**持久化**：AI 输出存入 `ai_outputs`（outputType=`contact_insight`，targetId=contactId）。有新事件后标记缓存失效，用户手动点"刷新"重新生成。

**实现路径**：
- `ContactDetailProvider` 新增 `generateInsight()` 方法
- 新增 `ContactInsightSection` widget
- `ContactDetailReadModel` 上下文已完整（contact + tags + events + milestones），无需 schema 变动

#### Phase 4：事件"会后补充"（降低记录摩擦的关键）

**场景**：事件在当前时间之后出现"会已结束"状态时，事件详情页顶部出现一条提示横幅，附带单行快速备注输入框。用户一句话，AI 帮结构化为备注 + 可能的行动项。

**设计原则**：把"会后记录"从"创建新内容"降级为"补全已有骨架"，摩擦大幅降低。

#### Phase 5（长期）：系统托盘 / 菜单栏快捷捕获

macOS 菜单栏 / Windows 系统托盘驻留，全局快捷键（`⌘⇧K`）唤起两行浮窗：

```
会议/通话记录（一句话）：___________
涉及的人：___________
```

AI 后台结构化处理，用户无需打开主 app。

**包支持**：`tray_manager`（托盘/菜单栏）+ `hotkey_manager`（全局快捷键）+ `window_manager`（多窗口），三个包均支持 macOS + Windows，Flutter 实现，95% 代码共用。

---

## 三、数据入口策略

### 核心问题

用户的关系数据散落在微信、Outlook、手机通讯录，没有任何工具帮助他们把这些整合到一个地方。Kongo 的 onboarding 成败取决于：**用户第一次打开 app 能不能把存量数据导进来**。

### 数据入口优先级

#### 入口一：Microsoft Outlook + Teams 日历（最高价值）

Teams 会议本质上是 Outlook 日历事件，接入 Microsoft Graph 即同时获得两者。

- **授权方式**：Azure AD 注册应用 → OAuth 2.0 → `flutter_web_auth_2` 包处理本地回调（localhost 监听或 URL scheme）
- **数据来源**：`/me/calendarView`（含 Teams 会议）+ `/me/events/{id}/attendees`（参与人 → 联系人池）+ `/me/contacts`（Outlook 通讯录）
- **权限 scope**：`Calendars.Read Contacts.Read User.Read offline_access`（仅读取，无写操作）
- **关键价值**：会议 attendees 是企业用户真实互动过的人，比任何手动录入都准确
- **跨平台**：macOS + Windows 均可，纯 HTTP + OAuth，无原生代码

#### 入口二：vCard / CSV 文件导入（保底通用）

- iPhone 通讯录可导出 `.vcf`，Outlook 可导出 `.csv`
- 纯 Dart 解析，实现成本一天内可完成
- LinkedIn 导出（设置 → 数据隐私 → 获取数据副本 → `Connections.csv`）是高质量商业人脉来源

#### 入口三：文件拖拽 + AI 解析（兜底所有漏网信息）

用户把任何文本/截图粘贴或拖入 Kongo，AI 提取联系人/事件/待办，用户确认后写入。

**关键原则：AI 提取后必须经用户确认，不能自动写入**——一次识别错误会污染联系人库。

`desktop_drop` 包支持 macOS + Windows + Linux，无原生代码。

#### 入口四：企业微信通讯录（B 端定向功能，后期）

- 个人用户无法导出企业微信通讯录（平台刻意封闭）
- 企业管理员可通过企业微信 API 获取通讯录
- 适合作为 B 端付费集成功能，不作为标准功能

#### 引导式 Onboarding（首次启动）

用户装完 Kongo 面对空列表会直接关掉。需要一个引导流程解决冷启动问题：

```
第一步：欢迎页 → "先把你认识的人导入"
第二步：选项卡
    ├── 连接 Outlook（主推，一键授权）
    ├── 导入 vCard / CSV 文件
    ├── 拖入名片照片 / 截图（AI 识别）
    ├── 手动添加第一个联系人
    └── 暂时跳过
第三步：导入完成 → 跳到首页日报
```

---

## 四、用户行为设计：如何驱动持续记录

### 根本问题

单靠功能无法改变用户行为。用户在 Teams/Outlook 里开会，没有理由中途离开切换到 Kongo 记录。

### 解法：会前价值倒逼会后记录

这是行为科学中的"完成循环"效应——如果 Kongo 在**会议开始前**就给了用户价值（如联系人洞察显示"你们上次讨论了 X，距今 40 天"），用户在会议里占到了便宜，会有强烈的心理冲动更新这条信息。

**联系人洞察和首页日报不只是 AI 功能，它们是催生"会后记录"习惯的钩子。Kongo 先给，用户才想还。**

### 行为闭环

```
会前：首页日报 / 联系人洞察 → 用户在会议中获得价值
会中：事件已建，骨架已在（参与人自动从日历同步）
会后：事件详情"补充备注"横幅 → 一行快速输入
次日：首页日报回显昨天的记录和今日建议 → 正向强化
```

每个 AI 接入点都在加固这个行为闭环。

---

## 五、云同步决策

### 决策

**确认引入云同步，支持 PC 端与移动端数据同步。** 这是本次讨论的明确结论。

### 同步方案路线图

| 用户群 | 同步方案 | 实现时机 |
|--------|---------|---------|
| macOS + iOS（Apple 用户） | iCloud 文件同步，改路径即可 | Phase 2 |
| 跨平台（含 Windows） | 自选同步后端（PocketBase / Supabase / 自托管），设置页填 server URL | Phase 3 |
| 不需要同步 | 纯本地，完全不受影响 | 始终支持 |

### 立即要做的一件事：Schema 预埋

云同步与否，现在就需要在各核心表补充以下字段，避免日后大规模迁移：

```sql
-- 在 contacts / events / daily_summaries / tags / attachments 等核心表添加：
updated_at  INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)  -- Unix 毫秒
deleted_at  INTEGER  -- NULL = 存活，有值 = 软删除
```

**`updated_at`**：冲突解决的基础，最后写入者胜（last-write-wins）。  
**`deleted_at`**：软删除，防止"你删我补"的同步循环。现有的硬删除查询需要增加 `WHERE deleted_at IS NULL` 过滤。

这两个字段对当前功能零影响，现在处理成本最低。

---

## 六、跨平台边界确认

所有功能均在 macOS + Windows 成立，无需维护两套逻辑：

| 功能 | macOS | Windows | 实现方式 |
|------|-------|---------|---------|
| 首页日报 / 联系人洞察 | ✅ | ✅ | 纯 Flutter |
| AI HTTP 调用 | ✅ | ✅ | `http` 包，纯 Dart |
| API Key 安全存储 | ✅ Keychain | ✅ Credential Store | `flutter_secure_storage` 自动适配 |
| Outlook 日历 / 通讯录 | ✅ | ✅ | Microsoft Graph HTTP + OAuth |
| vCard / CSV 导入 | ✅ | ✅ | 纯 Dart 文件解析 |
| 文件拖拽解析 | ✅ | ✅ | `desktop_drop` |
| 系统托盘（菜单栏） | ✅ 菜单栏 | ✅ 任务栏托盘 | `tray_manager` |
| 全局快捷键 | ✅ | ✅ | `hotkey_manager` |
| iCloud 同步 | ✅ | ⚠️ 不稳定 | 平台路径差异，Windows 用通用后端替代 |

**WidgetKit 桌面小组件**已从路线图中排除：需要 Swift 原生扩展，无法用 Flutter 实现，且无 Windows 对应方案。

---

## 七、实施路线图

### 近期（当前迭代）

1. **Schema 迁移**：各核心表补 `updated_at` / `deleted_at`，并在 repository 层统一软删除查询
2. **AI 基础通路**：`OpenAiCompatibleProvider` + 设置页 AI 配置 section + `flutter_secure_storage` 密钥存储
3. **首页日报**：`HomeProvider.generateDailyBrief()` + `AiDailyBriefCard` widget（混合呈现风格）

### 中期

4. **联系人关系洞察**：`ContactDetailProvider.generateInsight()` + `ContactInsightSection` widget
5. **Outlook 日历 + 通讯录接入**：Microsoft Graph OAuth + 事件/联系人同步
6. **Onboarding 引导流程**：首次启动的导入选项页

### 长期

7. **会后补充横幅**：事件详情页的快速记录入口
8. **系统托盘快捷捕获**：全局唤起浮窗
9. **iCloud / 通用后端云同步**：分平台实现

---

## 八、关键决策索引

| 决策 | 结论 |
|------|------|
| 核心交互模型 | 秘书模式（方向 B）：AI 是主入口，主动推送，不是辅助工具 |
| 首页形态 | 结构化 briefing 卡片（方向 X），预留升级对话式助手（方向 Y）接口 |
| AI provider 形式 | 预设列表 + 自定义，用户填 API key |
| 首选 AI provider | 硅基流动（DeepSeek 模型）+ 同时支持 DeepSeek 官方 / 通义千问 / 自定义 |
| AI provider 实现 | 单一 `OpenAiCompatibleProvider`，所有 provider 共用 |
| 首页日报呈现 | 混合风格：引导语 + 可交互卡片列表（C 方案） |
| 本地优先含义 | 含义一：数据在本机，不依赖 Kongo 服务器；允许用户授权第三方服务 |
| 云同步 | 确认引入；近期 schema 预埋 `updated_at` + `deleted_at` |
| 云同步方案 | 分平台：Apple 生态用 iCloud，跨平台用自选后端 |
| 日历接入 | Outlook + Teams（Microsoft Graph），优先于 Google Calendar |
| 通讯录接入 | Outlook 通讯录（随日历 OAuth 免费带来）+ LinkedIn CSV + vCard |
| 企业微信 | 排除个人用户路线；企业管理员 API 作为后期 B 端付费功能 |
| 桌面小组件 | 排除（无法用 Flutter 实现，无跨平台方案） |
| 竞争定位 | 不与企业微信竞争；目标是个人职业人脉长期资产管理 |
