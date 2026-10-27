import 'dart:async';

import 'package:flutter/material.dart';
import 'screens/chapters_screen.dart';
import 'screens/mine_screen.dart';
import 'screens/today_screen.dart';
import 'services/storage_service.dart';
import 'services/sync/sync_engine.dart';
import 'theme/app_theme.dart';
import 'widgets/tactile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 先完成旧数据迁移，再进入界面
  await StorageService.initialize();

  runApp(const MyApp());

  // 启动后尝试同步。失败不能挡住界面。
  unawaited(SyncEngine.instance.sync());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '六爻学习 App',
      theme: buildAppTheme(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  static const _navItems = [
    AppNavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: '今日',
    ),
    AppNavItem(
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories,
      label: '章节',
    ),
    AppNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: '我的',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 回到前台时再试一次同步，失败静默
    if (state == AppLifecycleState.resumed) {
      unawaited(SyncEngine.instance.sync());
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(
        onOpenChapters: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
      const ChaptersScreen(),
      const MineScreen(),
    ];
    return Scaffold(
      body: AppBackground(child: pages[_selectedIndex]),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
