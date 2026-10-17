import 'package:flutter/material.dart';

import '../data/knowledge_catalog.dart';
import '../data/study_groups.dart';
import '../models/srs_card.dart';
import '../services/srs_scheduler.dart';
import '../services/storage_service.dart';
import '../services/sync/sync_engine.dart';
import 'study_session_screen.dart';

/// 今日学习：先复习到期卡片，再引入一组新知识。每天默认自动引入一组。
class TodayScreen extends StatefulWidget {
  final VoidCallback? onOpenChapters;

  const TodayScreen({super.key, this.onOpenChapters});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  int _dueCount = 0;
  int _newCount = 0;

  /// 今天要引入的组。今天已经引入过一组，或者全部引入完时为空。
  StudyGroup? _todayGroup;

  /// 下一个还有新知识点的组，今天学完后可以「再学一组」。
  StudyGroup? _nextGroup;
  int _nextCount = 0;
  bool _loading = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    SyncEngine.dataVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    SyncEngine.dataVersion.removeListener(_load);
    super.dispose();
  }

  Future<_TodayState> _compute({bool extraGroup = false}) async {
    final now = DateTime.now();
    final cards = await StorageService.loadCards();
    final introducedToday = await StorageService.groupsIntroducedOn(now);
    final next = StudyGroups.next(cards.keys.toSet());
    final group = extraGroup || introducedToday.isEmpty ? next : null;
    final plan = SrsScheduler.planToday(
      catalogOrder: [for (final item in KnowledgeCatalog.items) item.itemKey],
      cards: cards,
      now: now,
      groupKeys: group?.itemKeys ?? const [],
    );
    return _TodayState(
      now: now,
      cards: cards,
      plan: plan,
      group: plan.newKeys.isEmpty ? null : group,
      next: next,
    );
  }

  Future<void> _load() async {
    final state = await _compute();
    if (!mounted) return;
    final next = state.next;
    setState(() {
      _dueCount = state.plan.dueCount;
      _newCount = state.plan.newCount;
      _todayGroup = state.group;
      _nextGroup = next;
      _nextCount = next == null
          ? 0
          : next.itemKeys.where((key) => !state.cards.containsKey(key)).length;
      _loading = false;
    });
  }

  Future<void> _start({bool extraGroup = false}) async {
    if (_starting) return;
    setState(() {
      _starting = true;
    });
    try {
      final state = await _compute(extraGroup: extraGroup);
      final plan = state.plan;
      if (plan.isEmpty) {
        await _load();
        return;
      }
      for (final key in plan.newKeys) {
        await StorageService.saveCard(SrsScheduler.introduce(key, state.now));
      }
      final group = state.group;
      if (group != null) {
        await StorageService.markGroupIntroduced(state.now, group.id);
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StudySessionScreen(
            title: '今日学习',
            group: group,
            loadItemKeys: () async => plan.itemKeys,
          ),
        ),
      );
      if (mounted) await _load();
    } finally {
      if (mounted) {
        setState(() {
          _starting = false;
        });
      }
    }
  }

  String get _newLine {
    final group = _todayGroup;
    if (group != null) return '今天新学：${group.title}（$_newCount 条）';
    if (_nextGroup == null) return '全部小组都已学过';
    return '今天的新组已经学过';
  }

  @override
  Widget build(BuildContext context) {
    final finished = !_loading && _dueCount == 0 && _newCount == 0;
    final next = _nextGroup;
    return Scaffold(
      appBar: AppBar(title: const Text('今日学习'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: _CountCard(
                            label: '到期复习',
                            value: _dueCount,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CountCard(
                            label: '今天新学',
                            value: _newCount,
                            color: const Color(0xFF00897B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _newLine,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 28),
                    if (finished) ...[
                      Text(
                        '今天已经学完',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '还可以到「章节」里按章巩固',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      if (next != null) ...[
                        OutlinedButton(
                          onPressed: _starting
                              ? null
                              : () => _start(extraGroup: true),
                          child: Text('再学一组：${next.title}（$_nextCount 条）'),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (widget.onOpenChapters != null)
                        OutlinedButton(
                          onPressed: widget.onOpenChapters,
                          child: const Text('去章节巩固'),
                        ),
                    ] else
                      FilledButton(
                        onPressed: _starting ? null : _start,
                        child: const Text('开始'),
                      ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TodayState {
  final DateTime now;
  final Map<String, SrsCard> cards;
  final TodayPlan plan;

  /// 这次要引入的组。没有新知识点要引入时为空。
  final StudyGroup? group;
  final StudyGroup? next;

  const _TodayState({
    required this.now,
    required this.cards,
    required this.plan,
    required this.group,
    required this.next,
  });
}

class _CountCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _CountCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
