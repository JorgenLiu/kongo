# Kongo 应用执行流程 - 快速参考

## 🚀 应用启动序列（30 秒快速版）

```
main()
  └─ print('🚀 应用启动...')
  └─ runApp(MyApp())
      └─ Flutter 框架初始化
          └─ MyApp.build()
              └─ MaterialApp(
                   home: ContactsListScreen()
                 )
                 └─ ContactsListScreen 创建
                     └─ initState()
                         ├─ 创建 TextEditingController
                         ├─ 调用 _initializeData()
                         │   └─ 创建 7 个 Contact 对象
                         └─ print('✅ 已初始化，共 7 个联系人')
                     └─ build()
                         ├─ Scaffold
                         ├─ AppBar
                         ├─ SearchBar
                         └─ ListView.builder
                             └─ 7 个 ContactCard
                                 ├─ 每个卡片有头像、名字、电话、标签
                                 └─ print('🧩 构建卡片...')
  └─ UI 显示在屏幕上
```

---

## 📊 类和对象的关系

```
MyApp (StatelessWidget)
  ↓
MyApp.build() 返回
  ↓
MaterialApp
  ↓
ContactsListScreen (StatefulWidget)
  ↓ 创建 State
  ↓
_ContactsListScreenState
  ├─ _searchController (TextEditingController)
  ├─ _allContacts (List<Contact>)  [7 个对象]
  ├─ _filteredContacts (List<Contact>)
  └─ build() 返回 Scaffold
      └─ body 包含 ListView.builder
          └─ itemBuilder 创建 ContactCard
              └─ 每个 ContactCard 需要一个 Contact 对象
```

---

## 🔄 用户交互流程

### 用户搜索：

```
用户在搜索框输入 "张"
  ↓
TextField.onChanged 触发
  ↓
_searchContacts("张") 被调用
  ↓
过滤 _allContacts，保留匹配的
  ↓
setState() 更新 _filteredContacts
  ↓
build() 自动重新执行
  ↓
ListView.builder 更新，只显示符合条件的卡片
  ↓
UI 更新，用户看到只有 "张三" 了
```

### 用户点击卡片：

```
用户点击 "张三" 的卡片
  ↓
InkWell.onTap 触发（涟漪效果）
  ↓
ContactCard.onTap 回调执行
  ↓
ScaffoldMessenger.of(context).showSnackBar(...)
  ↓
底部弹出 "点击了 张三"
```

---

## 💾 数据流

```
_allContacts (不变)
  [
    Contact(id:'1', name:'张三', phone:'138...', tags:['家人','同事']),
    Contact(id:'2', name:'李四', phone:'138...', tags:['朋友']),
    ...
  ]
        ↓
        用于显示和搜索
        ↓
_filteredContacts (会变)
  [
    显示的联系人...
  ]
        ↓
        ListView.builder itemBuilder
        ↓
        ContactCard (个数 = _filteredContacts.length)
        ↓
        UI 显示
```

---

## 🎯 关键方法速查

| 方法                | 所在类      | 触发时机           | 作用                   |
| ------------------- | ----------- | ------------------ | ---------------------- |
| `main()`            | 全局        | 应用启动           | 入口点，调用 runApp()  |
| `initState()`       | State       | Widget 创建时      | 初始化数据、创建控制器 |
| `build()`           | Widget      | 初始化或状态改变时 | 构建 UI                |
| `dispose()`         | State       | Widget 销毁时      | 清理资源               |
| `_initializeData()` | State       | initState 中调用   | 创建 7 个联系人        |
| `_searchContacts()` | State       | 搜索框文本改变时   | 过滤联系人             |
| `_buildAvatar()`    | ContactCard | build 中调用       | 构建头像 Widget        |
| `_buildTags()`      | ContactCard | build 中调用       | 构建标签 Widget        |

---

## 🧩 UI 层级树

```
MaterialApp
├─ theme: AppTheme.lightTheme
└─ home: ContactsListScreen
    └─ Scaffold
        ├─ appBar: AppBar
        │   ├─ title: Text('通讯录')
        │   └─ actions: [IconButton(sort)]
        │
        ├─ body: SafeArea
        │   └─ Column
        │       ├─ SearchBar
        │       │   └─ TextField
        │       │
        │       ├─ Padding
        │       │   └─ Text('7 个联系人')
        │       │
        │       └─ Expanded
        │           └─ ListView.builder (itemCount: 7)
        │               ├─ ContactCard #1
        │               │   └─ Card
        │               │       └─ InkWell
        │               │           └─ Padding
        │               │               └─ SizedBox (height: 75)
        │               │                   └─ Row
        │               │                       ├─ CircleAvatar
        │               │                       ├─ Column (info)
        │               │                       │   ├─ Text (name)
        │               │                       │   ├─ Text (phone)
        │               │                       │   └─ Wrap (tags)
        │               │                       └─ IconButton (more)
        │               │
        │               ├─ ContactCard #2
        │               └─ ... (共 7 个)
        │
        └─ floatingActionButton: FloatingActionButton(add)
```

---

## 🎬 控制台输出解读

```
┌─ 应用启动
├─ 🚀 ========================================
├─ 🚀 应用启动：Kongo - 通讯录和日程管理
├─ 🚀 ========================================
├─ ⏱️  启动时间: 2026-03-07 09:25:48.354826
│
├─ State 初始化
├─ 📱 ContactsListScreen.initState() 被调用
├─ ✅ 联系人列表屏幕已初始化，共 7 个联系人
│
├─ 第一次构建 UI
├─ 🎨 MyApp.build() 被调用
├─ 🎨 ContactsListScreen.build() 被调用，显示 7 个联系人
│
├─ 构建 7 个联系人卡片
├─ 🧩 构建联系人卡片: 张三 (ID: 1)
├─ 🧩 构建联系人卡片: 李四 (ID: 2)
├─ 🧩 构建联系人卡片: 王五 (ID: 3)
├─ 🧩 构建联系人卡片: 赵六 (ID: 4)
├─ 🧩 构建联系人卡片: 孙七 (ID: 5)
├─ 🧩 构建联系人卡片: 周八 (ID: 6)
├─ 🧩 构建联系人卡片: 吴九 (ID: 7)
│
└─ UI 显示完成，应用就绪
```

---

## 🔑 重要概念

### StatefulWidget vs StatelessWidget

```
StatelessWidget (无状态)
├─ 不会改变
├─ 只有 build() 方法
├─ 用于常量 UI：MyApp、AppBar 标题等
└─ 例：MyApp, AppBar, Icon, Text

StatefulWidget (有状态)
├─ 会改变（搜索、排序、输入等）
├─ 需要 State 类管理数据
├─ 有 initState(), build(), dispose() 等方法
├─ 通过 setState() 更新 UI
└─ 例：ContactsListScreen, TextField, Checkbox
```

### 状态管理流程

```
setState() 被调用
  ↓
setState 的回调函数执行
  ↓
状态变量被更新
  ↓
Flutter 标记 Widget "dirty"
  ↓
下一帧渲染时
  ↓
build() 被重新调用
  ↓
返回新的 Widget 树
  ↓
Flutter 比较新旧 Widget 树（Diffing）
  ↓
只更新改变的部分（Efficient Rendering）
  ↓
UI 更新到屏幕
```

### 为什么需要 initState？

```
late List<Contact> contacts;

// ❌ 不能这样做：
// contacts = [...];  // 全局初始化

// ✅ 应该这样做：
@override
void initState() {
  super.initState();
  contacts = [...];  // 在 initState 中初始化
}

原因：
- State 对象是延迟创建的（在 build() 调用时）
- 在 initState 前不能确保 context 存在
- 需要在 initState 中初始化依赖 context 的东西
```

---

## 📱 屏幕布局分析

```
┌─────────────────────────────────────┐
│ AppBar (蓝色，高度 56)             │ ← elevation: 0 (无阴影)
│ 通讯录          [排序按钮]         │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [🔍 搜索框]               [✕]   │ │ ← SearchBar
│ └─────────────────────────────────┘ │
│ 7 个联系人                          │ ← 计数文本
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ ┌─────┐  张三      ⋮            │ │ ← ContactCard #1
│ │ │ 张 │ 138 0000 0001           │ │
│ │ │   │ [家人] [同事]            │ │
│ │ └─────┘                        │ │
│ │ ┌─────┐  李四      ⋮            │ │ ← ContactCard #2
│ │ │ 李 │ 138 0000 0002           │ │
│ │ │   │ [朋友]                   │ │
│ │ └─────┘                        │ │
│ │ ... (还有 5 个)                │ │
│ └─────────────────────────────────┘ │ ← ListView
├─────────────────────────────────────┤
│                                  [+] │ ← FloatingActionButton
└─────────────────────────────────────┘
```

---

## 🐛 调试技巧

### 1. 使用 print() 追踪执行流程

```dart
print('🚀 开始');
print('📱 中间');
print('✅ 完成');
print('❌ 错误');
```

### 2. 检查 State 是否正确初始化

```dart
@override
void initState() {
  super.initState();
  print('_searchController: $_searchController');  // 应该不为 null
  print('_allContacts.length: ${_allContacts.length}');  // 应该是 7
}
```

### 3. 追踪 build 的执行次数

```dart
int buildCount = 0;

@override
Widget build(BuildContext context) {
  buildCount++;
  print('build 第 $buildCount 次');
  return ...;
}
```

### 4. 检查 setState 是否被正确调用

```dart
void _searchContacts(String query) {
  print('搜索词: $query');
  setState(() {
    print('setState 内部，更新 _filteredContacts');
    _filteredContacts = ...;
  });
  print('setState 调用完成');
}
```

---

## 📚 延伸学习

### 如果想添加新功能，需要修改的地方：

```
添加"删除联系人"功能：
├─ 修改 Contact 类（如果需要新字段）
├─ 修改 _initializeData()（如果需要测试数据）
├─ 修改 ContactCard.build()（添加删除按钮）
├─ 添加删除方法（_deleteContact）
├─ 在删除方法中调用 setState()
└─ 测试

添加"编辑联系人"功能：
├─ 创建新的 EditContactScreen
├─ 在 ContactCard 的 onTap 中导航
├─ 使用 Navigator.push() 打开编辑页面
├─ 编辑完成后返回修改后的 Contact
├─ 在原屏幕调用 setState() 更新列表
└─ 测试
```

