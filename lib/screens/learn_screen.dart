import 'package:flutter/material.dart';
import 'study_module_screen.dart';
import 'tiangan_dizhi_submenu_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("六爻基础"), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // 减少边距以适应小屏幕
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Text(
              //   "六爻基础",
              //   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              //     fontWeight: FontWeight.bold,
              //   ),
              //   textAlign: TextAlign.center,
              // ),
              // const SizedBox(height: 24), // 减少间距
              Expanded(
                child: SingleChildScrollView(
                  // 添加滚动支持
                  child: Column(
                    children: [
                      _buildModuleButton(
                        context,
                        title: "六十四卦",
                        subtitle: "速记六十四卦卦象",
                        icon: Icons.auto_stories,
                        onTap: () => _navigateToModule(context, '64gua'),
                      ),
                      _buildModuleButton(
                        context,
                        title: "天干地支基础",
                        subtitle: "五行、阴阳、方位、时间、生克",
                        icon: Icons.auto_stories,
                        onTap: () => _navigateToSubmenu(context),
                      ),
                      const SizedBox(height: 12), // 减少间距
                      _buildModuleButton(
                        context,
                        title: "十二支指诀",
                        subtitle: "地支对应手指关节的快速记忆法",
                        icon: Icons.psychology,
                        onTap: () => _navigateToModule(context, 'wuxing'),
                      ),
                      const SizedBox(height: 12),
                      _buildModuleButton(
                        context,
                        title: "刑冲合害",
                        subtitle: "判断人事关系、事情走向的规则",
                        icon: Icons.compare_arrows,
                        onTap: () => _navigateToModule(context, 'hechong'),
                      ),
                      const SizedBox(height: 12),
                      _buildModuleButton(
                        context,
                        title: "十二长生",
                        subtitle: "用来判断某个爻（事物）的旺衰强弱",
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.05),
                Theme.of(context).primaryColor.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).primaryColor.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSubmenu(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TianGanDiZhiSubmenuScreen(),
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
