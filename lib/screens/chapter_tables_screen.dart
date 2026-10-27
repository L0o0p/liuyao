import 'package:flutter/material.dart';

import '../data/chapters.dart';
import '../widgets/atlas_table_view.dart';
import '../widgets/tactile.dart';

/// 只看本章对照表。做题时查表用，不写复习记录。
class ChapterTablesScreen extends StatelessWidget {
  final Chapter chapter;

  const ChapterTablesScreen({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              DetailHeader(title: chapter.title, icon: Icons.table_chart),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [AtlasChapterView(chapter: chapter.atlas)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
