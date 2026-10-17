import 'package:flutter/material.dart';

import '../data/study_groups.dart';
import 'atlas_table_view.dart';

/// 引入一组新知识前先看整组对照表和口诀。和教学卡同一布局，讲的是一整组。
class GroupIntroCard extends StatelessWidget {
  final StudyGroup group;
  final VoidCallback onContinue;

  const GroupIntroCard({
    super.key,
    required this.group,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final showTableTitles = group.tables.length > 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('今日新学', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              group.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '共 ${group.itemKeys.length} 条，先看一遍整组，再逐条练。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final table in group.tables) ...[
                      if (showTableTitles) ...[
                        Text(
                          table.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                      ],
                      AtlasTableView(table: table),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        group.mnemonic,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onContinue,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('开始逐条练习'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
