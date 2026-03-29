# 技术选型决策记录：2026-03-28

本文记录 2026-03-28 完成评估后确认的技术架构决策，重点包括跨平台框架选型、原生桥接方案、多端同步策略，以及输入解析的技术路线。

---

## 一、跨平台框架：Flutter（确认继续）

### 决策

继续使用 Flutter 作为主框架，覆盖 macOS、iOS、Windows。

### 评估过的替代方案

在 2026-03-28 的评估中，考虑了以下替代路线：

**候选：Tauri v2**
- 优势：原生 Webview，Rust 后端，产物体积小，Windows 体验接近原生
- 劣势（致命）：
  1. iOS/Android Widget（主屏幕小组件）是 open feature request，Tauri v2.10.3 当前**不支持**（GitHub issue #14555 仍然开放）
  2. Share Extension 同样需要原生 Swift 实现，Tauri 无官方路径
  3. CloudKit 同步无官方插件，需要从头实现 Swift 插件并通过 FFI 桥接
  4. WKWebView 稳定性社区反馈有活跃 issue（Tauri discuss #8524），特别是 macOS Ventura 下
  5. 迁移成本：现有 Flutter 代码库、测试覆盖、provider/repository 层不可直接复用

**候选：Electron + React**
- 劣势：包体积极大，iOS 无路径

### 为什么 Flutter 胜出

| 维度 | Flutter | Tauri |
|------|---------|-------|
| iOS Widget 支持 | ✅ flutter_home_widget 成熟 | ❌ 官方列为 roadmap，未实现 |
| iOS Share Extension | ✅ 可用 Swift Extension 共享 SQLite | ❌ 无官方路径 |
| iCloud CloudKit | ✅ community plugin 存在，也可直接 Swift | ❌ 需完整自制插件 |
| macOS 菜单栏 | ✅ NSStatusItem via MethodChannel（~2-3天）| ✅ 可实现，但 WKWebView 稳定性存疑 |
| 现有 codebase 迁移成本 | ✅ 无需迁移 | ❌ 全部重写 |
| 测试覆盖保留 | ✅ 178 个测试可直接沿用 | ❌ 全部重写 |

**结论**：Tauri 在 iOS Widget 和 Share Extension 上的缺失是战略性障碍，直接否决迁移。Flutter 继续作为唯一主框架。

---

## 二、macOS 菜单栏快捷捕获：Swift 原生桥接

### 方案

在 macOS 平台使用 Swift 原生代码实现菜单栏组件，通过 Flutter MethodChannel 与主 Flutter 应用通信。

### 技术组件

```
Swift 侧（原生）
├── NSStatusItem          <- 菜单栏图标
├── NSPopover             <- 输入浮窗（HTML/WebView 或原生 NSView，建议后者）
├── NSEvent addGlobalMonitorForEvents  <- 全局快捷键监听
└── MethodChannel 发送方  <- 将用户输入发给 Flutter

Flutter 侧
├── MethodChannel 接收方  <- 接收 quick capture 文本
├── QuickCaptureService   <- 解析人名 + 内容，写入 SQLite
└── 主窗口 Provider 刷新  <- 可选，通知 UI 更新
```

### 通信方式

两种可选方案，推荐方案 A：

**方案 A：MethodChannel（推荐）**
- Swift 调用 `channel.invokeMethod("quickCapture", arguments: text)`
- Flutter 接收后进入正常业务流程（解析 → 写 DB → 刷新 UI）
- 优点：与现有 Flutter 应用架构完全集成，无需额外进程

**方案 B：直接写 SQLite**
- Swift 侧直接写共享的 SQLite 文件
- 需要处理并发锁、schema 版本感知
- 仅在 Flutter 主进程不可用时作为 fallback

### 实现规模估算

- NSStatusItem + NSPopover：~0.5天
- 全局快捷键注册：~0.5天
- MethodChannel 联调：~0.5天
- 样式/交互打磨：~1天
- **合计：约 2-3 天**，一次性原生成本，后续维护极低

### 安全考量

- 全局快捷键监听需要 macOS 辅助功能权限（Accessibility）；在 entitlements 中声明
- 菜单栏不存储任何敏感信息，Quick Capture 文本仅写入本地 SQLite

---

## 三、输入解析：启发式规则（不用 LLM）

### 问题定义

用户输入：`"今天见了张伟，他说Q2预算可能削减三成"`

需要解析出：
- 人名：「张伟」
- 内容/备注：「Q2预算可能削减三成」
- 关联联系人：从联系人库中 fuzzy match「张伟」

### 技术方案

```
Step 1  联系人库 Fuzzy Match
        对输入文本进行滑窗扫描，与现有联系人姓名做相似度比较
        匹配到已有联系人 → 直接关联，置信度高

Step 2  启发式规则（未匹配到已知联系人时）
        中文规则：连续 2-4 个汉字，不属于常见停用词，判断为人名候选
        英文规则：首字母大写的单词或词组（如 "David" / "Dr. Chen"）
        结合上下文动词线索（"见了"、"跟XX说"、"和XX开会"）提升置信度

Step 3  单步确认
        当识别出新联系人（不在现有库中）时，弹出单步确认
        "是「张伟」吗？ [确认 · 修改]"
        确认后创建联系人记录，写入 Quick Capture 内容

Step 4  纯内容记录（无人名时）
        允许用户不指定联系人，内容作为通用备注保存
        之后可在 UI 中手动关联联系人
```

### 为什么不用 LLM 解析

- LLM 调用有网络依赖，菜单栏输入必须**离线可用**
- 人名识别的准确率：联系人库 fuzzy match > LLM 零样本推理
  （用户自己维护的 200 人库，fuzzy match 准确率极高）
- 隐私：用户输入的关系信息不应发送给外部服务
- LLM 保留用途：**用户已积累非结构化内容后的总结/摘要**，用户主动触发，但不用于实时解析

---

## 四、多端同步策略

### 设备矩阵与同步方案

| 设备组合 | 同步方案 | 状态 |
|----------|---------|------|
| macOS + iOS | iCloud CloudKit | P2 规划，需实施 |
| macOS 单机 | 本地 SQLite 无需同步 | 当前状态 ✅ |
| macOS + Windows | E2EE 中继服务器 | 延后，暂不实施 |

### iCloud CloudKit 方案（macOS + iOS）

**为什么选 CloudKit**：
- Apple 生态内置，用户无需额外账号
- 免费额度对个人用户充足
- Flutter 有 community plugin（`cloudkit_storage`），也可直接 Swift 桥接

**不用文件同步（iCloud Drive / OneDrive 的 SQLite 文件）的原因**：
- 多设备同时写入同一 SQLite 文件会导致数据库损坏
- CloudKit 的 record-level 同步才是正确方案

**CloudKit 同步的 schema 准备**：
- `deletedAt` 字段已在 schema v9 中存在 ✅（所有主表）
- 还需为每张主表添加 `lastModifiedAt`（写入时自动设置）
- CloudKit 记录使用 `uuid` 作为全局唯一 ID（现有 schema 已用 UUID）✅

**冲突解决策略（V1）**：
- Last-Write-Wins，以 `lastModifiedAt` 为准
- 删除记录：软删除（`deletedAt` 非空），不做物理删除
- 后续版本可引入 CRDT 或用户手动解决，但 V1 不过度设计

### Windows 同步（延后）

当需要支持 Windows 时：
- 方案：E2EE 中继服务器
  - 客户端在本地加密（AES-256）后上传加密 blob
  - 服务器只做存储转发，永不接触明文
  - 其他设备下载后在本地解密
- 加密密钥派生：从用户密码或 Apple/Google 账号 OIDC token 派生，不存储在服务器
- 此方案彻底规避 "Kongo 服务器看到用户关系数据" 的信任问题

---

## 五、AI 技术整合路线

AI 功能在技术架构上作为**可选后台层**实现，不嵌入核心数据流：

```
核心数据流（不依赖 AI）
  Quick Capture → 解析服务 → SQLite → Provider → UI

AI 增强层（可选，异步）
  用户触发 → AI 服务 → 读取联系人历史记录 → 生成摘要/简报 → 展示给用户
```

**AI 调用约束**：
- 所有 AI 调用必须用户主动触发（点击按钮），不允许后台自动发送
- 发送给 AI 的数据仅包含用户已在 Kongo 中明确记录的内容（非隐式采集）
- AI 服务密钥通过 iOS Keychain / macOS Keychain 存储，不存入 SQLite

**现有 AI 基础设施**：
- `lib/ai/ai_service.dart`：对话调用封装
- `lib/ai/ai_provider.dart`：Flutter provider 层
- `ios/Runner/AiSecretStoreChannel.swift`：iOS Keychain 桥接
- 以上均已落地，可直接复用于未来的会议摘要/关系回顾功能

---

## 六、现有架构的保留与延续

以下已落地的架构决策**保持不变**，无需修改：

| 层 | 现状 | 延续策略 |
|----|------|---------|
| SQLite + sqflite | schema v9，migrations 已有幂等性保护 | 继续沿用，添加 `lastModifiedAt` 时走现有 migration 流程 |
| Repository 层 | ContactRepo, EventRepo, TagRepo, AttachmentRepo 等已实现 | 新功能通过相同模式扩展 |
| Read Service 层 | `lib/services/read/` ContactReadService, EventReadService | Quick Capture 写入后触发 Provider 刷新，不绕过该层 |
| Provider 层 | BaseProvider, ProviderError; ContactProvider, EventDetailProvider 等 | 新的 QuickCaptureProvider 沿用相同基础设施 |
| 测试基础设施 | 178 个测试，sqflite_common_ffi 测试工具 | 新功能同样写单元测试和 widget 测试 |
| 分层边界 | screens → widgets/actions → providers → services/read → repos → models | 严格保持，Quick Capture 不绕过 |

---

## 七、技术风险与缓解

| 风险 | 可能性 | 缓解措施 |
|------|--------|---------|
| macOS 全局快捷键与其他 App 冲突 | 中 | 快捷键可用户自定义；默认选低冲突组合键 |
| CloudKit 同步首次集成复杂度高 | 中 | 单独作为 P2 Sprint，主功能不 block 在此 |
| 中文人名识别假阳性/假阴性 | 中 | 新联系人强制单步确认；误识别不会静默写入 |
| macOS entitlements / sandbox 限制 | 低 | 网络权限已在 v9 修复，NSStatusItem 无需额外 entitlement |
| Windows E2EE 密钥管理复杂度 | 高（当实施时）| 推迟到 Windows 支持阶段，届时单独评估方案 |

---

## 八、本文档与其他文档的关系

- 本文是 2026-03-28 技术选型的正式记录
- 产品方向背景见 `doc/PRODUCT_DIRECTION_2026_03_28.md`
- 同步相关的 schema 设计细节见 `doc/DATABASE_DESIGN.md`
- 分层架构规范见 `doc/DEVELOPMENT_GUIDE.md`
- 整体研发路线见 `doc/PROJECT_PLAN.md`
