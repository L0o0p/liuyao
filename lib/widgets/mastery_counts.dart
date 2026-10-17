import 'package:flutter/material.dart';

import '../services/srs_scheduler.dart';

/// 已掌握、学习中、未学三项计数。
class MasteryCountRow extends StatelessWidget {
  final SrsCounts counts;

  const MasteryCountRow({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _Count(label: '已掌握', value: counts.mastered, color: Colors.green),
        _Count(label: '学习中', value: counts.learning, color: Colors.blue),
        _Count(label: '未学', value: counts.unseen, color: Colors.grey),
      ],
    );
  }
}

/// 掌握比例进度条。
class MasteryBar extends StatelessWidget {
  final SrsCounts counts;
  final double minHeight;

  const MasteryBar({super.key, required this.counts, this.minHeight = 8});

  @override
  Widget build(BuildContext context) {
    final ratio = counts.total == 0 ? 0.0 : counts.mastered / counts.total;
    return LinearProgressIndicator(value: ratio, minHeight: minHeight);
  }
}

class _Count extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Count({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
