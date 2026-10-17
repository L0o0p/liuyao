import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/data/knowledge_catalog.dart';
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
      'gua_to_xiang',
      'xiang_to_gua',
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
