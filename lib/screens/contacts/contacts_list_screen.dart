import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/contact.dart';
import '../../widgets/contact/contact_card.dart';
import '../../widgets/common/search_bar.dart' as custom_search;

/// 联系人列表屏幕
class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({Key? key}) : super(key: key);

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  late TextEditingController _searchController;
  late List<Contact> _allContacts;
  late List<Contact> _filteredContacts;

  @override
  void initState() {
    super.initState();
    print('📱 ContactsListScreen.initState() 被调用');
    _searchController = TextEditingController();
    _initializeData();
    print('✅ 联系人列表屏幕已初始化，共 ${_allContacts.length} 个联系人');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 初始化数据（jia7数据）
  void _initializeData() {
    _allContacts = [
      Contact(
        id: '1',
        name: '张三',
        phone: '138 0000 0001',
        email: 'zhangsan@example.com',
        tags: ['家人', '同事'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Contact(
        id: '2',
        name: '李四',
        phone: '138 0000 0002',
        email: 'lisi@example.com',
        tags: ['朋友'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Contact(
        id: '3',
        name: '王五',
        phone: '138 0000 0003',
        email: 'wangwu@example.com',
        tags: ['同事', '项目组'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Contact(
        id: '4',
        name: '赵六',
        phone: '138 0000 0004',
        email: 'zhaoliu@example.com',
        tags: ['朋友', '高中同学'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Contact(
        id: '5',
        name: '孙七',
        phone: '138 0000 0005',
        email: 'sunqi@example.com',
        tags: ['家人'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Contact(
        id: '6',
        name: '周八',
        phone: '138 0000 0006',
        email: 'zhoubo@example.com',
        tags: ['同事', '部门'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Contact(
        id: '7',
        name: '吴九',
        phone: '138 0000 0007',
        email: 'wujiu@example.com',
        tags: ['朋友', '健身房'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    _filteredContacts = List.from(_allContacts);
  }

  /// 搜索联系人
  void _searchContacts(String query) {
    print('🔍 搜索: "$query"');
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = List.from(_allContacts);
      } else {
        _filteredContacts = _allContacts
            .where((contact) =>
                contact.name.toLowerCase().contains(query.toLowerCase()) ||
                (contact.phone?.contains(query) ?? false) ||
                (contact.email?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
      print('✅ 搜索结果: ${_filteredContacts.length} 个联系人');
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 ContactsListScreen.build() 被调用，显示 ${_filteredContacts.length} 个联系人');
    return Scaffold(
      appBar: AppBar(
        title: const Text('通讯录'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {},
            tooltip: '排序',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 搜索框
            custom_search.SearchBar(
              controller: _searchController,
              onChanged: _searchContacts,
            ),
            // 联系人计数
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredContacts.length} 个联系人',
                  style: const TextStyle(
                    fontSize: AppFontSize.bodySmall,
                    color: AppColors.outline,
                  ),
                ),
              ),
            ),
            // 联系人列表
            Expanded(
              child: _filteredContacts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _filteredContacts[index];
                        return ContactCard(
                          contact: contact,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('点击了 ${contact.name}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          onLongPress: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('长按了 ${contact.name}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('添加新联系人'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        tooltip: '添加联系人',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts_outlined,
            size: 80,
            color: AppColors.outline.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _searchController.text.isEmpty ? '暂无联系人' : '未找到匹配的联系人',
            style: const TextStyle(
              fontSize: AppFontSize.bodyMedium,
              color: AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}
