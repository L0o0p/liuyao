import 'atlas_tables.dart';
import 'knowledge_catalog.dart';

/// 一章：对照表加上本章要练的题型。
///
/// 按题型而不是模块圈定知识点：天干、地支两章横跨原来按属性分的几个模块。
/// 模块 id 和卡片键都不受影响。
class Chapter {
  final String id;
  final AtlasChapter atlas;
  final List<String> questionTypes;

  /// 每答完这么多题提示休息。只影响界面，不写进度。
  final int? restEvery;

  const Chapter({
    required this.id,
    required this.atlas,
    required this.questionTypes,
    this.restEvery,
  });

  String get title => atlas.title;

  String get summary => atlas.summary;

  /// 本章知识点，保持目录顺序。
  List<KnowledgeItem> get items =>
      KnowledgeCatalog.itemsForTypes(questionTypes);

  List<String> get itemKeys => [for (final item in items) item.itemKey];
}

class Chapters {
  Chapters._();

  /// 按学习顺序排列。
  static final List<Chapter> all = _buildChapters();

  static Chapter? byId(String id) {
    for (final chapter in all) {
      if (chapter.id == id) return chapter;
    }
    return null;
  }

  /// 题型所属的章节。目录里的每个题型都恰好属于一章，由单测保证。
  /// 旧的十二长生题型已不在目录里，仍归到十二长生章。
  static Chapter? forQuestionType(String questionType) {
    if (questionType == KnowledgeCatalog.legacyChangShengType) {
      return byId('changsheng');
    }
    for (final chapter in all) {
      if (chapter.questionTypes.contains(questionType)) return chapter;
    }
    return null;
  }
}

List<Chapter> _buildChapters() {
  return [
    Chapter(
      id: 'wuxing_shengke',
      atlas: wuXingAtlas(),
      questionTypes: const ['wuxing_sheng', 'wuxing_ke'],
    ),
    Chapter(
      id: 'tiangan',
      atlas: tianGanAtlas(),
      questionTypes: const [
        'gan_wuxing',
        'gan_yinyang',
        'gan_direction',
        'gan_season',
        'gan_month',
        'gan_time',
      ],
    ),
    Chapter(
      id: 'dizhi',
      atlas: diZhiAtlas(),
      questionTypes: const [
        'zhi_wuxing',
        'zhi_yinyang',
        'zhi_direction',
        'zhi_season',
        'zhi_month',
        'zhi_time',
        'zhi_hour',
        'finger_forward',
        'finger_reverse',
      ],
    ),
    Chapter(
      id: 'xingchonghehai',
      atlas: xingChongHeHaiAtlas(),
      questionTypes: const [
        'zhi_liuhe',
        'zhi_sanhe',
        'zhi_sanxing',
        'zhi_zixing',
        'zhi_liuchong',
        'zhi_liuhai',
        'zhi_poxiang',
      ],
    ),
    Chapter(
      id: 'changsheng',
      atlas: changShengAtlas(),
      questionTypes: const [
        KnowledgeCatalog.changShengStageType,
        KnowledgeCatalog.changShengStartType,
      ],
    ),
    Chapter(
      id: 'kongwang',
      atlas: kongWangAtlas(),
      questionTypes: const [KnowledgeCatalog.kongWangType],
    ),
    Chapter(
      id: 'gua64',
      atlas: guaAtlas(),
      questionTypes: const ['gua_to_xiang', 'xiang_to_gua'],
      restEvery: KnowledgeCatalog.module('64gua')?.partSize,
    ),
    Chapter(
      id: 'shiying',
      atlas: shiYingAtlas(),
      questionTypes: const [KnowledgeCatalog.shiYingType],
    ),
    Chapter(
      id: 'liuqin',
      atlas: liuQinAtlas(),
      questionTypes: const [KnowledgeCatalog.liuQinType],
    ),
    Chapter(
      id: 'yongshen',
      atlas: yongShenAtlas(),
      questionTypes: const [KnowledgeCatalog.yongShenType],
    ),
    Chapter(
      id: 'wangxiang',
      atlas: wangXiangAtlas(),
      questionTypes: const [KnowledgeCatalog.wangXiangType],
    ),
  ];
}
