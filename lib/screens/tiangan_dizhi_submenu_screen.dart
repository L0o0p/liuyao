import 'package:flutter/material.dart';
import '../data/knowledge_catalog.dart';
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
                      for (
                        var i = 0;
                        i < KnowledgeCatalog.tianganMenuIds.length;
                        i++
                      ) ...[
                        if (i >= 2) const SizedBox(height: 12),
                        _buildCatalogButton(
                          context,
                          KnowledgeCatalog.tianganMenuIds[i],
                        ),
                      ],
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

  Widget _buildCatalogButton(BuildContext context, String id) {
    final module = KnowledgeCatalog.module(id)!;
    return _buildSubmenuButton(
      context,
      title: module.name,
      subtitle: module.subtitle,
      icon: _submenuIcon(id),
      onTap: () => _navigateToModule(context, id),
    );
  }

  IconData _submenuIcon(String id) {
    switch (id) {
      case 'tiangandizhi_comprehensive':
        return Icons.quiz;
      case 'tiangandizhi_wuxing':
        return Icons.eco;
      case 'tiangandizhi_yinyang':
        return Icons.brightness_6;
      case 'tiangandizhi_direction':
        return Icons.explore;
      case 'tiangandizhi_time':
        return Icons.schedule;
      case 'tiangandizhi_shengke':
        return Icons.psychology;
      default:
        return Icons.quiz;
    }
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
