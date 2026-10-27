import 'package:flutter/material.dart';

import '../services/srs_scheduler.dart';
import '../theme/app_theme.dart';
import 'tactile.dart';

/// 已掌握、学习中、未学三个计数胶囊。
class MasteryCountRow extends StatelessWidget {
  final SrsCounts counts;

  const MasteryCountRow({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Count(
            label: '已掌握',
            value: counts.mastered,
            background: AppColors.masteredBg,
            border: AppColors.masteredBorder,
            shadow: AppColors.masteredShadow,
            text: AppColors.masteredText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Count(
            label: '学习中',
            value: counts.learning,
            background: AppColors.learningBg,
            border: AppColors.learningBorder,
            shadow: AppColors.learningShadow,
            text: AppColors.learningText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Count(
            label: '未学',
            value: counts.unseen,
            background: AppColors.unseenBg,
            border: AppColors.unseenBorder,
            shadow: AppColors.unseenShadow,
            text: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 掌握情况分段条：已掌握、学习中、未学。
class MasteryBar extends StatelessWidget {
  final SrsCounts counts;
  final double height;

  const MasteryBar({super.key, required this.counts, this.height = 16});

  @override
  Widget build(BuildContext context) {
    final total = counts.total == 0 ? 1 : counts.total;
    return TactileSegmentBar(
      height: height,
      segments: [
        (counts.mastered / total, AppColors.masteredBar),
        (counts.learning / total, AppColors.cheese),
        (counts.unseen / total, AppColors.unseenBar),
      ],
    );
  }
}

/// 进度条上方的「掌握进度 / 待学」百分比。
class MasteryPercentLine extends StatelessWidget {
  final SrsCounts counts;

  const MasteryPercentLine({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('掌握进度 ${_percent(counts.mastered, counts.total)}', style: style),
        Text('待学 ${_percent(counts.unseen, counts.total)}', style: style),
      ],
    );
  }
}

String _percent(int part, int total) {
  if (total == 0) return '0%';
  return '${(part * 100 / total).toStringAsFixed(1)}%';
}

/// 虚线框里的小字说明。
class InfoNote extends StatelessWidget {
  final String text;

  const InfoNote({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: scheme.surfaceTint,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final String label;
  final int value;
  final Color background;
  final Color border;
  final Color shadow;
  final Color text;

  const _Count({
    required this.label,
    required this.value,
    required this.background,
    required this.border,
    required this.shadow,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2),
        boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: border,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: shadow),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
