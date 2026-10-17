import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/data/chapters.dart';
import 'package:liuyao/data/knowledge_catalog.dart';
import 'package:liuyao/data/study_groups.dart';

void main() {
  test('目录里每个知识点恰好属于一个小组', () {
    final owners = <String, List<String>>{};
    for (final group in StudyGroups.all) {
      for (final key in group.itemKeys) {
        owners.putIfAbsent(key, () => []).add(group.id);
      }
    }
    for (final item in KnowledgeCatalog.items) {
      expect(owners[item.itemKey], hasLength(1), reason: item.itemKey);
    }
    expect(
      owners.keys.toSet(),
      KnowledgeCatalog.items.map((item) => item.itemKey).toSet(),
    );
  });

  test('小组按章节学习顺序排成一条线，组内知识点属于所在章节', () {
    final chapterIds = Chapters.all.map((chapter) => chapter.id).toList();
    var last = 0;
    for (final group in StudyGroups.all) {
      final index = chapterIds.indexOf(group.chapterId);
      expect(index, greaterThanOrEqualTo(last), reason: group.id);
      last = index;
      final chapterKeys = Chapters.byId(group.chapterId)!.itemKeys.toSet();
      expect(chapterKeys.containsAll(group.itemKeys), isTrue, reason: group.id);
    }
    expect(
      StudyGroups.all.map((group) => group.chapterId).toSet(),
      chapterIds.toSet(),
    );
  });

  test('目录 382 条知识点分成 33 组', () {
    expect(KnowledgeCatalog.items, hasLength(382));
    expect(StudyGroups.all, hasLength(33));
  });

  test('小组 id 唯一，大小适中，每组有表和口诀', () {
    expect(
      StudyGroups.all.map((group) => group.id).toSet(),
      hasLength(StudyGroups.all.length),
    );
    for (final group in StudyGroups.all) {
      expect(group.itemKeys.length, inInclusiveRange(4, 16), reason: group.id);
      expect(group.tables, isNotEmpty, reason: group.id);
      expect(group.tables.every((t) => t.rows.isNotEmpty), isTrue);
      expect(group.mnemonic, isNotEmpty, reason: group.id);
    }
  });

  test('从五行相生开始；六十四卦按八宫分 8 组，每组 8 卦两种问法', () {
    expect(StudyGroups.all.first.id, 'wuxing_sheng');
    expect(StudyGroups.byId('tiangan_wuxing')!.itemKeys, hasLength(10));
    expect(StudyGroups.byId('tiangan_wuxing')!.tables.single.columns, [
      '天干',
      '五行',
    ]);

    final gua = StudyGroups.forChapter('gua64');
    expect(gua.map((group) => group.title).toList(), [
      '乾宫八卦',
      '坤宫八卦',
      '震宫八卦',
      '巽宫八卦',
      '坎宫八卦',
      '离宫八卦',
      '艮宫八卦',
      '兑宫八卦',
    ]);
    final qian = gua.first;
    expect(qian.itemKeys, hasLength(16));
    expect(qian.itemKeys, contains('gua_to_xiang:大有'));
    expect(qian.itemKeys, contains('xiang_to_gua:火天'));
    expect(qian.tables.single.rows.map((row) => row.first), contains('姤'));

    final changSheng = StudyGroups.forChapter('changsheng');
    expect(changSheng.map((group) => group.id), [
      'changsheng_stage',
      'changsheng_start',
    ]);
    expect(changSheng.last.itemKeys, hasLength(5));
  });

  test('下一组是第一个还有没引入的知识点的组', () {
    expect(StudyGroups.next({})!.id, 'wuxing_sheng');
    final sheng = StudyGroups.byId('wuxing_sheng')!.itemKeys.toSet();
    expect(StudyGroups.next(sheng)!.id, 'wuxing_ke');
    final partial = {...sheng}..remove(sheng.first);
    expect(StudyGroups.next(partial)!.id, 'wuxing_sheng');
    final everything = KnowledgeCatalog.items.map((e) => e.itemKey).toSet();
    expect(StudyGroups.next(everything), isNull);
  });
}
