import 'package:flutter/material.dart';
import 'study_module_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text("选择学习板块"), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // 减少边距以适应小屏幕
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                // "请选择要学习的内容",
                "六爻基础",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24), // 减少间距
              Expanded(
                child: SingleChildScrollView(
                  // 添加滚动支持
                  child: Column(
                    children: [
                      _buildModuleButton(
                        context,
                        title: "天干地支基础",
                        subtitle: "学习十天干、十二地支的基本知识",
                        icon: Icons.auto_stories,
                        onTap: () =>
                            _navigateToModule(context, 'tianganzhizhi'),
                      ),
                      const SizedBox(height: 12), // 减少间距
                      _buildModuleButton(
                        context,
                        title: "五行相生相克",
                        subtitle: "掌握五行之间的生克关系",
                        icon: Icons.psychology,
                        onTap: () => _navigateToModule(context, 'wuxing'),
                      ),
                      const SizedBox(height: 12),
                      _buildModuleButton(
                        context,
                        title: "六合三合六冲",
                        subtitle: "了解地支间的合冲关系",
                        icon: Icons.compare_arrows,
                        onTap: () => _navigateToModule(context, 'hechong'),
                      ),
                      const SizedBox(height: 12),
                      _buildModuleButton(
                        context,
                        title: "十二长生",
                        subtitle: "掌握十二长生宫位的含义",
                        icon: Icons.timeline,
                        onTap: () =>
                            _navigateToModule(context, 'shierchangsheng'),
                      ),
                      const SizedBox(height: 12),
                      _buildModuleButton(
                        context,
                        title: "综合练习",
                        subtitle: "混合各种题型，全面复习",
                        icon: Icons.quiz,
                        onTap: () =>
                            _navigateToModule(context, 'comprehensive'),
                      ),
                      const SizedBox(height: 16), // 底部额外间距
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // 减少内边距
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), // 减少图标容器内边距
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24, // 稍微减小图标尺寸
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12), // 减少间距
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15, // 稍微减小字体
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2), // 减少间距
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13, // 稍微减小副标题字体
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[400],
              ), // 减小箭头尺寸
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToModule(BuildContext context, String moduleType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyModuleScreen(moduleType: moduleType),
      ),
    );
  }
}
