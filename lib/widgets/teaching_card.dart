import 'package:flutter/material.dart';

import '../data/teaching_notes.dart';
import '../theme/app_theme.dart';
import 'tactile.dart';

/// 先讲后考时用的说明卡。
class TeachingCard extends StatelessWidget {
  final TeachingNote note;
  final String actionLabel;
  final VoidCallback onContinue;

  const TeachingCard({
    super.key,
    required this.note,
    required this.onContinue,
    this.actionLabel = '记住了，开始答题',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: TactileCard(
                  padding: const EdgeInsets.all(20),
                  shadowColor: AppColors.border,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Pill(
                          label: '先看一眼',
                          icon: Icons.lightbulb,
                          background: scheme.tertiaryFixed,
                          foreground: scheme.onTertiaryFixed,
                          border: AppColors.border,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        note.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          note.fact,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        note.hint,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TactileButton(
              label: actionLabel,
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
