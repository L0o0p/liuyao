import 'atlas_tables.dart';
import 'gua_data.dart';
import 'knowledge_catalog.dart';

/// 新知识按小组引入：先看整组对照表和口诀，再逐条练。
///
/// id 存在每日记录里，发布后不能改名。
class StudyGroup {
  final String id;
  final String title;
  final String chapterId;
  final List<String> itemKeys;
  final List<AtlasTable> tables;
  final String mnemonic;

  const StudyGroup({
    required this.id,
    required this.title,
    required this.chapterId,
    required this.itemKeys,
    required this.tables,
    required this.mnemonic,
  });
}

class StudyGroups {
  StudyGroups._();

  /// 按章节学习顺序排成一条线，章内按引入顺序。
  static final List<StudyGroup> all = _buildGroups();

  static StudyGroup? byId(String id) {
    for (final group in all) {
      if (group.id == id) return group;
    }
    return null;
  }

  static List<StudyGroup> forChapter(String chapterId) {
    return all.where((group) => group.chapterId == chapterId).toList();
  }

  /// 第一个还有没引入过的知识点的组。[introduced] 是已经有卡片的知识点。
  static StudyGroup? next(Set<String> introduced) {
    for (final group in all) {
      if (group.itemKeys.any((key) => !introduced.contains(key))) {
        return group;
      }
    }
    return null;
  }
}

List<StudyGroup> _buildGroups() {
  final wuXing = wuXingAtlas();
  final tianGan = tianGanAtlas();
  final diZhi = diZhiAtlas();
  final relations = xingChongHeHaiAtlas();
  final changSheng = changShengAtlas();
  final kongWang = kongWangAtlas();
  final gua = guaAtlas();

  StudyGroup byTypes({
    required String id,
    required String title,
    required String chapterId,
    required List<String> types,
    required List<AtlasTable> tables,
    required String mnemonic,
  }) {
    return StudyGroup(
      id: id,
      title: title,
      chapterId: chapterId,
      itemKeys: [
        for (final item in KnowledgeCatalog.itemsForTypes(types)) item.itemKey,
      ],
      tables: tables,
      mnemonic: mnemonic,
    );
  }

  StudyGroup ganGroup(
    String id,
    String title,
    String type,
    String column,
    String mnemonic,
  ) {
    return byTypes(
      id: id,
      title: title,
      chapterId: 'tiangan',
      types: [type],
      tables: [
        _pick(_table(tianGan, '天干属性'), ['天干', column]),
      ],
      mnemonic: mnemonic,
    );
  }

  StudyGroup zhiGroup(
    String id,
    String title,
    String type,
    String column,
    String mnemonic,
  ) {
    return byTypes(
      id: id,
      title: title,
      chapterId: 'dizhi',
      types: [type],
      tables: [
        _pick(_table(diZhi, '地支属性'), ['地支', column]),
      ],
      mnemonic: mnemonic,
    );
  }

  StudyGroup relationGroup(
    String id,
    String title,
    List<String> types,
    List<String> tableTitles,
    String mnemonic,
  ) {
    return byTypes(
      id: id,
      title: title,
      chapterId: 'xingchonghehai',
      types: types,
      tables: [for (final name in tableTitles) _table(relations, name)],
      mnemonic: mnemonic,
    );
  }

  final groups = <StudyGroup>[
    byTypes(
      id: 'wuxing_sheng',
      title: '五行相生',
      chapterId: 'wuxing_shengke',
      types: ['wuxing_sheng'],
      tables: [
        _pick(_table(wuXing, '生与克'), ['五行', '所生']),
      ],
      mnemonic: '木生火，火生土，土生金，金生水，水生木。',
    ),
    byTypes(
      id: 'wuxing_ke',
      title: '五行相克',
      chapterId: 'wuxing_shengke',
      types: ['wuxing_ke'],
      tables: [
        _pick(_table(wuXing, '生与克'), ['五行', '所克']),
      ],
      mnemonic: '木克土，土克水，水克火，火克金，金克木。',
    ),
    ganGroup(
      'tiangan_wuxing',
      '天干五行',
      'gan_wuxing',
      '五行',
      '甲乙东方木，丙丁南方火，戊己中央土，庚辛西方金，壬癸北方水。',
    ),
    ganGroup(
      'tiangan_yinyang',
      '天干阴阳',
      'gan_yinyang',
      '阴阳',
      '从甲起阳阴相间：甲丙戊庚壬为阳，乙丁己辛癸为阴。',
    ),
    ganGroup(
      'tiangan_direction',
      '天干方位',
      'gan_direction',
      '方位',
      '甲乙东，丙丁南，戊己中，庚辛西，壬癸北。',
    ),
    ganGroup(
      'tiangan_season',
      '天干季节',
      'gan_season',
      '季节',
      '甲乙春，丙丁夏，戊己长夏，庚辛秋，壬癸冬。',
    ),
    ganGroup('tiangan_month', '天干月份', 'gan_month', '月份', '从甲到癸，依次对应正月到十月。'),
    ganGroup(
      'tiangan_time',
      '天干时辰',
      'gan_time',
      '时辰',
      '甲寅乙卯，丙巳丁午，戊辰己未，庚申辛酉，壬亥癸子。',
    ),
    zhiGroup(
      'dizhi_wuxing',
      '地支五行',
      'zhi_wuxing',
      '五行',
      '寅卯木，巳午火，申酉金，亥子水，辰戌丑未土。',
    ),
    zhiGroup(
      'dizhi_yinyang',
      '地支阴阳',
      'zhi_yinyang',
      '阴阳',
      '从子起阳阴相间：子寅辰午申戌为阳，丑卯巳未酉亥为阴。',
    ),
    zhiGroup(
      'dizhi_direction',
      '地支方位',
      'zhi_direction',
      '方位',
      '子北午南，卯东酉西；丑寅东北，辰巳东南，未申西南，戌亥西北。',
    ),
    zhiGroup(
      'dizhi_season',
      '地支季节',
      'zhi_season',
      '季节',
      '寅卯辰春，巳午未夏，申酉戌秋，亥子丑冬。',
    ),
    zhiGroup('dizhi_month', '地支月份', 'zhi_month', '月份', '寅为正月，卯为二月，依次数到丑为十二月。'),
    zhiGroup('dizhi_time', '地支时辰', 'zhi_time', '时辰', '一支一个时辰，子时、丑时、寅时……亥时。'),
    zhiGroup(
      'dizhi_hour',
      '地支钟点',
      'zhi_hour',
      '钟点',
      '子时是 23 点到 1 点，之后每个时辰两小时：丑 1-3，寅 3-5……亥 21-23。',
    ),
    byTypes(
      id: 'dizhi_finger_forward',
      title: '地支指诀',
      chapterId: 'dizhi',
      types: ['finger_forward'],
      tables: [_table(diZhi, '十二支指诀')],
      mnemonic:
          '寅在食指根部，沿食指上到指尖，横过中指、无名指指尖到小指，'
          '沿小指下到根部，再经无名指根、中指根回到寅。',
    ),
    byTypes(
      id: 'dizhi_finger_reverse',
      title: '指诀反查',
      chapterId: 'dizhi',
      types: ['finger_reverse'],
      tables: [
        _pick(_table(diZhi, '十二支指诀'), ['指节', '地支']),
      ],
      mnemonic: '从食指根部的寅起，顺着指节走一圈：寅卯辰巳午未申酉戌亥子丑。',
    ),
    relationGroup(
      'liuhe',
      '六合',
      ['zhi_liuhe'],
      ['六合'],
      '子丑合，寅亥合，卯戌合，辰酉合，巳申合，午未合。',
    ),
    relationGroup(
      'sanhe',
      '三合',
      ['zhi_sanhe'],
      ['三合'],
      '申子辰合水，亥卯未合木，寅午戌合火，巳酉丑合金。',
    ),
    relationGroup(
      'sanxing_zixing',
      '三刑与自刑',
      ['zhi_sanxing', 'zhi_zixing'],
      ['三刑', '自刑'],
      '寅巳申无恩之刑，丑戌未持势之刑，子卯无礼之刑；辰午酉亥自刑。',
    ),
    relationGroup(
      'liuchong',
      '六冲',
      ['zhi_liuchong'],
      ['六冲'],
      '子午冲，丑未冲，寅申冲，卯酉冲，辰戌冲，巳亥冲。',
    ),
    relationGroup(
      'liuhai',
      '六害',
      ['zhi_liuhai'],
      ['六害'],
      '子未害，丑午害，寅巳害，卯辰害，申亥害，酉戌害。',
    ),
    relationGroup(
      'poxiang',
      '相破',
      ['zhi_poxiang'],
      ['相破'],
      '子酉破，丑辰破，寅亥破，卯午破，巳申破，未戌破。',
    ),
    // 阶段卡的推算题也要用到长生起点，所以两张表一起看。
    byTypes(
      id: 'changsheng_stage',
      title: '十二长生阶段顺序',
      chapterId: 'changsheng',
      types: [KnowledgeCatalog.changShengStageType],
      tables: changSheng.tables,
      mnemonic:
          '长生、沐浴、冠带、临官、帝旺、衰、病、死、墓、绝、胎、养。'
          '从日支五行的长生起点按地支顺数到爻支。',
    ),
    byTypes(
      id: 'changsheng_start',
      title: '十二长生起点',
      chapterId: 'changsheng',
      types: [KnowledgeCatalog.changShengStartType],
      tables: [_table(changSheng, '长生起点')],
      mnemonic: '木长生在亥，火长生在寅，金长生在巳，水土长生在申。',
    ),
    byTypes(
      id: 'kongwang',
      title: '算空亡',
      chapterId: 'kongwang',
      types: [KnowledgeCatalog.kongWangType],
      tables: kongWang.tables,
      mnemonic:
          '从日干倒着数到甲，日支退同样的位数得到旬首，再往回数两位。'
          '甲子旬戌亥，甲戌旬申酉，甲申旬午未，甲午旬辰巳，甲辰旬寅卯，甲寅旬子丑。',
    ),
    ..._guaPalaceGroups(_table(gua, '卦名与卦象')),
    byTypes(
      id: 'shiying',
      title: '寻世应',
      chapterId: 'shiying',
      types: [KnowledgeCatalog.shiYingType],
      tables: shiYingAtlas().tables,
      mnemonic:
          '本宫在上爻，一世在初爻，二世在二爻，三世在三爻，四世在四爻，五世在五爻，'
          '游魂同四世，归魂同三世。应爻与世爻隔两位。',
    ),
    byTypes(
      id: 'liuqin',
      title: '寻六亲',
      chapterId: 'liuqin',
      types: [KnowledgeCatalog.liuQinType],
      tables: liuQinAtlas().tables,
      mnemonic: '以卦宫五行为我：生我父母，比和兄弟，我生子孙，我克妻财，克我官鬼。',
    ),
    byTypes(
      id: 'yongshen',
      title: '定用神',
      chapterId: 'yongshen',
      types: [KnowledgeCatalog.yongShenType],
      tables: yongShenAtlas().tables,
      mnemonic: '钱财、妻子取妻财，丈夫、官职、疾病取官鬼，父母、文书学业、房屋车船取父母，子女、医药取子孙，兄弟朋友取兄弟，测自己取世爻。',
    ),
    byTypes(
      id: 'wangxiang',
      title: '判断旺相',
      chapterId: 'wangxiang',
      types: [KnowledgeCatalog.wangXiangType],
      tables: wangXiangAtlas().tables,
      mnemonic: '以月令五行为我：同我为旺，我生为相，生我为休，克我为囚，我克为死。',
    ),
  ];

  final ids = <String>{};
  for (final group in groups) {
    if (!ids.add(group.id)) {
      throw StateError('重复小组: ${group.id}');
    }
    if (group.itemKeys.isEmpty) {
      throw StateError('小组没有知识点: ${group.id}');
    }
  }
  return groups;
}

/// 八宫顺序与 [guaMap] 一致，每宫 8 卦，宫首是八纯卦。
List<StudyGroup> _guaPalaceGroups(AtlasTable source) {
  const palaces = [
    ('qian', '乾'),
    ('kun', '坤'),
    ('zhen', '震'),
    ('xun', '巽'),
    ('kan', '坎'),
    ('li', '离'),
    ('gen', '艮'),
    ('dui', '兑'),
  ];
  final names = getAllGuaNames();
  if (names.length != palaces.length * 8) {
    throw StateError('六十四卦数量不对: ${names.length}');
  }
  return [
    for (var i = 0; i < palaces.length; i++)
      _guaPalace(
        id: 'gua_${palaces[i].$1}',
        palace: palaces[i].$2,
        names: names.sublist(i * 8, i * 8 + 8),
        source: source,
      ),
  ];
}

StudyGroup _guaPalace({
  required String id,
  required String palace,
  required List<String> names,
  required AtlasTable source,
}) {
  if (names.first != palace) {
    throw StateError('$palace宫的宫首不对: ${names.first}');
  }
  final wanted = names.toSet();
  final xiangs = {for (final name in names) getGuaXiang(name)!};
  return StudyGroup(
    id: id,
    title: '$palace宫八卦',
    chapterId: 'gua64',
    itemKeys: [
      for (final item in KnowledgeCatalog.itemsForTypes([
        'gua_to_xiang',
        'xiang_to_gua',
      ]))
        if ((item.questionType == 'gua_to_xiang' &&
                wanted.contains(item.input)) ||
            (item.questionType == 'xiang_to_gua' &&
                xiangs.contains(item.input)))
          item.itemKey,
    ],
    tables: [
      AtlasTable(
        title: '$palace宫八卦',
        columns: source.columns,
        rows: [
          for (final row in source.rows)
            if (wanted.contains(row.first)) row,
        ],
      ),
    ],
    mnemonic: '$palace宫八卦：${names.join('、')}。卦象前一个字是上卦，后一个字是下卦。',
  );
}

AtlasTable _table(AtlasChapter chapter, String title) {
  return chapter.tables.firstWhere(
    (table) => table.title == title,
    orElse: () => throw StateError('${chapter.title}没有表 $title'),
  );
}

/// 只留下指定的列，按给定顺序排列。
AtlasTable _pick(AtlasTable source, List<String> columns) {
  final indexes = [
    for (final column in columns) source.columns.indexOf(column),
  ];
  if (indexes.contains(-1)) {
    throw StateError('${source.title}缺少列 $columns');
  }
  return AtlasTable(
    title: source.title,
    columns: columns,
    rows: [
      for (final row in source.rows) [for (final i in indexes) row[i]],
    ],
  );
}
