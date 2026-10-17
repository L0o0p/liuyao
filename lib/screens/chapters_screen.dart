import 'package:flutter/material.dart';

import '../data/chapters.dart';
import '../data/knowledge_catalog.dart';
import '../data/study_groups.dart';
import '../models/srs_card.dart';
import '../services/srs_scheduler.dart';
import '../services/storage_service.dart';
import '../services/sync/sync_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/tactile.dart';
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
    final currentChapterId = StudyGroups.next(_cards.keys.toSet())?.chapterId;
    return SafeArea(
      bottom: false,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: chapters.length + 1,
        separatorBuilder: (context, index) =>
            SizedBox(height: index == 0 ? 16 : 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _OverviewCard(
              counts: _loading
                  ? null
                  : SrsScheduler.count(
                      KnowledgeCatalog.items.map((item) => item.itemKey),
                      _cards,
                    ),
              streak: SrsScheduler.studyStreakDays(
                _cards.values,
                DateTime.now(),
              ),
            );
          }
          final chapter = chapters[index - 1];
          return _ChapterTile(
            index: index,
            chapter: chapter,
            current: !_loading && chapter.id == currentChapterId,
            counts: _loading
                ? null
                : SrsScheduler.count(chapter.itemKeys, _cards),
            onTap: () => _open(chapter),
          );
        },
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final SrsCounts? counts;
  final int streak;

  const _OverviewCard({required this.counts, required this.streak});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final counts = this.counts;
    return TactileCard(
      shadowColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.honey,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '章节目录',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '循序渐进 · 从基础到断卦',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (counts != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: ShapeDecoration(
                    color: Color.alphaBlend(
                      scheme.secondaryFixed.withValues(alpha: 0.7),
                      AppColors.card,
                    ),
                    shape: const StadiumBorder(
                      side: BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    shadows: const [
                      BoxShadow(color: AppColors.border, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, size: 16, color: scheme.secondary),
                      const SizedBox(width: 6),
                      Text(
                        '总进度 ${counts.mastered}/${counts.total}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: scheme.onSecondaryFixed),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _DashedDivider(color: scheme.outlineVariant),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.bolt, size: 16, color: scheme.tertiaryFixedDim),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  streak > 0 ? '已连续学习 $streak 天' : '今天还没开始学习',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Text(
                  '点开章节看口诀和对照表',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: scheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ChapterStatus { mastered, current, learning, notStarted }

class _ChapterTile extends StatelessWidget {
  final int index;
  final Chapter chapter;
  final bool current;
  final SrsCounts? counts;
  final VoidCallback onTap;

  const _ChapterTile({
    required this.index,
    required this.chapter,
    required this.current,
    required this.counts,
    required this.onTap,
  });

  _ChapterStatus _status(SrsCounts counts) {
    if (counts.total > 0 && counts.mastered == counts.total) {
      return _ChapterStatus.mastered;
    }
    if (current) return _ChapterStatus.current;
    if (counts.unseen == counts.total) return _ChapterStatus.notStarted;
    return _ChapterStatus.learning;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final counts = this.counts;
    final status = counts == null ? _ChapterStatus.notStarted : _status(counts);
    final muted = status == _ChapterStatus.notStarted;
    final ratio = counts == null || counts.total == 0
        ? 0.0
        : counts.mastered / counts.total;

    final (
      Color circle,
      Color badgeBg,
      Color badgeFg,
      IconData badgeIcon,
      String badgeLabel,
      Color bar,
      Color subtitleColor,
    ) = switch (status) {
      _ChapterStatus.mastered => (
        scheme.secondaryContainer,
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.verified,
        '已掌握',
        scheme.secondary,
        scheme.secondary,
      ),
      _ChapterStatus.current => (
        Color.alphaBlend(
          scheme.onTertiaryContainer.withValues(alpha: 0.4),
          AppColors.card,
        ),
        scheme.tertiaryFixed,
        scheme.onTertiaryFixed,
        Icons.local_fire_department,
        '学习中',
        scheme.tertiaryFixedDim,
        scheme.tertiaryContainer,
      ),
      _ChapterStatus.learning => (
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
        scheme.primary,
        Icons.edit_note,
        '学习中',
        AppColors.cheese,
        scheme.onSurfaceVariant,
      ),
      _ChapterStatus.notStarted => (
        scheme.surfaceContainerHighest,
        scheme.surfaceContainer,
        scheme.outline,
        Icons.flag_outlined,
        '未开始',
        scheme.secondaryFixedDim,
        scheme.outline,
      ),
    };

    final subtitle = counts == null
        ? ''
        : switch (status) {
            _ChapterStatus.mastered => '${counts.mastered}/${counts.total} 已掌握',
            _ChapterStatus.notStarted => '未开始 · 0/${counts.total}',
            _ => '${counts.mastered}/${counts.total} 掌握中',
          };

    final card = TactileCard(
      onTap: onTap,
      color: muted ? const Color(0xFFF7F5ED) : AppColors.card,
      borderColor: current ? AppColors.honey : AppColors.border,
      shadowColor: muted
          ? AppColors.border.withValues(alpha: 0.35)
          : AppColors.border,
      borderWidth: current ? 3 : 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: circle,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: muted ? scheme.outlineVariant : AppColors.border,
                  ),
                  boxShadow: muted
                      ? null
                      : const [
                          BoxShadow(
                            color: AppColors.border,
                            offset: Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  '$index',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: muted ? scheme.outline : scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: muted
                                ? scheme.onSurfaceVariant
                                : scheme.primary,
                          ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: subtitleColor),
                      ),
                  ],
                ),
              ),
              Pill(
                label: badgeLabel,
                icon: badgeIcon,
                background: badgeBg,
                foreground: badgeFg,
                border: muted
                    ? scheme.outline.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: muted
                  ? scheme.surfaceContainer.withValues(alpha: 0.6)
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              '口诀：「${chapter.summary}」',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: muted ? scheme.outline : scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (counts != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TactileProgressBar(
                    value: ratio,
                    color: bar,
                    height: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  status == _ChapterStatus.mastered
                      ? '100%'
                      : '${counts.mastered}/${counts.total}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: status == _ChapterStatus.mastered
                        ? scheme.secondary
                        : muted
                        ? scheme.outline
                        : scheme.primary,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: muted ? scheme.outline : scheme.primary,
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (!current) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -10,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.honey,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(color: AppColors.border, offset: Offset(0, 2)),
              ],
            ),
            child: Text(
              '正在进行',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onTertiaryFixed),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 4.0;
        const gap = 3.0;
        final count = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          children: [
            for (var i = 0; i < count; i++)
              Container(
                width: dash,
                height: 1,
                margin: const EdgeInsets.only(right: gap),
                color: color,
              ),
          ],
        );
      },
    );
  }
}
