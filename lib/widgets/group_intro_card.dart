import 'package:flutter/material.dart';

import '../data/study_groups.dart';
import '../theme/app_theme.dart';
import 'atlas_table_view.dart';
import 'tactile.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final showTableTitles = group.tables.length > 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TactileCard(
                      padding: const EdgeInsets.all(20),
                      shadowColor: AppColors.border,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Pill(
                              label: '今日新学',
                              icon: Icons.auto_awesome,
                              background: scheme.secondaryContainer,
                              foreground: scheme.onSecondaryContainer,
                              border: scheme.secondary.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            group.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '共 ${group.itemKeys.length} 条，先看一遍整组，再逐条练。',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          for (final table in group.tables) ...[
                            if (showTableTitles) ...[
                              SectionTitle(title: table.title),
                              const SizedBox(height: 8),
                            ],
                            AtlasTableView(table: table),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    MnemonicCard(title: '口诀', text: group.mnemonic),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TactileButton(
              label: '开始逐条练习',
              trailingIcon: Icons.arrow_forward,
              large: true,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
