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
  int _streak = 0;
  Map<String, SrsCard> _cards = {};

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
      _streak = SrsScheduler.studyStreakDays(state.cards.values, state.now);
      _cards = state.cards;
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
    final scheme = Theme.of(context).colorScheme;
    final finished = !_loading && _dueCount == 0 && _newCount == 0;
    final next = _nextGroup;
    final routeGroup = _todayGroup ?? next;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: '今日学习',
            badge: Pill(
              label: _dateLabel(DateTime.now()),
              background: scheme.surface,
              foreground: scheme.primaryContainer,
              border: AppColors.border,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 32,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _StreakCard(days: _streak),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _CountCard(
                                    tag: '待温故',
                                    tagIcon: Icons.history,
                                    label: '到期复习',
                                    hint: '巩固遗忘曲线',
                                    value: _dueCount,
                                    accent: scheme.primary,
                                    tagBackground: scheme.surfaceContainer,
                                    tagForeground: scheme.primaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _CountCard(
                                    tag: '新知识',
                                    tagIcon: Icons.auto_awesome,
                                    label: '今天可新学',
                                    hint: '轻松开启新爻位',
                                    value: _newCount,
                                    accent: scheme.secondary,
                                    tagBackground: scheme.secondaryContainer,
                                    tagForeground: scheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _newLine,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            if (finished)
                              ..._finishedActions(context, next)
                            else
                              TactileButton(
                                label: '开始学习',
                                icon: Icons.play_circle,
                                trailingIcon: Icons.arrow_forward,
                                large: true,
                                onPressed: _starting ? null : _start,
                              ),
                            if (routeGroup != null) ...[
                              const SizedBox(height: 16),
                              _RouteCard(group: routeGroup, cards: _cards),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _finishedActions(BuildContext context, StudyGroup? next) {
    return [
      Text(
        '今天已经学完',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 4),
      Text(
        '还可以到「章节」里按章巩固',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      if (next != null) ...[
        TactileButton(
          label: '再学一组：${next.title}（$_nextCount 条）',
          icon: Icons.add_circle,
          onPressed: _starting ? null : () => _start(extraGroup: true),
        ),
        const SizedBox(height: 8),
      ],
      if (widget.onOpenChapters != null)
        TactileButton(
          label: '去章节巩固',
          icon: Icons.auto_stories,
          style: TactileButtonStyle.secondary,
          onPressed: widget.onOpenChapters,
        ),
    ];
  }
}

String _dateLabel(DateTime date) {
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return '${date.month}月${date.day}日 周${weekdays[date.weekday - 1]}';
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

class _StreakCard extends StatelessWidget {
  final int days;

  const _StreakCard({required this.days});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TactileCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                scheme.tertiaryFixed.withValues(alpha: 0.4),
                AppColors.card,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: const [
                BoxShadow(color: AppColors.border, offset: Offset(0, 2)),
              ],
            ),
            child: Icon(
              Icons.local_fire_department,
              color: days > 0 ? scheme.primaryContainer : scheme.outline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '连续打卡 ',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextSpan(
                        text: '$days',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      TextSpan(
                        text: ' 天',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: scheme.primary),
                      ),
                    ],
                  ),
                ),
                Text(
                  days > 0 ? '好棒！保持节奏，记忆更深刻～' : '今天开始，每天几分钟就够',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String tag;
  final IconData tagIcon;
  final String label;
  final String hint;
  final int value;
  final Color accent;
  final Color tagBackground;
  final Color tagForeground;

  const _CountCard({
    required this.tag,
    required this.tagIcon,
    required this.label,
    required this.hint,
    required this.value,
    required this.accent,
    required this.tagBackground,
    required this.tagForeground,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TactileCard(
      child: Column(
        children: [
          Pill(
            label: tag,
            icon: tagIcon,
            background: tagBackground,
            foreground: tagForeground,
            border: tagForeground.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$value',
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(color: accent, height: 1),
                ),
                TextSpan(
                  text: ' 个',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            hint,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

/// 当前学到的章节：第几组、本章已掌握比例。
class _RouteCard extends StatelessWidget {
  final StudyGroup group;
  final Map<String, SrsCard> cards;

  const _RouteCard({required this.group, required this.cards});

  @override
  Widget build(BuildContext context) {
    final chapter = Chapters.byId(group.chapterId);
    if (chapter == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final groups = StudyGroups.forChapter(chapter.id);
    final position = groups.indexWhere((g) => g.id == group.id) + 1;
    final counts = SrsScheduler.count(chapter.itemKeys, cards);
    final ratio = counts.total == 0 ? 0.0 : counts.mastered / counts.total;
    return TactileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: scheme.primaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chapter.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: scheme.primary),
                ),
              ),
              Pill(
                label: '进行中',
                background: scheme.surfaceContainer,
                foreground: scheme.onSurfaceVariant,
                border: AppColors.border.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TactileProgressBar(value: ratio, color: scheme.secondary, height: 14),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '共 ${groups.length} 组 · 第 $position 组',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                '已掌握 ${(ratio * 100).round()}%',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: scheme.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
