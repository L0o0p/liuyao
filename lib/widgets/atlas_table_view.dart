import 'package:flutter/material.dart';

import '../data/atlas_tables.dart';

/// 一章的口诀和全部对照表。放进外层的纵向滚动里用。
class AtlasChapterView extends StatelessWidget {
  final AtlasChapter chapter;

  const AtlasChapterView({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(chapter.summary, style: Theme.of(context).textTheme.bodyLarge),
        for (final table in chapter.tables) ...[
          const SizedBox(height: 20),
          Text(table.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          AtlasTableView(table: table),
        ],
      ],
    );
  }
}

/// 列多时横向滚动。
class AtlasTableView extends StatelessWidget {
  final AtlasTable table;

  const AtlasTableView({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
