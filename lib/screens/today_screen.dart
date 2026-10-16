import 'package:flutter/material.dart';

import '../data/knowledge_catalog.dart';
import '../services/srs_scheduler.dart';
import '../services/storage_service.dart';
import '../services/sync/sync_engine.dart';
import 'study_session_screen.dart';

/// 今日学习：先复习到期卡片，再在每日额度内引入新卡。
class TodayScreen extends StatefulWidget {
  final VoidCallback? onOpenChapters;

  const TodayScreen({super.key, this.onOpenChapters});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  int _dueCount = 0;
  int _newCount = 0;
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

  Future<void> _load() async {
    final now = DateTime.now();
    final cards = await StorageService.loadCards();
    final introduced = await StorageService.introducedOn(now);
    final plan = SrsScheduler.planToday(
      catalogOrder: [
        for (final item in KnowledgeCatalog.items) item.itemKey,
      ],
      cards: cards,
      introducedToday: introduced,
      now: now,
    );
    if (!mounted) return;
    setState(() {
      _dueCount = plan.dueCount;
      _newCount = plan.newCount;
      _loading = false;
    });
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() {
      _starting = true;
    });
    try {
      final now = DateTime.now();
      final cards = await StorageService.loadCards();
      final introduced = await StorageService.introducedOn(now);
      final plan = SrsScheduler.planToday(
        catalogOrder: [
          for (final item in KnowledgeCatalog.items) item.itemKey,
        ],
        cards: cards,
        introducedToday: introduced,
        now: now,
      );
      if (plan.isEmpty) {
        await _load();
        return;
      }
      var created = 0;
      for (final key in plan.newKeys) {
        await StorageService.saveCard(SrsScheduler.introduce(key, now));
        created++;
      }
      await StorageService.addIntroduced(now, created);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StudySessionScreen(
            title: '今日学习',
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

  @override
  Widget build(BuildContext context) {
    final finished = !_loading && _dueCount == 0 && _newCount == 0;
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
                            label: '今天可新学',
                            value: _newCount,
                            color: const Color(0xFF00897B),
                          ),
                        ),
                      ],
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
