import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/data/gua_data.dart';
import 'package:liuyao/data/knowledge_catalog.dart';
import 'package:liuyao/data/kong_wang.dart';
import 'package:liuyao/data/liu_qin.dart';
import 'package:liuyao/data/shi_ying.dart';
import 'package:liuyao/data/wang_xiang.dart';
import 'package:liuyao/data/yong_shen.dart';
import 'package:liuyao/data/teaching_notes.dart';
import 'package:liuyao/data/zhi_relations.dart';
import 'package:liuyao/models/question.dart';
import 'package:liuyao/models/wrong_question_record.dart';
import 'package:liuyao/services/question_reconstructor.dart';
import 'package:liuyao/services/questions.dart';
import 'package:liuyao/services/rule_functions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Set<String> wrongOf(Question question) {
    return question.options.toSet().difference({question.correctAnswer});
  }

  test('目录覆盖重建器里的题型，键不重复', () {
    const types = [
      'gan_wuxing',
      'gan_yinyang',
      'gan_direction',
      'gan_season',
      'gan_month',
      'gan_time',
      'zhi_wuxing',
      'zhi_yinyang',
      'zhi_direction',
      'zhi_season',
      'zhi_month',
      'zhi_time',
      'zhi_hour',
      'zhi_liuhe',
      'zhi_sanhe',
      'zhi_sanxing',
      'zhi_zixing',
      'zhi_liuchong',
      'zhi_liuhai',
      'zhi_poxiang',
      'finger_forward',
      'finger_reverse',
      'wuxing_sheng',
      'wuxing_ke',
      'changsheng_stage',
      'changsheng_start',
      'kongwang',
      'gua_to_xiang',
      'xiang_to_gua',
      'shiying',
      'liuqin',
      'yongshen',
      'wangxiang',
    ];
    final actual = KnowledgeCatalog.items
        .map((item) => item.questionType)
        .toSet();
    expect(actual, types.toSet());
    expect(
      KnowledgeCatalog.items.map((item) => item.itemKey).toSet(),
      hasLength(KnowledgeCatalog.items.length),
    );
  });

  test('同一知识点多次生成时正确答案和键不变，选项含正确答案且不重复', () {
    for (final item in KnowledgeCatalog.items) {
      if (KnowledgeCatalog.isChangShengRule(item.questionType)) continue;
      final first = KnowledgeCatalog.generateQuestion(
        item.questionType,
        item.input,
        random: Random(1),
      );
      final second = KnowledgeCatalog.generateQuestion(
        item.questionType,
        item.input,
        random: Random(2),
      );
      expect(first.correctAnswer, item.correctAnswer, reason: item.itemKey);
      expect(second.correctAnswer, item.correctAnswer, reason: item.itemKey);
      expect(first.itemKey, item.itemKey);
      expect(second.itemKey, item.itemKey);
      for (final question in [first, second]) {
        expect(question.options, contains(question.correctAnswer));
        expect(question.options.toSet(), hasLength(question.options.length));
        final wrongCount = item.distractors.length >= 3
            ? 3
            : item.distractors.length;
        expect(
          question.options,
          hasLength(wrongCount + 1),
          reason: item.itemKey,
        );
      }
    }
  });

  test('六十四卦「讼」的卦象固定，错误选项随种子变化', () {
    final first = KnowledgeCatalog.generateQuestion(
      'gua_to_xiang',
      '讼',
      random: Random(1),
    );
    final second = KnowledgeCatalog.generateQuestion(
      'gua_to_xiang',
      '讼',
      random: Random(2),
    );
    expect(first.correctAnswer, '天水');
    expect(second.correctAnswer, first.correctAnswer);
    expect(first.itemKey, 'gua_to_xiang:讼');
    expect(second.itemKey, first.itemKey);
    expect(first.options, contains('天水'));
    expect(wrongOf(first), isNot(wrongOf(second)));
  });

  test('阴阳只有两个选项，时辰和钟点分开', () {
    final yinYang = KnowledgeCatalog.generateQuestion(
      'gan_yinyang',
      '甲',
      random: Random(1),
    );
    expect(yinYang.options.toSet(), {'阳', '阴'});
    expect(yinYang.correctAnswer, '阳');

    final shiChen = KnowledgeCatalog.generateQuestion('zhi_time', '子');
    expect(shiChen.correctAnswer, '子时');
    expect(shiChen.itemKey, 'zhi_time:子');

    final hour = KnowledgeCatalog.generateQuestion('zhi_hour', '子');
    expect(hour.correctAnswer, '23-1');
    expect(hour.itemKey, 'zhi_hour:子');

    final ganTime = Questions.generateGanTimeQuestion(gan: '甲');
    expect(ganTime.correctAnswer, '寅时');
    expect(ganTime.itemKey, 'gan_time:甲');
  });

  test('十二长生只有 17 张规则卡：12 个阶段和 5 个五行起点', () {
    final stages = KnowledgeCatalog.itemsForTypes(['changsheng_stage']);
    final starts = KnowledgeCatalog.itemsForTypes(['changsheng_start']);
    expect(
      stages.map((item) => item.input).join(' '),
      '长生 沐浴 冠带 临官 帝旺 衰 病 死 墓 绝 胎 养',
    );
    expect(
      {for (final item in starts) item.input: item.correctAnswer},
      {'木': '亥', '火': '寅', '金': '巳', '水': '申', '土': '申'},
    );
    expect(
      KnowledgeCatalog.itemsForModule('shierchangsheng').map((e) => e.itemKey),
      [...stages, ...starts].map((e) => e.itemKey),
    );
    expect(KnowledgeCatalog.find('changsheng', '午_酉'), isNull);
  });

  test('午日酉爻：午属火，火长生在寅，从寅顺数到酉是死', () {
    final question = KnowledgeCatalog.changShengQuestion(
      riZhi: '午',
      yaoZhi: '酉',
      ruleType: 'changsheng_start',
      random: Random(1),
    );
    expect(question.text, '日支午、爻支酉，处于十二长生的哪个阶段？');
    expect(question.correctAnswer, '死');
    expect(question.itemKey, 'changsheng_start:火');
    expect(question.context, {'riZhi': '午', 'yaoZhi': '酉'});
    expect(question.options, hasLength(4));
    expect(question.options, contains('死'));

    final byStage = KnowledgeCatalog.changShengQuestion(
      riZhi: '午',
      yaoZhi: '酉',
      ruleType: 'changsheng_stage',
    );
    expect(byStage.itemKey, 'changsheng_stage:死');

    expect(TeachingNotes.changShengSteps('午', '酉'), [
      '日支午属火',
      '火长生在寅',
      '从寅顺数到酉：寅长生、卯沐浴、辰冠带、巳临官、午帝旺、未衰、申病、酉死',
      '死',
    ]);
    final note = TeachingNotes.forQuestion(question)!;
    expect(note.hint, startsWith('日支午属火 → 火长生在寅 → 从寅顺数到酉'));
    expect(note.hint, endsWith('→ 死'));

    // 土随水，长生在申。
    expect(KnowledgeCatalog.legacyChangShengRules('辰_申'), (
      startKey: 'changsheng_start:土',
      stageKey: 'changsheng_stage:长生',
    ));
    expect(KnowledgeCatalog.legacyChangShengRules('午'), isNull);
  });

  test('戊戌日在甲午旬，空亡是辰巳，四个选项都是旬空对', () {
    final question = KnowledgeCatalog.kongWangQuestion(
      xun: '甲午',
      riZhu: '戊戌',
      random: Random(1),
    );
    expect(question.text, '戊戌日，空亡的地支是？');
    expect(question.correctAnswer, '辰巳');
    expect(question.itemKey, 'kongwang:甲午');
    expect(question.context, {'riGan': '戊', 'riZhi': '戌'});
    expect(question.options, hasLength(4));
    expect(question.options.toSet(), hasLength(4));
    expect(kongWangPairs().toSet(), containsAll(question.options));

    expect(kongWangSteps('戊', '戌'), [
      '从戊倒着数到甲：戊、丁、丙、乙、甲，退4位',
      '从戌退4位：戌、酉、申、未、午，旬首是甲午',
      '从午往回数两位：午、巳、辰，空亡辰巳',
    ]);
    final note = TeachingNotes.forQuestion(question)!;
    expect(note.fact, '戊戌日空辰巳');
    expect(note.hint, endsWith('空亡辰巳'));

    expect(kongWangOf('甲', '子'), '戌亥');
    expect(kongWangOf('甲', '丑'), isNull);
    expect(xunHeadBranches, ['子', '戌', '申', '午', '辰', '寅']);
    expect(kongWangPairs(), ['戌亥', '申酉', '午未', '辰巳', '寅卯', '子丑']);

    final days = [for (final head in xunHeadBranches) ...daysInXun('甲$head')];
    expect(days, hasLength(60));
    expect(days.map((day) => day.text).toSet(), hasLength(60));
    for (final head in xunHeadBranches) {
      final pair = kongWangOf('甲', head);
      for (final day in daysInXun('甲$head')) {
        expect(kongWangOf(day.gan, day.zhi), pair, reason: day.text);
      }
    }

    for (var seed = 0; seed < 20; seed++) {
      final drawn = KnowledgeCatalog.generateQuestion(
        'kongwang',
        '甲午',
        random: Random(seed),
      );
      final again = KnowledgeCatalog.generateQuestion(
        'kongwang',
        '甲午',
        random: Random(seed),
      );
      expect(again.text, drawn.text);
      expect(again.options, drawn.options);
      expect(drawn.itemKey, 'kongwang:甲午');
      expect(drawn.correctAnswer, '辰巳');
      expect(drawn.options, hasLength(4));
      final riZhu = drawn.text.substring(0, 2);
      expect(daysInXun('甲午').map((day) => day.text), contains(riZhu));
    }
  });

  test('天风姤是乾宫一世，世在初爻、应在四爻', () {
    final question = KnowledgeCatalog.shiYingQuestion(
      shiCi: '一世',
      guaName: '姤',
      random: Random(1),
    );
    expect(question.text, '天风姤，世爻和应爻在哪？');
    expect(question.correctAnswer, '世初爻，应四爻');
    expect(question.itemKey, 'shiying:一世');
    expect(question.context, {'gua': '姤'});
    expect(question.options, hasLength(4));
    expect(question.options.toSet(), hasLength(4));
    expect(shiYingPairs().toSet(), containsAll(question.options));

    expect(shiYingSteps('姤'), [
      '天风姤是乾宫一世卦',
      '乾宫依次是乾、姤、遁、否、观、剥、晋、大有，姤排第2位',
      '一世卦世在初爻，应在四爻',
      '世初爻，应四爻',
    ]);
    final note = TeachingNotes.forQuestion(question)!;
    expect(note.fact, '天风姤，世初爻，应四爻');
    expect(note.hint, endsWith('世初爻，应四爻'));

    expect(shiYingOf('乾'), '世上爻，应三爻');
    expect(shiYingOf('晋'), '世四爻，应初爻');
    expect(shiYingOf('大有'), '世三爻，应上爻');
    expect(shiYingOf('归妹'), '世三爻，应上爻');
    expect(shiYingPairs(), [
      '世上爻，应三爻',
      '世初爻，应四爻',
      '世二爻，应五爻',
      '世三爻，应上爻',
      '世四爻，应初爻',
      '世五爻，应二爻',
    ]);

    final names = <String>{};
    for (final ci in shiCiNames) {
      final guas = guasInGeneration(ci);
      expect(guas, hasLength(8), reason: ci);
      for (final name in guas) {
        expect(names.add(name), isTrue, reason: name);
        expect(shiYingOf(name), shiYingAnswerFor(shiCiNames.indexOf(ci)));
      }
    }
    expect(names, hasLength(64));

    for (var seed = 0; seed < 20; seed++) {
      final drawn = KnowledgeCatalog.generateQuestion(
        'shiying',
        '游魂',
        random: Random(seed),
      );
      final again = KnowledgeCatalog.generateQuestion(
        'shiying',
        '游魂',
        random: Random(seed),
      );
      expect(again.text, drawn.text);
      expect(again.options, drawn.options);
      expect(drawn.itemKey, 'shiying:游魂');
      expect(drawn.correctAnswer, '世四爻，应初爻');
      expect(drawn.options, hasLength(4));
      expect(
        guasInGeneration('游魂').map(guaTitle),
        contains(drawn.text.split('，').first),
      );
    }
  });

  test('天风姤爻支寅是妻财，寅月午爻为相，测丈夫取官鬼', () {
    final liuQin = KnowledgeCatalog.liuQinQuestion(
      liuQin: '妻财',
      guaName: '姤',
      yaoZhi: '寅',
      random: Random(1),
    );
    expect(liuQin.text, '天风姤，爻支寅，此爻是什么六亲？');
    expect(liuQin.correctAnswer, '妻财');
    expect(liuQin.itemKey, 'liuqin:妻财');
    expect(liuQin.options, hasLength(4));
    expect(liuQinSteps('姤', '寅'), ['天风姤属乾宫，宫五行金', '爻支寅属木', '金克木，我克者为妻财', '妻财']);
    final liuQinNote = TeachingNotes.forQuestion(liuQin)!;
    expect(liuQinNote.fact, contains('妻财'));
    expect(liuQinNote.hint, endsWith('妻财'));

    final wang = KnowledgeCatalog.wangXiangQuestion(
      state: '相',
      monthZhi: '寅',
      yaoZhi: '午',
      random: Random(1),
    );
    expect(wang.text, '寅月，爻支午，属于旺相休囚死的哪一种？');
    expect(wang.correctAnswer, '相');
    expect(wang.itemKey, 'wangxiang:相');
    expect(wang.options.toSet(), hasLength(4));
    expect(wangXiangSteps('寅', '午'), ['月支寅属木', '爻支午属火', '木生火，月令所生为相', '相']);

    final husband = KnowledgeCatalog.generateQuestion('yongshen', '丈夫');
    expect(husband.text, '测丈夫，用神取什么？');
    expect(husband.correctAnswer, '官鬼');
    expect(husband.itemKey, 'yongshen:丈夫');
    expect(
      {for (final matter in yongShenMatters) matter.matter: matter.yongShen},
      {
        for (final item in KnowledgeCatalog.itemsForTypes(['yongshen']))
          item.input: item.correctAnswer,
      },
    );

    for (final gua in getAllGuaNames()) {
      for (final zhi in diZhiCycle) {
        final answer = liuQinOfGua(gua, zhi);
        expect(liuQinNames, contains(answer), reason: '$gua $zhi');
      }
    }
    for (final month in diZhiCycle) {
      for (final zhi in diZhiCycle) {
        expect(wangXiangNames, contains(wangXiangOf(month, zhi)));
      }
    }
  });

  test('规则卡出题依赖这条规则，固定种子可复现，itemKey 始终是规则卡', () {
    var direct = 0;
    for (final item in KnowledgeCatalog.itemsForTypes([
      'changsheng_stage',
      'changsheng_start',
    ])) {
      for (var seed = 0; seed < 40; seed++) {
        final question = KnowledgeCatalog.generateQuestion(
          item.questionType,
          item.input,
          random: Random(seed),
        );
        final again = KnowledgeCatalog.generateQuestion(
          item.questionType,
          item.input,
          random: Random(seed),
        );
        expect(again.text, question.text);
        expect(again.options, question.options);
        expect(question.itemKey, item.itemKey);
        expect(question.options, contains(question.correctAnswer));
        expect(question.options.toSet(), hasLength(4));

        final riZhi = question.context['riZhi'];
        final yaoZhi = question.context['yaoZhi'];
        if (riZhi == null || yaoZhi == null) {
          direct++;
          expect(question.text, item.text);
          expect(question.correctAnswer, item.correctAnswer);
          continue;
        }
        expect(question.text, '日支$riZhi、爻支$yaoZhi，处于十二长生的哪个阶段？');
        expect(question.correctAnswer, getWuXingChangSheng(riZhi, yaoZhi));
        expect(changShengCycle, containsAll(question.options));
        final rules = KnowledgeCatalog.legacyChangShengRules(
          '${riZhi}_$yaoZhi',
        )!;
        expect(
          item.questionType == 'changsheng_start'
              ? rules.startKey
              : rules.stageKey,
          item.itemKey,
        );
      }
    }
    // 推算题为主，偶尔直接问规则。
    expect(direct, greaterThan(0));
    expect(direct, lessThan(17 * 40 / 2));
  });

  test('六冲可以按键出题', () {
    final chong = KnowledgeCatalog.generateQuestion('zhi_liuchong', '子');
    expect(chong.correctAnswer, '午');
    expect(chong.itemKey, 'zhi_liuchong:子');

    final hai = KnowledgeCatalog.generateQuestion('zhi_liuhai', '子');
    expect(hai.correctAnswer, '未');
    final po = KnowledgeCatalog.generateQuestion('zhi_poxiang', '子');
    expect(po.correctAnswer, '酉');
  });

  test('已知题型从目录重建，旧题干仍能反推', () {
    final record = WrongQuestionRecord(
      questionType: 'gua_to_xiang',
      input: '讼',
      correctAnswer: '天水',
      userAnswer: '天天',
    );
    final rebuilt = QuestionReconstructor.reconstructFromRecord(record);
    expect(rebuilt.correctAnswer, '天水');
    expect(rebuilt.itemKey, 'gua_to_xiang:讼');
    expect(rebuilt.options, contains('天水'));
    expect(rebuilt.options.toSet(), hasLength(rebuilt.options.length));

    final legacy = QuestionReconstructor.inferQuestionTypeAndInput(
      Question(text: '甲 对应什么方位？', options: ['东'], correctAnswer: '东'),
    );
    expect(legacy, {'questionType': 'gan_direction', 'input': '甲'});

    final fromStem = QuestionReconstructor.inferQuestionTypeAndInput(
      Question(text: '卦「讼」的卦象是哪个？', options: ['天水', '天天'], correctAnswer: '天水'),
    );
    expect(fromStem, {'questionType': 'gua_to_xiang', 'input': '讼'});
  });

  test('旧十二长生题干和错题记录映射到日支五行的起点卡', () {
    final legacyStem = QuestionReconstructor.inferQuestionTypeAndInput(
      Question(
        text: '若日支为『午』，某爻地支为『酉』，此爻处于十二长生的哪一阶段？',
        options: ['死', '病'],
        correctAnswer: '死',
      ),
    );
    expect(legacyStem, {'questionType': 'changsheng_start', 'input': '火'});

    final currentStem = QuestionReconstructor.inferQuestionTypeAndInput(
      Question(
        text: '日支辰、爻支申，处于十二长生的哪个阶段？',
        options: ['长生', '沐浴'],
        correctAnswer: '长生',
      ),
    );
    expect(currentStem, {'questionType': 'changsheng_start', 'input': '土'});

    final rebuilt = QuestionReconstructor.reconstructFromRecord(
      WrongQuestionRecord(
        questionType: 'changsheng',
        input: '午_酉',
        correctAnswer: '死',
        userAnswer: '病',
      ),
    );
    expect(rebuilt.itemKey, 'changsheng_start:火');
    expect(rebuilt.correctAnswer, '死');
    expect(rebuilt.text, contains('日支午、爻支酉'));
  });
}
