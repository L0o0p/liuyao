import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/knowledge_catalog.dart';
import '../models/srs_card.dart';
import '../services/srs_scheduler.dart';
import '../services/storage_service.dart';
import '../services/sync/sync_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/mastery_counts.dart';
import '../widgets/tactile.dart';

/// 连续学习天数、整体掌握度、学习数据导入导出和清空卡片。
/// 已掌握：state 为 review，且间隔不少于 21 天。
class MineScreen extends StatefulWidget {
  const MineScreen({super.key});

  @override
  State<MineScreen> createState() => _MineScreenState();
}

class _MineScreenState extends State<MineScreen> {
  Map<String, SrsCard> _cards = {};
  bool _loading = true;
  bool _transferring = false;

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

  /// 导出复习卡片，交给系统分享面板。
  Future<void> _exportLearningData() async {
    if (_transferring) return;
    setState(() {
      _transferring = true;
    });
    try {
      final document = await SyncEngine.instance.exportDocument();
      final file = File(
        '${Directory.systemTemp.path}/liuyao-learning-data.json',
      );
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(document),
      );
      if (!mounted) return;
      final box = context.findRenderObject();
      final origin = box is RenderBox && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: '六爻学习数据',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _transferring = false;
        });
      }
    }
  }

  /// 选择导出文件，按合并规则导入，不覆盖本地较新的数据。
  Future<void> _importLearningData() async {
    if (_transferring) return;
    setState(() {
      _transferring = true;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      final String raw;
      if (picked.bytes != null) {
        raw = utf8.decode(picked.bytes!);
      } else if (picked.path != null) {
        raw = await File(picked.path!).readAsString();
      } else {
        throw const FormatException('无法读取所选文件');
      }

      final summary = await SyncEngine.instance.importJson(raw);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导入 ${summary.applied} 条，本地保留 ${summary.keptLocal} 条'),
        ),
      );
    } on FormatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败：$e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _transferring = false;
        });
      }
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空全部卡片'),
        content: const Text('确定要清掉全部复习卡片吗？所有知识点都会变成未学。'),
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
    await StorageService.clearAllCards();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已清掉全部卡片')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overall = SrsScheduler.count(
      KnowledgeCatalog.items.map((item) => item.itemKey),
      _cards,
    );
    final streak = SrsScheduler.studyStreakDays(_cards.values, DateTime.now());
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    '六爻入门速记',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                RoundIconButton(
                  icon: Icons.refresh,
                  tooltip: '刷新',
                  onPressed: _load,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      _StreakCard(days: streak),
                      const SizedBox(height: 12),
                      _OverallCard(counts: overall),
                      const SizedBox(height: 12),
                      _TransferCard(
                        busy: _transferring,
                        onExport: _exportLearningData,
                        onImport: _importLearningData,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 16,
                            color: scheme.outline,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '敏感数据管理区',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TactileButton(
                        label: '清空全部卡片',
                        icon: Icons.delete_forever,
                        style: TactileButtonStyle.danger,
                        onPressed: _clearAll,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '此操作将移除本地复习进度，建议提前导出备份',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: scheme.outline),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int days;

  const _StreakCard({required this.days});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return TactileCard(
      padding: const EdgeInsets.all(20),
      clip: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -44,
            bottom: -44,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2D0).withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pill(
                label: days > 0 ? '学习打卡进行中' : '今天开始打卡',
                icon: Icons.local_fire_department,
                iconColor: const Color(0xFFE07129),
                background: const Color(0xFFFDECD2),
                foreground: scheme.primary,
                border: AppColors.border.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '连续学习 ',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: '$days',
                      style: textTheme.displaySmall?.copyWith(height: 1),
                    ),
                    TextSpan(
                      text: ' 天',
                      style: textTheme.headlineSmall?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text('每天几分钟，熟记六爻基础', style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final SrsCounts counts;

  const _OverallCard({required this.counts});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TactileCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            title: '整体掌握度',
            trailing: Pill(
              label: '共 ${counts.total} 词条',
              background: scheme.surfaceContainerHigh,
              foreground: scheme.onSurfaceVariant,
              border: AppColors.border.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 14),
          MasteryCountRow(counts: counts),
          const SizedBox(height: 16),
          MasteryPercentLine(counts: counts),
          const SizedBox(height: 6),
          MasteryBar(counts: counts),
          const SizedBox(height: 12),
          const InfoNote(text: '已掌握是进入复习且间隔不少于 21 天的知识点。各章的掌握情况在「章节」里看。'),
        ],
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final bool busy;
  final VoidCallback onExport;
  final VoidCallback onImport;

  const _TransferCard({
    required this.busy,
    required this.onExport,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return TactileCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(title: '学习数据管理', icon: Icons.sync),
          const SizedBox(height: 8),
          Text(
            '可导出到文件，换机时再导入。导入会与本机数据合并，不会覆盖较新的记录。旧版本导出的备份也能导入。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TactileButton(
                  label: '导出学习数据',
                  icon: Icons.upload_file,
                  style: TactileButtonStyle.secondary,
                  onPressed: busy ? null : onExport,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TactileButton(
                  label: '导入学习数据',
                  icon: Icons.download_for_offline,
                  style: TactileButtonStyle.secondary,
                  onPressed: busy ? null : onImport,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
