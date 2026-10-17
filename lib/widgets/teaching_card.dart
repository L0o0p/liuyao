import 'package:flutter/material.dart';

import '../data/teaching_notes.dart';

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
    final primary = Theme.of(context).primaryColor;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '先看一眼',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              note.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        note.fact,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      note.hint,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onContinue,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
