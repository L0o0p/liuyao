import 'package:flutter/material.dart';

import '../data/atlas_tables.dart';

/// 可查阅的知识表。不写复习记录。
class AtlasScreen extends StatelessWidget {
  const AtlasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chapters = buildAtlasChapters();
    return Scaffold(
      appBar: AppBar(title: const Text('图鉴')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: chapters.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AtlasChapterScreen(chapter: chapter),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        chapter.summary,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AtlasChapterScreen extends StatelessWidget {
  final AtlasChapter chapter;

  const AtlasChapterScreen({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chapter.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(chapter.summary, style: Theme.of(context).textTheme.bodyLarge),
            for (final table in chapter.tables) ...[
              const SizedBox(height: 20),
              Text(table.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              _AtlasTableView(table: table),
            ],
          ],
        ),
      ),
    );
  }
}

class _AtlasTableView extends StatelessWidget {
  final AtlasTable table;

  const _AtlasTableView({required this.table});

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final cellStyle = Theme.of(context).textTheme.bodyLarge;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: Theme.of(context).dividerColor),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
            ),
            children: [
              for (final column in table.columns)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(column, style: headerStyle),
                ),
            ],
          ),
          for (final row in table.rows)
            TableRow(
              children: [
                for (final cell in row)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(cell, style: cellStyle),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
