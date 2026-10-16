import 'dart:math';

import 'package:flutter/material.dart';

import '../models/question.dart';
import '../services/rule_functions.dart';
import 'di_zhi.dart';
import 'gua_data.dart';
import 'tian_gan.dart';
import 'wu_xing.dart';
import 'zhi_relations.dart';

/// 首轮怎么从模块的知识点里抽题。
enum FirstRoundKind {
  /// 每个知识点一题，顺序打乱。
  eachItem,

  /// 六十四卦：每个卦一题，卦名→卦象与卦象→卦名交错。
  guaAlternating,

  /// 十二长生：按日支和阶段配对覆盖，不是 12×12 全组合。
  changshengCoverage,

  /// 综合练习：混合抽题，同一轮不重复知识点。
  mixed,
}

/// 一条知识点。键是 `questionType:input`，与 [Question.itemKey] 相同。
class KnowledgeItem {
  final String questionType;
  final String input;
  final String correctAnswer;
  final String text;

  /// 同类错误选项池，不含正确答案。出题时最多抽 3 个。
  final List<String> distractors;

  const KnowledgeItem({
    required this.questionType,
    required this.input,
    required this.correctAnswer,
    required this.text,
    required this.distractors,
  });

  String get itemKey => '$questionType:$input';
}

/// 学习模块。id 与已存进度一致，不能改名。
class StudyModule {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> questionTypes;
  final FirstRoundKind firstRound;
  final int? partSize;
  final List<String> sourceModuleIds;

  const StudyModule({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.questionTypes,
    required this.firstRound,
    this.partSize,
    this.sourceModuleIds = const [],
  });
}

/// 知识点目录。
///
/// 正确答案只由 questionType 和 input 决定。每次出题从干扰项池另抽至多 3 个
/// 错误选项，再打乱顺序。池子不足 3 个时（阴阳只有两个选项）不补假选项。
class KnowledgeCatalog {
  KnowledgeCatalog._();

  static const Map<String, String> questionTypeLabels = {
    'gan_wuxing': '天干五行',
    'zhi_wuxing': '地支五行',
    'gan_yinyang': '天干阴阳',
    'zhi_yinyang': '地支阴阳',
    'gan_direction': '天干方位',
    'zhi_direction': '地支方位',
    'gan_season': '天干季节',
    'zhi_season': '地支季节',
    'gan_month': '天干月份',
    'zhi_month': '地支月份',
    'gan_time': '天干时辰',
    'zhi_time': '地支时辰',
    'zhi_hour': '地支时辰钟点',
    'zhi_liuhe': '六合',
    'zhi_sanhe': '三合',
    'zhi_sanxing': '三刑',
    'zhi_zixing': '自刑',
    'zhi_liuchong': '六冲',
    'zhi_liuhai': '六害',
    'zhi_poxiang': '相破',
    'finger_forward': '地支指诀',
    'finger_reverse': '指诀反查',
    'wuxing_sheng': '五行相生',
    'wuxing_ke': '五行相克',
    'changsheng': '十二长生',
    'gua_to_xiang': '六十四卦',
    'xiang_to_gua': '六十四卦',
  };

  static final List<KnowledgeItem> items = _buildItems();

  static final Map<String, KnowledgeItem> _byKey = {
    for (final item in items) item.itemKey: item,
  };

  static final List<StudyModule> modules = _buildModules();

  static String questionTypeLabel(String questionType) {
    return questionTypeLabels[questionType] ?? questionType;
  }

  static KnowledgeItem? find(String questionType, String input) {
    return _byKey['$questionType:$input'];
  }

  static StudyModule? module(String id) {
    for (final item in modules) {
      if (item.id == id) return item;
    }
    return null;
  }

  static List<StudyModule> modulesByIds(List<String> ids) {
    return [for (final id in ids) module(id)!];
  }

  static List<KnowledgeItem> itemsForTypes(List<String> types) {
    final wanted = types.toSet();
    return items.where((item) => wanted.contains(item.questionType)).toList();
  }

  /// 模块里的知识点，保持目录顺序。综合练习展开来源模块并去重。
  static List<KnowledgeItem> itemsForModule(String moduleId) {
    return _itemsForModule(moduleId, <String>{});
  }

  static List<KnowledgeItem> _itemsForModule(
    String moduleId,
    Set<String> visiting,
  ) {
    final found = module(moduleId);
    if (found == null || !visiting.add(moduleId)) return const [];
    if (found.sourceModuleIds.isNotEmpty) {
      final seen = <String>{};
      final result = <KnowledgeItem>[];
      for (final sourceId in found.sourceModuleIds) {
        for (final item in _itemsForModule(sourceId, visiting)) {
          if (seen.add(item.itemKey)) result.add(item);
        }
      }
      visiting.remove(moduleId);
      return result;
    }
    visiting.remove(moduleId);
    return itemsForTypes(found.questionTypes);
  }

  static String randomInput(String questionType, Random random) {
    final pool = itemsForTypes([questionType]);
    if (pool.isEmpty) {
      throw Exception('Unknown question type: $questionType');
    }
    return pool[random.nextInt(pool.length)].input;
  }

  /// 给定题型和输入，正确答案与 itemKey 固定；错误选项和顺序随 [random] 变化。
  static Question generateQuestion(
    String questionType,
    String input, {
    Random? random,
  }) {
    final item = find(questionType, input);
    if (item == null) {
      throw Exception('Unknown question: $questionType:$input');
    }
    final rng = random ?? Random();
    final pool = List<String>.of(item.distractors)..shuffle(rng);
    final wrong = <String>[];
    final seen = <String>{item.correctAnswer};
    for (final candidate in pool) {
      if (!seen.add(candidate)) continue;
      wrong.add(candidate);
      if (wrong.length == 3) break;
    }
    final options = <String>[item.correctAnswer, ...wrong]..shuffle(rng);
    return Question(
      text: item.text,
      options: options,
      correctAnswer: item.correctAnswer,
      questionType: item.questionType,
      input: item.input,
    );
  }

  static Question randomQuestionOfType(String questionType, Random random) {
    return generateQuestion(
      questionType,
      randomInput(questionType, random),
      random: random,
    );
  }

  /// 在模块登记的题型里等概率抽一种，再抽一条知识点。
  /// 综合练习先等概率选一个来源模块。
  static Question randomQuestionForModule(String moduleId, Random random) {
    final found = module(moduleId);
    if (found == null) {
      return randomQuestionOfType('gan_wuxing', random);
    }
    if (found.sourceModuleIds.isNotEmpty) {
      final source =
          found.sourceModuleIds[random.nextInt(found.sourceModuleIds.length)];
      return randomQuestionForModule(source, random);
    }
    if (found.questionTypes.isEmpty) {
      return randomQuestionOfType('gan_wuxing', random);
    }
    final type =
        found.questionTypes[random.nextInt(found.questionTypes.length)];
    return randomQuestionOfType(type, random);
  }
}

List<KnowledgeItem> _buildItems() {
  final built = <KnowledgeItem>[];
  final seen = <String>{};

  void add(KnowledgeItem item) {
    if (!seen.add(item.itemKey)) {
      throw StateError('重复知识点: ${item.itemKey}');
    }
    if (item.correctAnswer.isEmpty || item.correctAnswer == '未知') {
      throw StateError('知识点缺少正确答案: ${item.itemKey}');
    }
    if (item.distractors.isEmpty ||
        item.distractors.contains(item.correctAnswer)) {
      throw StateError('干扰项池不合法: ${item.itemKey}');
    }
    built.add(item);
  }

  final ganNames = tianGan.map((item) => item['name']!).toList();
  final zhiNames = diZhi.map((item) => item['name']!).toList();
  final wuXingNames = wuXingSheng.keys.toList();
  const yinYang = ['阳', '阴'];
  final directions = [
    ..._fieldValues(tianGan, 'direction'),
    ..._fieldValues(diZhi, 'direction'),
  ];
  final seasons = [
    ..._fieldValues(tianGan, 'season'),
    ..._fieldValues(diZhi, 'season'),
  ];
  final months = [
    ..._fieldValues(tianGan, 'month'),
    ..._fieldValues(diZhi, 'month'),
  ];
  final shiChen = _fieldValues(diZhi, 'time');
  final hours = _fieldValues(diZhi, 'hour');
  final joints = _fieldValues(diZhi, 'fingerJoint');

  void addNamed({
    required String type,
    required List<String> names,
    required String Function(String name) answerOf,
    required String Function(String name) textOf,
    required List<String> pool,
  }) {
    for (final name in names) {
      final correct = answerOf(name);
      add(
        KnowledgeItem(
          questionType: type,
          input: name,
          correctAnswer: correct,
          text: textOf(name),
          distractors: _without(pool, correct),
        ),
      );
    }
  }

  addNamed(
    type: 'gan_wuxing',
    names: ganNames,
    answerOf: getGanWuXing,
    textOf: (name) => '$name 属于什么五行？',
    pool: wuXingNames,
  );
  addNamed(
    type: 'zhi_wuxing',
    names: zhiNames,
    answerOf: getZhiWuXing,
    textOf: (name) => '$name 属于什么五行？',
    pool: wuXingNames,
  );
  addNamed(
    type: 'gan_yinyang',
    names: ganNames,
    answerOf: getGanYinYang,
    textOf: (name) => '$name 属于阴还是阳？',
    pool: yinYang,
  );
  addNamed(
    type: 'zhi_yinyang',
    names: zhiNames,
    answerOf: getZhiYinYang,
    textOf: (name) => '$name 属于阴还是阳？',
    pool: yinYang,
  );
  addNamed(
    type: 'gan_direction',
    names: ganNames,
    answerOf: getGanDirection,
    textOf: (name) => '$name 对应的方位是？',
    pool: directions,
  );
  addNamed(
    type: 'zhi_direction',
    names: zhiNames,
    answerOf: getZhiDirection,
    textOf: (name) => '$name 对应的方位是？',
    pool: directions,
  );
  addNamed(
    type: 'gan_season',
    names: ganNames,
    answerOf: getGanSeason,
    textOf: (name) => '$name 对应的季节是？',
    pool: seasons,
  );
  addNamed(
    type: 'zhi_season',
    names: zhiNames,
    answerOf: getZhiSeason,
    textOf: (name) => '$name 对应的季节是？',
    pool: seasons,
  );
  addNamed(
    type: 'gan_month',
    names: ganNames,
    answerOf: getGanMonth,
    textOf: (name) => '$name 对应的月份是？',
    pool: months,
  );
  addNamed(
    type: 'zhi_month',
    names: zhiNames,
    answerOf: getZhiMonth,
    textOf: (name) => '$name 对应的月份是？',
    pool: months,
  );
  addNamed(
    type: 'gan_time',
    names: ganNames,
    answerOf: getGanTime,
    textOf: (name) => '$name 对应的时辰是？',
    pool: shiChen,
  );
  addNamed(
    type: 'zhi_time',
    names: zhiNames,
    answerOf: getZhiTime,
    textOf: (name) => '$name 对应的时辰是？',
    pool: shiChen,
  );
  addNamed(
    type: 'zhi_hour',
    names: zhiNames,
    answerOf: getZhiHour,
    textOf: (name) => '$name 对应的时间段是？',
    pool: hours,
  );

  for (final zhi in zhiNames) {
    final correct = getLiuHe(zhi);
    add(
      KnowledgeItem(
        questionType: 'zhi_liuhe',
        input: zhi,
        correctAnswer: correct,
        text: '谁和$zhi 六合？',
        distractors: _without(zhiNames, correct),
      ),
    );
  }

  final sanHePool = _fakeTriples({
    for (final group in sanHe) _canonical(group),
  });
  for (final group in sanHe) {
    add(
      KnowledgeItem(
        questionType: 'zhi_sanhe',
        input: group.join(),
        correctAnswer: group.join(' '),
        text: '以下哪个是三合组合？',
        distractors: sanHePool,
      ),
    );
  }

  final sanXingPool = _fakeTriples({
    for (final group in sanXing) _canonical(group),
  });
  for (final group in sanXing) {
    add(
      KnowledgeItem(
        questionType: 'zhi_sanxing',
        input: group.join(),
        correctAnswer: group.join(' '),
        text: '以下哪个是三刑组合？',
        distractors: sanXingPool,
      ),
    );
  }

  final nonZiXing = zhiNames.where((zhi) => !ziXing.containsKey(zhi)).toList();
  for (final zhi in ziXing.keys) {
    add(
      KnowledgeItem(
        questionType: 'zhi_zixing',
        input: zhi,
        correctAnswer: zhi,
        text: '以下哪个地支有自刑？',
        distractors: nonZiXing,
      ),
    );
  }

  for (final zhi in diZhiCycle) {
    final chong = liuChongOf(zhi);
    add(
      KnowledgeItem(
        questionType: 'zhi_liuchong',
        input: zhi,
        correctAnswer: chong,
        text: '谁和$zhi 六冲？',
        distractors: _without(zhiNames, chong),
      ),
    );
    final hai = liuHai[zhi]!;
    add(
      KnowledgeItem(
        questionType: 'zhi_liuhai',
        input: zhi,
        correctAnswer: hai,
        text: '谁和$zhi 六害？',
        distractors: _without(zhiNames, hai),
      ),
    );
    final po = poXiang[zhi]!;
    add(
      KnowledgeItem(
        questionType: 'zhi_poxiang',
        input: zhi,
        correctAnswer: po,
        text: '谁和$zhi 相破？',
        distractors: _without(zhiNames, po),
      ),
    );
  }

  for (final row in diZhi) {
    final name = row['name']!;
    final joint = row['fingerJoint']!;
    add(
      KnowledgeItem(
        questionType: 'finger_forward',
        input: name,
        correctAnswer: joint,
        text: '$name 对应的指节是？',
        distractors: _without(joints, joint),
      ),
    );
    add(
      KnowledgeItem(
        questionType: 'finger_reverse',
        input: joint,
        correctAnswer: name,
        text: '$joint 对应的地支是？',
        distractors: _without(zhiNames, name),
      ),
    );
  }

  for (final name in wuXingNames) {
    final sheng = getWuXingSheng(name);
    add(
      KnowledgeItem(
        questionType: 'wuxing_sheng',
        input: name,
        correctAnswer: sheng,
        text: '五行 $name 所生的是什么五行？',
        distractors: _without(wuXingNames, sheng),
      ),
    );
    final ke = getWuXingKe(name);
    add(
      KnowledgeItem(
        questionType: 'wuxing_ke',
        input: name,
        correctAnswer: ke,
        text: '五行 $name 所克的是什么五行？',
        distractors: _without(wuXingNames, ke),
      ),
    );
  }

  for (final riZhi in diZhiCycle) {
    for (final yaoZhi in diZhiCycle) {
      final correct = getWuXingChangSheng(riZhi, yaoZhi);
      add(
        KnowledgeItem(
          questionType: 'changsheng',
          input: '${riZhi}_$yaoZhi',
          correctAnswer: correct,
          text: '若日支为『$riZhi』，某爻地支为『$yaoZhi』，此爻处于十二长生的哪一阶段？',
          distractors: _without(changShengCycle, correct),
        ),
      );
    }
  }

  final guaNames = getAllGuaNames();
  final guaXiangs = getAllGuaXiang();
  for (final name in guaNames) {
    final xiang = getGuaXiang(name)!;
    add(
      KnowledgeItem(
        questionType: 'gua_to_xiang',
        input: name,
        correctAnswer: xiang,
        text: '卦「$name」的卦象是哪个？',
        distractors: _without(guaXiangs, xiang),
      ),
    );
    add(
      KnowledgeItem(
        questionType: 'xiang_to_gua',
        input: xiang,
        correctAnswer: name,
        text: '卦象「$xiang」对应的卦名是哪个？',
        distractors: _without(guaNames, name),
      ),
    );
  }

  return built;
}

List<StudyModule> _buildModules() {
  const modules = <StudyModule>[
    StudyModule(
      id: 'tiangandizhi_wuxing',
      name: '天干地支五行',
      subtitle: '学习天干地支的五行属性',
      icon: Icons.eco,
      color: Colors.green,
      questionTypes: ['gan_wuxing', 'zhi_wuxing'],
      firstRound: FirstRoundKind.eachItem,
    ),
    StudyModule(
      id: 'tiangandizhi_yinyang',
      name: '天干地支阴阳',
      subtitle: '掌握天干地支的阴阳属性',
      icon: Icons.brightness_6,
      color: Colors.orange,
      questionTypes: ['gan_yinyang', 'zhi_yinyang'],
      firstRound: FirstRoundKind.eachItem,
    ),
    StudyModule(
      id: 'tiangandizhi_direction',
      name: '方位对应',
      subtitle: '方位、季节与月份',
      icon: Icons.explore,
      color: Colors.blue,
      questionTypes: [
        'gan_direction',
        'zhi_direction',
        'gan_season',
        'zhi_season',
        'gan_month',
        'zhi_month',
      ],
      firstRound: FirstRoundKind.eachItem,
    ),
    StudyModule(
      id: 'tiangandizhi_time',
      name: '时间对应',
      subtitle: '时辰与时间段',
      icon: Icons.schedule,
      color: Colors.purple,
      questionTypes: ['gan_time', 'zhi_time', 'zhi_hour'],
      firstRound: FirstRoundKind.eachItem,
    ),
    StudyModule(
      id: 'tiangandizhi_shengke',
      name: '五行生克',
      subtitle: '学习五行之间的生克关系',
      icon: Icons.sync_alt,
      color: Colors.lightGreen,
      questionTypes: ['wuxing_sheng', 'wuxing_ke'],
      firstRound: FirstRoundKind.eachItem,
    ),
    StudyModule(
      id: 'tiangandizhi_comprehensive',
      name: '天干地支综合练习',
      subtitle: '综合练习天干地支五行、阴阳、方位、时间、生克关系',
      icon: Icons.quiz,
      color: Colors.cyan,
      questionTypes: [
        'gan_wuxing',
        'zhi_wuxing',
        'gan_yinyang',
        'zhi_yinyang',
        'gan_direction',
        'zhi_direction',
        'gan_season',
        'zhi_season',
        'gan_month',
        'zhi_month',
        'gan_time',
        'zhi_time',
        'zhi_hour',
        'wuxing_sheng',
        'wuxing_ke',
      ],
      firstRound: FirstRoundKind.mixed,
    ),
    StudyModule(
      id: 'wuxing',
      name: '十二支指诀',
      subtitle: '地支对应手指关节的快速记忆法',
      icon: Icons.psychology,
      color: Colors.teal,
      questionTypes: ['finger_forward', 'finger_reverse'],
      firstRound: FirstRoundKind.eachItem,
    ),
    // 六冲、六害、相破可以按键出题，但不进首轮，避免改掉现有覆盖维度。
    StudyModule(
      id: 'hechong',
      name: '六合三合六冲',
      subtitle: '判断人事关系、事情走向的规则',
      icon: Icons.compare_arrows,
      color: Colors.indigo,
      questionTypes: ['zhi_liuhe', 'zhi_sanhe', 'zhi_sanxing', 'zhi_zixing'],
      firstRound: FirstRoundKind.eachItem,
    ),
    StudyModule(
      id: 'shierchangsheng',
      name: '十二长生',
      subtitle: '用来判断某个爻（事物）的旺衰强弱',
      icon: Icons.timeline,
      color: Colors.deepOrange,
      questionTypes: ['changsheng'],
      firstRound: FirstRoundKind.changshengCoverage,
    ),
    StudyModule(
      id: '64gua',
      name: '六十四卦',
      subtitle: '速记六十四卦卦象',
      icon: Icons.grain,
      color: Colors.brown,
      questionTypes: ['gua_to_xiang', 'xiang_to_gua'],
      firstRound: FirstRoundKind.guaAlternating,
      partSize: 16,
    ),
    StudyModule(
      id: 'comprehensive',
      name: '综合练习',
      subtitle: '混合各种题型，全面复习',
      icon: Icons.quiz,
      color: Colors.blueGrey,
      questionTypes: [],
      firstRound: FirstRoundKind.mixed,
      sourceModuleIds: [
        'tiangandizhi_comprehensive',
        'wuxing',
        'hechong',
        'shierchangsheng',
        '64gua',
      ],
    ),
  ];

  final ids = <String>{};
  for (final module in modules) {
    if (!ids.add(module.id)) {
      throw StateError('重复模块: ${module.id}');
    }
    for (final type in module.questionTypes) {
      if (!KnowledgeCatalog.items.any((item) => item.questionType == type)) {
        throw StateError('${module.id} 引用了没有知识点的题型 $type');
      }
    }
    for (final source in module.sourceModuleIds) {
      if (!modules.any((item) => item.id == source)) {
        throw StateError('${module.id} 引用了不存在的来源模块 $source');
      }
    }
  }
  return modules;
}

List<String> _fieldValues(List<Map<String, String>> rows, String field) {
  final seen = <String>{};
  final result = <String>[];
  for (final row in rows) {
    final value = row[field];
    if (value == null || value.isEmpty || !seen.add(value)) continue;
    result.add(value);
  }
  return result;
}

List<String> _without(Iterable<String> pool, String correct) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in pool) {
    if (value.isEmpty || value == correct || !seen.add(value)) continue;
    result.add(value);
  }
  return result;
}

String _canonical(List<String> group) {
  final copy = List<String>.from(group)
    ..sort((a, b) => diZhiCycle.indexOf(a).compareTo(diZhiCycle.indexOf(b)));
  return copy.join();
}

/// 三个地支的组合，排除真正的三合/三刑，避免干扰项里出现另一个正确答案。
List<String> _fakeTriples(Set<String> excludedCanonical) {
  final names = diZhiCycle;
  final pool = <String>[];
  for (var i = 0; i < names.length; i++) {
    for (var j = i + 1; j < names.length; j++) {
      for (var k = j + 1; k < names.length; k++) {
        final group = [names[i], names[j], names[k]];
        if (excludedCanonical.contains(group.join())) continue;
        pool.add(group.join(' '));
      }
    }
  }
  return pool;
}
