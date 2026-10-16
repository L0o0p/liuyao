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
import '../widgets/mastery_counts.dart';

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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
    final overall = SrsScheduler.count(
      KnowledgeCatalog.items.map((item) => item.itemKey),
      _cards,
    );
    final streak = SrsScheduler.studyStreakDays(_cards.values, DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StreakCard(days: streak),
                  const SizedBox(height: 12),
                  _OverallCard(counts: overall),
                  const SizedBox(height: 8),
                  Text(
                    '已掌握是进入复习且间隔不少于 21 天的知识点。各章的掌握情况在「章节」里看。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _TransferCard(
                    busy: _transferring,
                    onExport: _exportLearningData,
                    onImport: _importLearningData,
                  ),
                  const SizedBox(height: 24),
                  Text('设置', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _clearAll,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('清空全部卡片'),
                  ),
                ],
              ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text('学习数据', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '可导出到文件，换机时再导入。导入会与本机数据合并，不会覆盖较新的记录。旧版本导出的备份也能导入。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : onExport,
              icon: const Icon(Icons.ios_share),
              label: const Text('导出学习数据'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : onImport,
              icon: const Icon(Icons.file_open_outlined),
              label: const Text('导入学习数据'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int days;

  const _StreakCard({required this.days});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 36,
              color: days > 0 ? Colors.deepOrange : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('连续学习', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    '$days 天',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final SrsCounts counts;

  const _OverallCard({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('整体掌握度', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            MasteryCountRow(counts: counts),
            const SizedBox(height: 16),
            MasteryBar(counts: counts),
          ],
        ),
      ),
    );
  }
}
