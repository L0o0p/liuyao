import 'package:flutter/material.dart';

import '../data/atlas_tables.dart';
import '../theme/app_theme.dart';
import 'tactile.dart';

/// 一章的口诀卡和全部对照表卡。放进外层的纵向滚动里用。
class AtlasChapterView extends StatelessWidget {
  final AtlasChapter chapter;

  const AtlasChapterView({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MnemonicCard(title: '${chapter.title}核心口诀', text: chapter.summary),
        for (final table in chapter.tables) ...[
          const SizedBox(height: 12),
          AtlasTableCard(table: table),
        ],
      ],
    );
  }
}

/// 便签风格的口诀卡。
class MnemonicCard extends StatelessWidget {
  final String title;
  final String text;

  const MnemonicCard({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TactileCard(
          color: scheme.surface,
          shadowColor: AppColors.border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE047),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.border,
                          offset: Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lightbulb,
                      size: 17,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -4,
          left: 24,
          child: Container(
            width: 32,
            height: 14,
            decoration: BoxDecoration(
              color: scheme.tertiaryFixedDim.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 带标题的对照表卡。
class AtlasTableCard extends StatelessWidget {
  final AtlasTable table;

  const AtlasTableCard({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TactileCard(
      color: scheme.surface,
      shadowColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            title: table.title,
            trailing: table.columns.length > 4
                ? Pill(
                    label: '可左右滑动',
                    icon: Icons.swap_horiz,
                    background: scheme.surfaceContainer,
                    foreground: scheme.onSurfaceVariant,
                    border: AppColors.border.withValues(alpha: 0.3),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          AtlasTableView(table: table),
        ],
      ),
    );
  }
}

/// 表头是圆角底条，每行是一张小卡片。列多时横向滚动。
class AtlasTableView extends StatelessWidget {
  final AtlasTable table;

  const AtlasTableView({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final columnCount = table.columns.length;
    final headerStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant);
    final rowDecoration = BoxDecoration(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.border.withValues(alpha: 0.15),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.border.withValues(alpha: 0.12),
          offset: const Offset(0, 1.5),
        ),
      ],
    );
    final gap = TableRow(
      children: List.filled(columnCount, const SizedBox(height: 6)),
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(flex: 1),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                children: [
                  for (final column in table.columns)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        column,
                        style: headerStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
              for (final row in table.rows) ...[
                gap,
                TableRow(
                  decoration: rowDecoration,
                  children: [
                    for (var i = 0; i < row.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Center(
                          child: _Cell(text: row[i], lead: i == 0),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;

  /// 第一列是这一行的主键，字更大更粗。
  final bool lead;

  const _Cell({required this.text, required this.lead});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = WuXingColors.byName[text];
    if (colors != null && !lead) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: ShapeDecoration(
          color: colors.background,
          shape: StadiumBorder(side: BorderSide(color: colors.border)),
        ),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.foreground),
        ),
      );
    }
    if ((text == '阴' || text == '阳') && !lead) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: ShapeDecoration(
          color: text == '阳'
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerHigh,
          shape: const StadiumBorder(),
        ),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: scheme.primary),
        ),
      );
    }
    final style = lead
        ? Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: scheme.primary)
        : Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.primary);
    return Text(text, style: style, textAlign: TextAlign.center);
  }
}
