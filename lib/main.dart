import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/contacts/contacts_list_screen.dart';

void main() {
  print('🚀 ========================================');
  print('🚀 应用启动：Kongo - 通讯录和日程管理');
  print('🚀 ========================================');
  print('⏱️  启动时间: ${DateTime.now()}');
  
  runApp(const MyApp());
  
  print('✅ MyApp 已创建');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🎨 MyApp.build() 被调用');
    
    return MaterialApp(
      title: 'Kongo - 通讯录和日程管理',
      theme: AppTheme.lightTheme,
      home: const ContactsListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

