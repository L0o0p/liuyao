import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/data/atlas_tables.dart';
import 'package:liuyao/data/knowledge_catalog.dart';
import 'package:liuyao/data/teaching_notes.dart';

void main() {
  test('教学卡的结论包含正确答案', () {
    for (final item in KnowledgeCatalog.items) {
      final note = TeachingNotes.forItem(item);
      expect(
        note.fact,
        contains(item.correctAnswer),
        reason: item.itemKey,
      );
      expect(note.hint, isNotEmpty, reason: item.itemKey);
    }
  });

  test('没学过的键也能取出教学卡', () {
    final note = TeachingNotes.forKey('gua_to_xiang:乾');
    expect(note, isNotNull);
    expect(note!.fact, contains('天天'));
  });

  test('图鉴覆盖主要对照表', () {
    final titles = buildAtlasChapters().map((chapter) => chapter.title).toList();
    expect(titles, ['五行生克', '天干', '地支', '刑冲合害', '十二长生', '六十四卦']);
    final gua = buildAtlasChapters().firstWhere(
      (chapter) => chapter.title == '六十四卦',
    );
    expect(gua.tables.single.rows, hasLength(64));
  });
}
