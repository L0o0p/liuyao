import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../data/knowledge_catalog.dart';
import '../models/module_progress.dart';
import '../services/storage_service.dart';
import '../services/sync/sync_engine.dart';
import 'study_module_screen.dart';

/// 进度页面
/// 展示用户在各个学习模块的学习进度和统计数据
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  /// 模块列表、名称和图标都来自知识点目录。
  List<StudyModule> get _modules => KnowledgeCatalog.modules;

  /// 存储所有模块的进度数据
  Map<String, ModuleProgress> _progressMap = {};
  bool _isLoading = true;
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    SyncEngine.dataVersion.addListener(_onDataChanged);
    _loadAllProgress();
  }

  @override
  void dispose() {
    SyncEngine.dataVersion.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    _loadAllProgress(showLoading: false);
  }

  /// 加载所有模块的进度数据
  Future<void> _loadAllProgress({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final Map<String, ModuleProgress> progressMap = {};
    for (final module in _modules) {
      final progress = await StorageService.loadProgress(module.id);
      progressMap[module.id] = progress;
    }

    if (!mounted) return;
    setState(() {
      _progressMap = progressMap;
      _isLoading = false;
    });
  }

  /// 导出进度和错题，交给系统分享面板。
  Future<void> _exportLearningData() async {
    if (_isTransferring) return;
    setState(() {
      _isTransferring = true;
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
          _isTransferring = false;
        });
      }
    }
  }

  /// 选择导出文件，按合并规则导入，不覆盖本地较新的数据。
  Future<void> _importLearningData() async {
    if (_isTransferring) return;
    setState(() {
      _isTransferring = true;
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
      await _loadAllProgress(showLoading: false);
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
          _isTransferring = false;
        });
      }
    }
  }

  /// 计算总体统计数据
  _OverallStats _calculateOverallStats() {
    int totalCorrect = 0;
    int totalWrong = 0;
    int completedModules = 0;

    for (final progress in _progressMap.values) {
      totalCorrect += progress.totalCorrectCount;
      totalWrong += progress.totalWrongCount;
      if (progress.firstRoundCompleted) {
        completedModules++;
      }
    }

    return _OverallStats(
      totalCorrect: totalCorrect,
      totalWrong: totalWrong,
      completedModules: completedModules,
      totalModules: _modules.length,
    );
  }

  /// 清空所有进度（确认后）
  Future<void> _resetAllProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('确定要清空所有学习进度吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearAllProgress();
      await _loadAllProgress();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已清空所有进度')));
      }
    }
  }

  /// 清空单个模块进度
  Future<void> _resetModuleProgress(String moduleId, String moduleName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: Text('确定要清空「$moduleName」的学习进度吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearProgress(moduleId);
      await _loadAllProgress();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已清空「$moduleName」进度')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final stats = _calculateOverallStats();

    return Scaffold(
      appBar: AppBar(title: const Text("学习进度"), centerTitle: true),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 学习数据导出 / 导入
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '学习数据',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '可导出到文件，换机时再导入。导入会与本机数据合并，不会覆盖较新的记录。',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isTransferring
                              ? null
                              : _exportLearningData,
                          icon: const Icon(Icons.ios_share),
                          label: const Text('导出学习数据'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _isTransferring
                              ? null
                              : _importLearningData,
                          icon: const Icon(Icons.file_open_outlined),
                          label: const Text('导入学习数据'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 总体统计卡片
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "学习进度",
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadAllProgress,
                          tooltip: '刷新进度',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildOverallStatsCard(stats),
                  ],
                ),
              ),
            ),

            // 模块进度列表
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final module = _modules[index];
                  final progress = _progressMap[module.id]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildModuleProgressCard(module, progress),
                  );
                }, childCount: _modules.length),
              ),
            ),

            // 底部重置按钮
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: OutlinedButton.icon(
                  onPressed: _resetAllProgress,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    '清空所有进度',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建总体统计卡片
  Widget _buildOverallStatsCard(_OverallStats stats) {
    final totalQuestions = stats.totalCorrect + stats.totalWrong;
    final accuracy = totalQuestions > 0
        ? stats.totalCorrect / totalQuestions
        : 0.0;

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.check_circle_outline,
                  label: '总答题数',
                  value: totalQuestions.toString(),
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.trending_up,
                  label: '正确率',
                  value: '${(accuracy * 100).toStringAsFixed(1)}%',
                  color: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.emoji_events,
                  label: '完成模块',
                  value: '${stats.completedModules}/${stats.totalModules}',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stats.totalModules > 0
                  ? stats.completedModules / stats.totalModules
                  : 0.0,
              backgroundColor: Colors.grey[200],
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '已完成 ${stats.completedModules} 个模块的首轮学习',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  /// 构建单个模块进度卡片
  Widget _buildModuleProgressCard(StudyModule module, ModuleProgress progress) {
    final totalQuestions =
        progress.totalCorrectCount + progress.totalWrongCount;
    final accuracy = totalQuestions > 0
        ? progress.totalCorrectCount / totalQuestions
        : 0.0;

    return Card(
      child: InkWell(
        onTap: () {
          // 点击进入学习
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyModuleScreen(moduleType: module.id),
            ),
          ).then((_) => _loadAllProgress());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 模块图标
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: module.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(module.icon, color: module.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  // 模块名称和状态
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusBadge(progress),
                            const SizedBox(width: 8),
                            if (totalQuestions > 0)
                              Text(
                                '${totalQuestions}题 · ${(accuracy * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 更多操作按钮
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'reset') {
                        _resetModuleProgress(module.id, module.name);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('重置进度'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (totalQuestions > 0) ...[
                const SizedBox(height: 12),
                // 进度条
                LinearProgressIndicator(
                  value: accuracy,
                  backgroundColor: Colors.grey[200],
                  color: module.color,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建状态徽章
  Widget _buildStatusBadge(ModuleProgress progress) {
    final isCompleted = progress.firstRoundCompleted;
    final hasStarted =
        progress.totalCorrectCount + progress.totalWrongCount > 0;

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Text(
          '✓ 已完成首轮',
          style: TextStyle(
            fontSize: 10,
            color: Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (hasStarted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: const Text(
          '学习中',
          style: TextStyle(
            fontSize: 10,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: const Text(
          '未开始',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }
}

/// 模块配置类
/// 定义模块的基本信息（ID、名称、图标、颜色）
/// 总体统计数据类
class _OverallStats {
  final int totalCorrect;
  final int totalWrong;
  final int completedModules;
  final int totalModules;

  _OverallStats({
    required this.totalCorrect,
    required this.totalWrong,
    required this.completedModules,
    required this.totalModules,
  });
}
