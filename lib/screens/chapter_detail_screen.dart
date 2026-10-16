import 'package:flutter/material.dart';

import '../data/chapters.dart';
import '../models/srs_card.dart';
import '../services/srs_scheduler.dart';
import '../services/storage_service.dart';
import '../services/sync/sync_engine.dart';
import '../widgets/atlas_table_view.dart';
import '../widgets/mastery_counts.dart';
import 'study_session_screen.dart';

/// 上半部分对照表和口诀，下半部分本章掌握情况和练习入口。
class ChapterDetailScreen extends StatefulWidget {
  final Chapter chapter;

  const ChapterDetailScreen({super.key, required this.chapter});

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  Map<String, SrsCard> _cards = {};
  bool _loading = true;

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
    final cards = await StorageService.loadCards();
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _loading = false;
    });
  }

  Future<void> _practice() async {
    final chapter = widget.chapter;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudySessionScreen(
          title: chapter.title,
          restEvery: chapter.restEvery,
          loadItemKeys: () => loadChapterQueue(chapter),
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _clear() async {
    final title = widget.chapter.title;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空卡片'),
        content: Text('确定要清掉「$title」的复习卡片吗？这些知识点会变成未学。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await StorageService.clearItems(widget.chapter.itemKeys);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已清掉「$title」的卡片')));
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    return Scaffold(
      appBar: AppBar(
        title: Text(chapter.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _clear();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'clear', child: Text('清空本章卡片')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            AtlasChapterView(chapter: chapter.atlas),
            const SizedBox(height: 28),
            Text('本章掌握情况', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              _ChapterProgressCard(
                counts: SrsScheduler.count(chapter.itemKeys, _cards),
                onPractice: _practice,
              ),
          ],
        ),
      ),
    );
  }
}

class _ChapterProgressCard extends StatelessWidget {
  final SrsCounts counts;
  final VoidCallback onPractice;

  const _ChapterProgressCard({required this.counts, required this.onPractice});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MasteryCountRow(counts: counts),
            const SizedBox(height: 12),
            MasteryBar(counts: counts, minHeight: 6),
            const SizedBox(height: 8),
            Text(
              '已掌握是进入复习且间隔不少于 21 天的知识点。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onPractice,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('练这一章'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 按章巩固的队列。只含本章知识点，不受今日新学上限约束。
Future<List<String>> loadChapterQueue(Chapter chapter) async {
  final cards = await StorageService.loadCards();
  return SrsScheduler.moduleQueue(
    moduleItemKeys: chapter.itemKeys,
    cards: cards,
    now: DateTime.now(),
  );
}
