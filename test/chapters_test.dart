import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/data/chapters.dart';
import 'package:liuyao/data/knowledge_catalog.dart';

void main() {
  test('章节按学习顺序排列', () {
    expect(Chapters.all.map((chapter) => chapter.title).toList(), [
      '五行生克',
      '天干',
      '地支',
      '刑冲合害',
      '十二长生',
      '六十四卦',
    ]);
    expect(
      Chapters.all.map((chapter) => chapter.id).toSet(),
      hasLength(Chapters.all.length),
    );
  });

  test('目录里每个题型都恰好映射到一章', () {
    final catalogTypes = KnowledgeCatalog.items
        .map((item) => item.questionType)
        .toSet();
    for (final type in catalogTypes) {
      final owners = Chapters.all
          .where((chapter) => chapter.questionTypes.contains(type))
          .toList();
      expect(owners, hasLength(1), reason: type);
      expect(Chapters.forQuestionType(type), same(owners.single));
    }
    final chapterTypes = {
      for (final chapter in Chapters.all) ...chapter.questionTypes,
    };
    expect(chapterTypes, catalogTypes);
  });

  test('章节合起来正好覆盖全部知识点，键格式不变', () {
    final keys = [for (final chapter in Chapters.all) ...chapter.itemKeys];
    expect(keys.toSet(), hasLength(keys.length));
    expect(
      keys.toSet(),
      KnowledgeCatalog.items.map((item) => item.itemKey).toSet(),
    );
    expect(Chapters.byId('tiangan')!.itemKeys, contains('gan_wuxing:甲'));
    expect(Chapters.byId('dizhi')!.itemKeys, contains('finger_forward:子'));
    expect(Chapters.byId('gua64')!.itemKeys, contains('gua_to_xiang:讼'));
  });

  test('每个模块的知识点都落在章节里', () {
    final chapterKeys = {
      for (final chapter in Chapters.all) ...chapter.itemKeys,
    };
    for (final module in KnowledgeCatalog.modules) {
      for (final item in KnowledgeCatalog.itemsForModule(module.id)) {
        expect(chapterKeys, contains(item.itemKey), reason: module.id);
      }
    }
  });

  test('天干章只含天干，指诀并入地支章', () {
    final tianGan = Chapters.byId('tiangan')!;
    expect(tianGan.items, hasLength(60));
    expect(
      tianGan.questionTypes.every((type) => type.startsWith('gan_')),
      isTrue,
    );
    expect(Chapters.forQuestionType('finger_reverse')!.id, 'dizhi');
    expect(Chapters.forQuestionType('zhi_hour')!.id, 'dizhi');
    expect(Chapters.forQuestionType('zhi_liuchong')!.id, 'xingchonghehai');
    expect(Chapters.forQuestionType('未知题型'), isNull);
  });

  test('六十四卦章每 16 题休息，其余章节不打断', () {
    expect(Chapters.byId('gua64')!.restEvery, 16);
    expect(Chapters.byId('dizhi')!.restEvery, isNull);
  });

  test('章节表格来自图鉴，地支章同时有属性表和指诀表', () {
    final diZhi = Chapters.byId('dizhi')!;
    expect(diZhi.atlas.tables.map((table) => table.title), ['地支属性', '十二支指诀']);
    expect(diZhi.atlas.tables.last.rows, hasLength(12));
  });
}
