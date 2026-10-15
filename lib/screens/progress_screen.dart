import 'package:flutter/material.dart';

import '../data/knowledge_catalog.dart';
import '../models/srs_card.dart';
import '../services/srs_scheduler.dart';
import '../services/storage_service.dart';
import '../services/sync/sync_engine.dart';
import 'study_module_screen.dart';

/// 按模块显示已掌握、学习中、未学。
/// 已掌握：state 为 review，且间隔不少于 21 天。
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
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

  Future<void> _clearModule(String moduleId, String moduleName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空卡片'),
        content: Text('确定要清掉「$moduleName」的复习卡片吗？这些知识点会变成未学。'),
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
    await StorageService.clearModule(moduleId);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已清掉「$moduleName」的卡片')));
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
    final modules = KnowledgeCatalog.modules;
    final overall = SrsScheduler.count(
      KnowledgeCatalog.items.map((item) => item.itemKey),
      _cards,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习进度'),
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
                  _OverallCard(counts: overall),
                  const SizedBox(height: 8),
                  Text(
                    '已掌握是进入复习且间隔不少于 21 天的知识点。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  for (final module in modules) ...[
                    _ModuleCard(
                      module: module,
                      counts: SrsScheduler.count(
                        KnowledgeCatalog.itemsForModule(
                          module.id,
                        ).map((item) => item.itemKey),
                        _cards,
                      ),
                      onOpen: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StudyModuleScreen(moduleType: module.id),
                          ),
                        ).then((_) => _load());
                      },
                      onClear: () => _clearModule(module.id, module.name),
                    ),
                    const SizedBox(height: 12),
                  ],
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

class _OverallCard extends StatelessWidget {
  final SrsCounts counts;

  const _OverallCard({required this.counts});

  @override
  Widget build(BuildContext context) {
    final ratio = counts.total == 0 ? 0.0 : counts.mastered / counts.total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _CountRow(counts: counts),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: ratio, minHeight: 8),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final StudyModule module;
  final SrsCounts counts;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  const _ModuleCard({
    required this.module,
    required this.counts,
    required this.onOpen,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = counts.total == 0 ? 0.0 : counts.mastered / counts.total;
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(module.icon, color: module.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      module.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'clear') onClear();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'clear', child: Text('清空卡片')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CountRow(counts: counts),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                color: module.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  final SrsCounts counts;

  const _CountRow({required this.counts});

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

class _Count extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Count({
    required this.label,
    required this.value,
    required this.color,
  });

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
