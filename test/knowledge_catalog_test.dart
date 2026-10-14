import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/data/knowledge_catalog.dart';
import 'package:liuyao/models/question.dart';
import 'package:liuyao/models/wrong_question_record.dart';
import 'package:liuyao/services/question_reconstructor.dart';
import 'package:liuyao/services/questions.dart';

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
      'changsheng',
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

  test('十二长生键仍是日支_爻支，六冲可以按键出题', () {
    final changSheng = KnowledgeCatalog.generateQuestion(
      'changsheng',
      '子_亥',
      random: Random(3),
    );
    expect(changSheng.questionType, 'changsheng');
    expect(changSheng.input, '子_亥');
    expect(changSheng.itemKey, 'changsheng:子_亥');
    expect(changSheng.text, contains('日支为『子』'));
    expect(changSheng.text, contains('爻地支为『亥』'));

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
}
