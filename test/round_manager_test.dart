import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/data/di_zhi.dart';
import 'package:liuyao/data/tian_gan.dart';
import 'package:liuyao/models/module_progress.dart';
import 'package:liuyao/models/question.dart';
import 'package:liuyao/services/questions.dart';
import 'package:liuyao/services/round_manager.dart';
import 'package:liuyao/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.initialize();
  });

  test('指定输入时不再随机出题', () {
    final question = Questions.generateGanWuXingQuestion(gan: '甲');
    expect(question.questionType, 'gan_wuxing');
    expect(question.input, '甲');
    expect(question.itemKey, 'gan_wuxing:甲');
    expect(question.text, contains('甲'));
  });

  test('旧题目缺少题型和输入时仍能反序列化', () {
    final question = Question.fromJson({
      'text': '甲 属于什么五行？',
      'options': ['木', '火'],
      'correctAnswer': '木',
    });
    expect(question.questionType, isEmpty);
    expect(question.input, isEmpty);
  });

  test('天干地支五行首轮恰好覆盖 10 个天干和 12 个地支', () async {
    final manager = RoundManager('tiangandizhi_wuxing');
    await manager.initialize();

    final questions = manager.questions;
    expect(questions, hasLength(22));

    final ganInputs = questions
        .where((question) => question.questionType == 'gan_wuxing')
        .map((question) => question.input)
        .toList();
    final zhiInputs = questions
        .where((question) => question.questionType == 'zhi_wuxing')
        .map((question) => question.input)
        .toList();

    expect(ganInputs, hasLength(10));
    expect(zhiInputs, hasLength(12));
    expect(ganInputs.toSet(), tianGan.map((item) => item['name']!).toSet());
    expect(zhiInputs.toSet(), diZhi.map((item) => item['name']!).toSet());

    for (final question in questions) {
      expect(question.text, contains(question.input));
      expect(question.itemKey, '${question.questionType}:${question.input}');
    }
  });

  test('答对加 10，答错减 15，并记入已学知识点', () async {
    final manager = RoundManager('tiangandizhi_wuxing');
    await manager.initialize();

    final first = manager.questions[0];
    final second = manager.questions[1];

    await manager.submitAnswer(0, true);
    await manager.submitAnswer(1, false);

    expect(manager.progress.proficiency[first.itemKey], 60);
    expect(manager.progress.proficiency[second.itemKey], 35);
    expect(manager.progress.learnedItems, contains(first.itemKey));
    expect(manager.progress.learnedItems, contains(second.itemKey));
  });

  test('复习模式的薄弱题来自对应知识点', () async {
    final progress = ModuleProgress(
      moduleId: 'tiangandizhi_wuxing',
      firstRoundCompleted: true,
      proficiency: {'gan_wuxing:甲': 10, 'zhi_wuxing:子': 80},
    );
    await StorageService.saveProgress(progress);

    final manager = RoundManager('tiangandizhi_wuxing');
    await manager.initialize();

    final weakQuestions = manager.questions
        .where((question) => question.itemKey == 'gan_wuxing:甲')
        .toList();
    // 20 题里 60% 来自薄弱项，只有「甲」低于 60 分。
    expect(weakQuestions.length, greaterThanOrEqualTo(12));
    for (final question in weakQuestions) {
      expect(question.questionType, 'gan_wuxing');
      expect(question.input, '甲');
      expect(question.text, contains('甲'));
    }
  });
}
