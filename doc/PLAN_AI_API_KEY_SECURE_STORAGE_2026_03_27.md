# AI API Key Secure Storage Design

> 日期：2026-03-27

## 目标

将当前明文保存在本地设置文件中的 AI API key 改造成平台安全存储方案，并保持现有 AI 配置流程与设置页使用路径尽量稳定。

本方案同时定义 macOS、iOS、Windows 三端的正式落点与工程边界，但实施优先级以 macOS 为第一阶段。

---

## 一、背景与问题

当前实现中，AI 配置由 `AiConfigStore` 统一读写，`apiKey` 与 provider、baseUrl、model 一起保存在 `settings_preferences.json` 中。

现状问题：

1. API key 以明文形式落盘
2. 配置导出、备份、诊断收集时存在误泄漏风险
3. 敏感配置与非敏感配置混在同一条存储链路中，后续扩展困难
4. 设置页默认回显完整 key，不符合安全交互预期

这套实现适合原型阶段，但不适合作为长期方案继续演进。

---

## 二、设计结论

### 2.1 总体方案

将 AI 配置拆成两层：

1. **非敏感配置层**
   - 保存 provider、baseUrl、model
   - 继续使用现有 `AiConfigStore`
   - 继续走 `SettingsPreferencesStore`

2. **敏感凭证层**
   - 只保存 API key
   - 新增 `AiSecretStore`
   - 各平台走系统安全存储能力

运行时再将两层结果合并为一份 `AiSettingsSnapshot` 或等价的运行时配置对象。

### 2.2 平台正式方案

#### macOS

- 使用 **Keychain**
- 通过原生 MethodChannel 与 Dart 层通信
- 作为第一优先实现平台

#### iOS

- 使用 **Keychain**
- 通过原生 MethodChannel 与 Dart 层通信
- 与 macOS 在能力模型上保持一致，但原生实现独立维护

#### Windows

- 使用 **Credential Manager / PasswordVault 等系统凭证能力**
- 通过原生 MethodChannel 与 Dart 层通信
- 若首期暂不落原生实现，只做接口预留，不允许回退到明文 JSON 持久化

### 2.3 明确不采用的方案

1. 不继续把 API key 存回 `settings_preferences.json`
2. 不做“安全存储不可用时自动回退到明文”的隐式降级
3. 第一阶段不引入第三方 secure storage 插件作为主方案
4. 第一阶段不做多 provider 多密钥并行缓存

---

## 三、架构方案

### 3.1 运行时边界

建议新增一条独立的 secret 存储链路：

1. `AiConfigStore`
   - 负责 provider / baseUrl / model
   - 不再负责 API key

2. `AiSecretStore`
   - 负责 API key 的读取、写入、清除
   - 对外暴露窄接口，不做通用 key-value secret 平台

3. `AiSettingsAssembler` 或在 `AiConfigStore` 中增加组装方法
   - 将 `AiConfigStore` 与 `AiSecretStore` 的结果合并为运行时快照

4. 设置页
   - UI 保持一个表单
   - 保存时分两段写入：
     - 非敏感配置 -> `AiConfigStore`
     - API key -> `AiSecretStore`

### 3.2 Dart 层接口建议

```dart
abstract class AiSecretStore {
  Future<String?> loadApiKey();
  Future<void> saveApiKey(String value);
  Future<void> clearApiKey();
  Future<bool> isSupported();
}
```

建议实现：

- `UnsupportedAiSecretStore`
- `MethodChannelAiSecretStore`

说明：

1. 当前需求只有 AI key，一开始保持窄接口更稳
2. 不要过早抽象成通用 secret kv store
3. `isSupported()` 用于设置页和迁移逻辑做显式判断

### 3.3 原生层职责

统一 channel 名建议：

- `kongo/ai_secrets`

建议支持的方法：

1. `loadApiKey`
2. `saveApiKey`
3. `clearApiKey`
4. `isSupported`

返回值保持简单：

- `loadApiKey` -> `String?`
- `saveApiKey` -> `void`
- `clearApiKey` -> `void`
- `isSupported` -> `bool`

---

## 四、平台细化设计

### 4.1 macOS

#### 存储介质

- Keychain

#### 推荐标识

- service: `kongo.ai`
- account: `default`

如果未来需要多 provider 多 key，再扩展 account 为 provider id；第一阶段不需要。

#### 原生实现职责

1. 从 Keychain 查询指定 service/account 的 secret
2. 写入或覆盖对应 secret
3. 删除对应 secret
4. 将系统错误转换成稳定的 channel error code

#### 设计原因

1. 当前主验证平台就是 macOS
2. Keychain 是系统级方案，安全边界清晰
3. 与桌面本地工具使用场景匹配

### 4.2 iOS

#### 存储介质

- Keychain

#### 标识建议

- service 与 account 与 macOS 保持一致，便于统一认知

#### 原生实现职责

1. 与 macOS 同样的四个 MethodChannel 方法
2. 不依赖 UI 层，不在 iOS 侧持有业务逻辑

#### 设计原因

1. 与 macOS 方案认知一致
2. 未来若扩展移动端 AI 功能，无需再推翻 Dart 层接口

### 4.3 Windows

#### 存储介质

- Credential Manager / PasswordVault / 系统凭证能力

#### 设计要求

1. 使用系统安全存储
2. 不允许因为首期未做完而悄悄回退到明文 JSON

#### 第一阶段建议

1. Dart 层接口与依赖注入先预留
2. 原生 Windows 实现可以在第二阶段落地
3. 在实现完成前，`isSupported()` 返回 false，设置页明确提示该平台当前不支持保存 API key

---

## 五、迁移策略

当前最重要的是从旧的明文配置迁移到安全存储。

### 5.1 迁移原则

1. 迁移只发生一次
2. 迁移成功后，旧明文字段必须清除
3. 新 secret store 中已有值时，以 secret store 为准
4. 不做无感的明文 fallback

### 5.2 迁移流程

应用启动时：

1. 读取现有 `AiConfigStore`
2. 判断旧字段 `ai_api_key` 是否有值
3. 读取 `AiSecretStore.loadApiKey()`
4. 若 secret store 为空且旧明文字段存在：
   - 写入 secret store
   - 写入成功后删除旧明文字段
5. 若 secret store 已有值：
   - 删除旧明文字段
6. 若 secret store 不支持：
   - 不执行迁移写入
   - 保留旧字段仅读用于当前过渡版本显示或提示
   - 下一版本可进一步要求用户手动重新输入

### 5.3 风险控制

迁移必须遵循“先写后删”：

1. 先写入 Keychain / Credential store
2. 确认成功
3. 再删除 JSON 中旧字段

避免中途失败导致 key 丢失。

---

## 六、设置页交互设计

### 6.1 当前问题

当前 [lib/widgets/settings/ai_settings_section.dart](lib/widgets/settings/ai_settings_section.dart) 会把完整 API key 回填到输入框中。

这在切换到安全存储后不再合适。

### 6.2 推荐交互

设置页改为：

1. API key 输入框仍保留
2. 若本地已保存 key：
   - 不回显完整值
   - 显示状态文案：`已保存 API key`
3. 用户重新输入非空值时，视为覆盖保存
4. 提供“清除已保存密钥”动作
5. 若平台不支持安全存储：
   - 显示明确提示
   - 禁用“保存 API key”能力

### 6.3 保存行为

点击“保存配置”时：

1. 保存 provider/baseUrl/model 到 `AiConfigStore`
2. 若 API key 输入框非空，则保存到 `AiSecretStore`
3. 若用户点击“清除密钥”，则调用 `clearApiKey()`

注意：

1. 非敏感配置保存成功，不代表 secret 保存成功
2. UI 需要区分两类保存错误
3. 成功提示应是统一的，但日志与错误处理应分层

---

## 七、文件规划

### Create

- `lib/services/ai_secret_store.dart`
- `test/config/ai_secret_store_test.dart`
- `test/widgets/ai_settings_section_secure_storage_test.dart`

如果第一阶段同时做 macOS channel 绑定，则还需要：

- `macos/Runner/AiSecretStoreChannel.swift` 或等价文件

如果预留 iOS / Windows：

- `ios/Runner/AiSecretStoreChannel.swift`
- `windows/runner/ai_secret_store_channel.*`

### Modify

- `lib/config/ai_config_store.dart`
- `lib/widgets/settings/ai_settings_section.dart`
- `lib/services/app_dependencies.dart`
- `lib/main.dart`
- `lib/services/settings_preferences_store.dart`
- `test/config/ai_config_store_test.dart`
- `test/widgets/ai_settings_section_test.dart`

### Maybe Modify

- `macos/Runner/AppDelegate.swift`
- `ios/Runner/AppDelegate.swift`

仅当需要注册新 MethodChannel handler 时修改。

---

## 八、分阶段实施建议

### Phase 1：Dart 层解耦与 macOS 正式实现

目标：

1. 让 API key 脱离 JSON 明文存储
2. 在 macOS 上完成可用的 Keychain 存储
3. 不破坏现有 AI 设置页主路径

交付标准：

1. `AiConfigStore` 不再持久化 API key
2. `AiSecretStore` 可以在 macOS 下正常读写
3. 旧明文 key 能迁移到 Keychain
4. 设置页能显示“已保存 key”状态

### Phase 2：iOS / Windows 平台实现

目标：

1. 在保持 Dart 层不变的情况下新增原生实现
2. 各平台都能通过统一接口读写 secret

交付标准：

1. iOS Keychain 可用
2. Windows Credential Manager 可用
3. 不支持能力的平台有明确降级提示

---

## 九、详细任务拆分

### Task 1：抽离敏感配置边界

**Files:**

- Create: `lib/services/ai_secret_store.dart`
- Modify: `lib/config/ai_config_store.dart`

- [ ] 定义 `AiSecretStore` 抽象、unsupported 实现、method-channel 实现骨架
- [ ] 将 `AiConfigStore` 中的 API key 读写逻辑拆出
- [ ] 保留 provider/baseUrl/model 的现有行为不变
- [ ] 明确运行时如何合并非敏感配置与 secret
- [ ] Verify: `flutter analyze lib/config/ai_config_store.dart lib/services/ai_secret_store.dart`

### Task 2：调整运行时快照组装

**Files:**

- Modify: `lib/config/ai_config_store.dart`
- Modify: `lib/services/app_dependencies.dart`

- [ ] 让 `AiSettingsSnapshot` 支持由“普通配置 + secret”组合生成
- [ ] 更新 `AppDependencies.bootstrap()` 中 AI provider 加载逻辑
- [ ] 确保未保存 API key 时 provider 仍安全降级为 unavailable
- [ ] Verify: `flutter analyze lib/services/app_dependencies.dart`

### Task 3：实现 macOS Keychain 通道

**Files:**

- Create: `macos/Runner/AiSecretStoreChannel.swift`
- Modify: `macos/Runner/AppDelegate.swift`

- [ ] 新增 `kongo/ai_secrets` channel 注册
- [ ] 实现 `loadApiKey` / `saveApiKey` / `clearApiKey` / `isSupported`
- [ ] 将原生错误转成稳定 code/message
- [ ] Verify: macOS 工程无编译错误

### Task 4：实现 Dart MethodChannel secret store

**Files:**

- Create: `lib/services/ai_secret_store.dart`
- Test: `test/config/ai_secret_store_test.dart`

- [ ] 在 Dart 层封装 channel 调用
- [ ] 处理平台异常与 unsupported 平台行为
- [ ] 补充 fake / stub 测试
- [ ] Verify: `flutter test test/config/ai_secret_store_test.dart`

### Task 5：实现旧明文迁移

**Files:**

- Modify: `lib/config/ai_config_store.dart`
- Modify: `lib/services/settings_preferences_store.dart`
- Test: `test/config/ai_config_store_test.dart`

- [ ] 读取旧 `ai_api_key` 字段
- [ ] 若 secret store 为空则迁移写入
- [ ] 写入成功后删除旧字段
- [ ] secret store 已有值时直接清理旧字段
- [ ] Verify: `flutter test test/config/ai_config_store_test.dart`

### Task 6：重构 AI 设置页保存逻辑

**Files:**

- Modify: `lib/widgets/settings/ai_settings_section.dart`
- Test: `test/widgets/ai_settings_section_test.dart`
- Test: `test/widgets/ai_settings_section_secure_storage_test.dart`

- [ ] 设置页不再回显完整 API key
- [ ] 增加“已保存 key”状态提示
- [ ] 增加“清除密钥”动作
- [ ] 保存时拆成“配置保存”和“secret 保存”两步
- [ ] 平台不支持时给出明确提示
- [ ] Verify: `flutter test test/widgets/ai_settings_section_test.dart`

### Task 7：接入 main / provider 注入链路

**Files:**

- Modify: `lib/main.dart`
- Modify: `lib/services/app_dependencies.dart`

- [ ] 将 `AiSecretStore` 注入全局依赖
- [ ] 确保设置页与 app 启动都能拿到同一实例
- [ ] 保持现有 AI connection test 行为不回归
- [ ] Verify: `flutter analyze`

### Task 8：预留 iOS 接口与实现骨架

**Files:**

- Create: `ios/Runner/AiSecretStoreChannel.swift`
- Modify: `ios/Runner/AppDelegate.swift`

- [ ] 按 macOS 同样的 channel 接口预留 iOS 实现
- [ ] 第一版可只完成骨架或完整 Keychain 实现，取决于本轮范围
- [ ] 确保 Dart 层无需分叉逻辑

### Task 9：预留 Windows 接口与实现骨架

**Files:**

- Create: `windows/runner/ai_secret_store_channel.h`
- Create: `windows/runner/ai_secret_store_channel.cpp`
- Modify: `windows/runner/flutter_window.cpp` 或对应入口

- [ ] 预留 `kongo/ai_secrets` channel 注册
- [ ] 约定后续 Credential Manager 的实现入口
- [ ] 在未完成前使 `isSupported` 返回 false

### Task 10：补全回归验证

**Files:**

- Modify: impacted files only

- [ ] Run: `flutter test test/config/ai_config_store_test.dart`
- [ ] Run: `flutter test test/config/ai_secret_store_test.dart`
- [ ] Run: `flutter test test/widgets/ai_settings_section_test.dart`
- [ ] Run: `flutter test test/widgets/ai_settings_section_secure_storage_test.dart`
- [ ] Run: `flutter analyze`
- [ ] Run: `flutter test`

---

## 十、测试策略

### Dart 层

1. `AiConfigStore` 不再写入明文 API key
2. 迁移逻辑遵循“先写后删”
3. secret store 为空 / 已有值 / 不支持 三种路径都可测

### Widget 层

1. 设置页显示“已保存 key”而不是完整 key
2. 清除密钥后状态变化正确
3. 平台不支持时按钮禁用或提示明确

### 平台层

1. macOS Keychain 写入后可读回
2. 清除后不可再读取
3. channel error 能稳定回到 Dart 层

---

## 十一、风险与控制

1. **风险：** 迁移过程中 key 丢失
   **控制：** 先写 secret store，再删除旧 JSON 字段

2. **风险：** 安全存储不可用时继续默默明文保存
   **控制：** 明确禁止隐式 fallback

3. **风险：** 设置页仍然回显完整 key
   **控制：** UI 只显示“已保存”状态，不显示原值

4. **风险：** Windows / iOS 后续接入时需要重写 Dart 层
   **控制：** 现在就把 `AiSecretStore` 与 channel 协议定死

5. **风险：** 引入第三方插件导致原生集成不稳定
   **控制：** 第一阶段坚持自建薄 MethodChannel

---

## 十二、推荐执行顺序

推荐顺序如下：

1. 先做 `AiSecretStore` 抽象与 `AiConfigStore` 解耦
2. 再做 macOS Keychain 正式实现
3. 然后完成旧明文迁移
4. 再改设置页保存逻辑与 UI 状态
5. 最后补 iOS / Windows 预留或实现

原因：

1. macOS 是当前真实验证平台，先完成闭环最有价值
2. 先把架构边界和迁移规则锁住，再做 UI 改造，返工最少
3. iOS / Windows 可以在不改 Dart 层契约的前提下后续补齐