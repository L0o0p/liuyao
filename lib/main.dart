import 'package:flutter/material.dart';
import 'screens/learn_screen.dart';
import 'screens/review_screen.dart';
import 'screens/progress_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '六爻学习 App',
      theme: ThemeData(
        // 主色调：深紫色，体现传统文化的庄重感
        primarySwatch: Colors.deepPurple,
        primaryColor: const Color(0xFF673AB7), // 深紫色
        primaryColorDark: const Color(0xFF512DA8), // 更深的紫色
        primaryColorLight: const Color(0xFF9575CD), // 浅紫色
        // 辅助色：金色，体现传统文化的华贵感
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF673AB7),
          secondary: const Color(0xFFFFD700), // 金色
          surface: const Color(0xFFFAFAFA), // 浅灰背景
          background: const Color(0xFFFFFFFF), // 纯白背景
        ),

        // 字体主题
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF673AB7),
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF673AB7),
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E2E2E),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF2E2E2E),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF666666),
          ),
        ),

        // 卡片主题
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
        ),

        // 按钮主题
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF673AB7),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),

        // 底部导航栏主题
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF673AB7),
          unselectedItemColor: Color(0xFF999999),
          backgroundColor: Colors.white,
          elevation: 8,
        ),

        // AppBar主题
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF673AB7),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // 默认选中学习页面（中间位置）

  final List<Widget> _pages = const [
    ReviewScreen(), // 复习 - 第一个位置
    LearnScreen(), // 学习 - 中间位置
    ProgressScreen(), // 进度 - 第三个位置
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.refresh), label: '复习'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: '学习'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '进度'),
        ],
      ),
    );
  }
}
