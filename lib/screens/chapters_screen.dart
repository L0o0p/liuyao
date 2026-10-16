import 'package:flutter/material.dart';

import '../data/chapters.dart';
import '../models/srs_card.dart';
import '../services/srs_scheduler.dart';
import '../services/storage_service.dart';
import '../services/sync/sync_engine.dart';
import '../widgets/mastery_counts.dart';
import 'chapter_detail_screen.dart';

/// 按学习顺序列出章节，每章显示口诀摘要和掌握情况。
class ChaptersScreen extends StatefulWidget {
  const ChaptersScreen({super.key});

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
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

  Future<void> _open(Chapter chapter) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChapterDetailScreen(chapter: chapter),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final chapters = Chapters.all;
    return Scaffold(
      appBar: AppBar(title: const Text('章节'), centerTitle: true),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: chapters.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            return _ChapterTile(
              index: index + 1,
              chapter: chapter,
              counts: _loading
                  ? null
                  : SrsScheduler.count(chapter.itemKeys, _cards),
              onTap: () => _open(chapter),
            );
          },
        ),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final int index;
  final Chapter chapter;
  final SrsCounts? counts;
  final VoidCallback onTap;

  const _ChapterTile({
    required this.index,
    required this.chapter,
    required this.counts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final counts = this.counts;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$index',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      chapter.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (counts != null)
                    Text(
                      '已掌握 ${counts.mastered}/${counts.total}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                chapter.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (counts != null) ...[
                const SizedBox(height: 12),
                MasteryBar(counts: counts, minHeight: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
