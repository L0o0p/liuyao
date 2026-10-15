import 'package:flutter/material.dart';

import '../data/knowledge_catalog.dart';
import '../services/srs_scheduler.dart';
import '../services/storage_service.dart';
import 'study_session_screen.dart';

/// 按模块巩固。队列只含这个模块，不受今日新学上限约束。
class StudyModuleScreen extends StatelessWidget {
  final String moduleType;

  const StudyModuleScreen({super.key, required this.moduleType});

  @override
  Widget build(BuildContext context) {
    final module = KnowledgeCatalog.module(moduleType);
    return StudySessionScreen(
      title: module?.name ?? '学习',
      restEvery: module?.partSize,
      loadItemKeys: () => loadModuleQueue(moduleType),
    );
  }
}

Future<List<String>> loadModuleQueue(String moduleId) async {
  final cards = await StorageService.loadCards();
  final keys = [
    for (final item in KnowledgeCatalog.itemsForModule(moduleId)) item.itemKey,
  ];
  return SrsScheduler.moduleQueue(
    moduleItemKeys: keys,
    cards: cards,
    now: DateTime.now(),
  );
}
