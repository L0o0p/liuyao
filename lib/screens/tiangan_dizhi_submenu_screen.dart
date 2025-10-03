import 'package:flutter/material.dart';
import 'study_module_screen.dart';

class TianGanDiZhiSubmenuScreen extends StatelessWidget {
  const TianGanDiZhiSubmenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "天干地支基础",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Text(
              //   "选择学习内容",
              //   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              //     fontWeight: FontWeight.bold,
              //   ),
              //   textAlign: TextAlign.center,
              // ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSubmenuButton(
                        context,
                        title: "综合练习",
                        subtitle: "综合练习天干地支五行、阴阳、方位、时间、生克关系",
                        icon: Icons.quiz,
                        onTap: () =>
                            _navigateToModule(context, 'tiangandizhi_comprehensive'),
                      ),
                      _buildSubmenuButton(
                        context,
                        title: "天干地支五行",
                        subtitle: "学习天干地支的五行属性",
                        icon: Icons.eco,
                        onTap: () =>
                            _navigateToModule(context, 'tiangandizhi_wuxing'),
                      ),
                      const SizedBox(height: 12),
                      _buildSubmenuButton(
                        context,
                        title: "天干地支阴阳",
                        subtitle: "掌握天干地支的阴阳属性",
                        icon: Icons.brightness_6,
                        onTap: () =>
                            _navigateToModule(context, 'tiangandizhi_yinyang'),
                      ),
                      const SizedBox(height: 12),
                      _buildSubmenuButton(
                        context,
                        title: "方位对应",
                        subtitle: "了解天干地支对应的方位",
                        icon: Icons.explore,
                        onTap: () => _navigateToModule(
                          context,
                          'tiangandizhi_direction',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSubmenuButton(
                        context,
                        title: "时间对应",
                        subtitle: "掌握天干地支对应的时间",
                        icon: Icons.schedule,
                        onTap: () =>
                            _navigateToModule(context, 'tiangandizhi_time'),
                      ),
                      const SizedBox(height: 12),
                      _buildSubmenuButton(
                        context,
                        title: "五行生克",
                        subtitle: "学习五行之间的生克关系",
                        icon: Icons.psychology,
                        onTap: () =>
                            _navigateToModule(context, 'tiangandizhi_shengke'),
                      ),
                      const SizedBox(height: 16),
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

  Widget _buildSubmenuButton(
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

  void _navigateToModule(BuildContext context, String moduleType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyModuleScreen(moduleType: moduleType),
      ),
    );
  }
}
