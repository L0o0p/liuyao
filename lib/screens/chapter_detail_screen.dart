import 'package:flutter/material.dart';

import '../data/chapters.dart';
import '../data/study_groups.dart';
import '../models/srs_card.dart';
import '../services/srs_scheduler.dart';
import '../services/storage_service.dart';
import '../services/sync/sync_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/atlas_table_view.dart';
import '../widgets/mastery_counts.dart';
import '../widgets/tactile.dart';
import 'study_session_screen.dart';

/// 上半部分口诀和对照表，下半部分本章掌握情况，底部吸附练习入口。
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
            style: TextButton.styleFrom(foregroundColor: AppColors.wrong),
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  DetailHeader(
                    title: chapter.title,
                    trailing: PopupMenuButton<String>(
                      tooltip: '更多操作',
                      onSelected: (value) {
                        if (value == 'clear') _clear();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.restart_alt,
                                size: 19,
                                color: AppColors.wrong,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '清空本章卡片',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: AppColors.wrong),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: TactileCard(
                        padding: const EdgeInsets.all(8),
                        radius: 20,
                        depth: 3,
                        color: scheme.surfaceContainerLowest,
                        shadowColor: AppColors.border,
                        child: Icon(
                          Icons.more_horiz,
                          size: 20,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      children: [
                        AtlasChapterView(chapter: chapter.atlas),
                        const SizedBox(height: 12),
                        if (_loading)
                          const Center(child: CircularProgressIndicator())
                        else ...[
                          _ChapterProgressCard(
                            counts: SrsScheduler.count(
                              chapter.itemKeys,
                              _cards,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _GroupsCard(chapterId: chapter.id, cards: _cards),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.page,
                        AppColors.page.withValues(alpha: 0.9),
                        AppColors.page.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: TactileButton(
                    label: '练这一章',
                    trailingIcon: Icons.arrow_forward,
                    large: true,
                    onPressed: _practice,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterProgressCard extends StatelessWidget {
  final SrsCounts counts;

  const _ChapterProgressCard({required this.counts});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = counts.total == 0
        ? '0%'
        : '${(counts.mastered * 100 / counts.total).toStringAsFixed(1)}%';
    return TactileCard(
      color: scheme.surface,
      shadowColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(title: '本章掌握情况', dotColor: scheme.secondary),
          const SizedBox(height: 12),
          MasteryCountRow(counts: counts),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '总体进度',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: scheme.primary),
              ),
              Text(
                percent,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          MasteryBar(counts: counts, height: 12),
          const SizedBox(height: 12),
          const InfoNote(text: '已掌握是进入复习且间隔不少于 21 天的知识点。'),
        ],
      ),
    );
  }
}

class _GroupsCard extends StatelessWidget {
  final String chapterId;
  final Map<String, SrsCard> cards;

  const _GroupsCard({required this.chapterId, required this.cards});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TactileCard(
      color: scheme.surface,
      shadowColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(title: '本章小组'),
          const SizedBox(height: 4),
          Text('今日按这个顺序每天引入一组。', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final group in StudyGroups.forChapter(chapterId))
            _GroupRow(
              title: group.title,
              counts: SrsScheduler.count(group.itemKeys, cards),
            ),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final String title;
  final SrsCounts counts;

  const _GroupRow({required this.title, required this.counts});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final started = counts.total - counts.unseen;
    final done = counts.unseen == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: done ? scheme.secondary : scheme.outlineVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
            ),
          ),
          Text(
            '已学 $started/${counts.total} · 已掌握 ${counts.mastered}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// 按章巩固的队列。只含本章知识点，不受今日小组引入的约束。
Future<List<String>> loadChapterQueue(Chapter chapter) async {
  final cards = await StorageService.loadCards();
  return SrsScheduler.moduleQueue(
    moduleItemKeys: chapter.itemKeys,
    cards: cards,
    now: DateTime.now(),
  );
}
