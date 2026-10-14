import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/data/di_zhi.dart';
import 'package:liuyao/data/gua_data.dart';
import 'package:liuyao/data/knowledge_catalog.dart';
import 'package:liuyao/data/zhi_relations.dart';
import 'package:liuyao/models/wrong_question_record.dart';
import 'package:liuyao/services/round_manager.dart';
import 'package:liuyao/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<RoundManager> _firstRound(String moduleId) async {
  final manager = RoundManager(moduleId);
  await manager.initialize();
  return manager;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.initialize();
  });

  group('综合与生克模块出题', () {
    test('五行生克首轮覆盖 5 个五行的生与克', () async {
      final questions = (await _firstRound('tiangandizhi_shengke')).questions;
      expect(questions, hasLength(10));

      final wuxing = {'木', '火', '土', '金', '水'};
      final sheng = questions
          .where((q) => q.questionType == 'wuxing_sheng')
          .map((q) => q.input)
          .toSet();
      final ke = questions
          .where((q) => q.questionType == 'wuxing_ke')
          .map((q) => q.input)
          .toSet();
      expect(sheng, wuxing);
      expect(ke, wuxing);
    });

    test('天干地支综合练习混合多种题型', () async {
      final questions = (await _firstRound(
        'tiangandizhi_comprehensive',
      )).questions;
      expect(questions, hasLength(RoundManager.comprehensiveRoundSize));

      final allowed = KnowledgeCatalog.module(
        'tiangandizhi_comprehensive',
      )!.questionTypes.toSet();
      final types = questions.map((q) => q.questionType).toSet();
      expect(allowed.containsAll(types), isTrue);
      expect(allowed, contains('gan_season'));
      expect(allowed, contains('zhi_hour'));
      expect(types.length, greaterThan(1));
      expect(questions.map((q) => q.itemKey).toSet(), hasLength(20));
    });

    test('综合练习不全是天干五行题，并跨多个模块', () async {
      final questions = (await _firstRound('comprehensive')).questions;
      expect(questions, hasLength(RoundManager.comprehensiveRoundSize));
      expect(questions.every((q) => q.questionType == 'gan_wuxing'), isFalse);
      expect(
        questions.map((q) => q.questionType).toSet().length,
        greaterThan(2),
      );
      expect(questions.map((q) => q.itemKey).toSet(), hasLength(20));
    });

    test('综合练习复习轮也是混合题', () async {
      final manager = await _firstRound('comprehensive');
      await manager.completeRound();
      expect(manager.isFirstRoundCompleted, isTrue);
      expect(manager.questions, hasLength(20));
      expect(
        manager.questions.every((q) => q.questionType == 'gan_wuxing'),
        isFalse,
      );
    });
  });

  group('首轮按知识点覆盖', () {
    test('全覆盖模块的首轮正好是注册表里的每个知识点', () async {
      const ids = [
        'tiangandizhi_wuxing',
        'tiangandizhi_yinyang',
        'tiangandizhi_direction',
        'tiangandizhi_time',
        'tiangandizhi_shengke',
        'wuxing',
        'hechong',
      ];
      for (final id in ids) {
        final module = KnowledgeCatalog.module(id)!;
        final expected = KnowledgeCatalog.itemsForTypes(module.questionTypes);
        final questions = (await _firstRound(id)).questions;
        expect(
          questions.map((q) => q.itemKey).toSet(),
          expected.map((item) => item.itemKey).toSet(),
          reason: id,
        );
        expect(questions, hasLength(expected.length), reason: id);
        expect(
          questions.every((q) => q.questionType == 'gan_wuxing'),
          isFalse,
          reason: id,
        );
      }
    });

    test('六十四卦首轮每卦一题，两种方向交错', () async {
      final manager = await _firstRound('64gua');
      final questions = manager.questions;
      expect(questions, hasLength(64));
      expect(manager.partSize, 16);
      expect(manager.totalParts, 4);

      final names = <String>{};
      for (var i = 0; i < questions.length; i++) {
        final question = questions[i];
        if (i.isEven) {
          expect(question.questionType, 'gua_to_xiang');
          names.add(question.input);
        } else {
          expect(question.questionType, 'xiang_to_gua');
          final guaName = getGuaName(question.input);
          expect(guaName, isNotNull);
          names.add(guaName!);
        }
      }
      expect(names, getAllGuaNames().toSet());
    });

    test('刑冲合害：六合 12 支、三合 4 局、三刑 3 组、自刑 4 支', () async {
      final questions = (await _firstRound('hechong')).questions;

      List<String> inputsOf(String type) => questions
          .where((q) => q.questionType == type)
          .map((q) => q.input)
          .toList();

      final liuHe = inputsOf('zhi_liuhe');
      expect(liuHe, hasLength(12));
      expect(liuHe.toSet(), diZhi.map((z) => z['name']!).toSet());
      expect(inputsOf('zhi_sanhe').toSet(), sanHe.map((g) => g.join()).toSet());
      expect(
        inputsOf('zhi_sanxing').toSet(),
        sanXing.map((g) => g.join()).toSet(),
      );
      expect(inputsOf('zhi_zixing').toSet(), ziXing.keys.toSet());
      expect(questions, hasLength(12 + 4 + 3 + 4));
    });

    test('十二长生：每个日支、每个阶段各出现两次且不重复', () async {
      final questions = (await _firstRound('shierchangsheng')).questions;
      expect(questions, hasLength(24));
      expect(questions.map((q) => q.input).toSet(), hasLength(24));

      final riCounts = <String, int>{};
      final stageCounts = <String, int>{};
      for (final q in questions) {
        expect(q.questionType, 'changsheng');
        final riZhi = q.input.split('_').first;
        riCounts[riZhi] = (riCounts[riZhi] ?? 0) + 1;
        stageCounts[q.correctAnswer] = (stageCounts[q.correctAnswer] ?? 0) + 1;
      }
      expect(riCounts.keys.toSet(), diZhiCycle.toSet());
      expect(riCounts.values.every((c) => c == 2), isTrue);
      expect(stageCounts.keys.toSet(), changShengCycle.toSet());
      expect(stageCounts.values.every((c) => c == 2), isTrue);
    });
  });

  test('只接受当前题的提交，不能跳题', () async {
    final manager = await _firstRound('tiangandizhi_wuxing');

    await manager.submitAnswer(5, true);
    expect(manager.currentIndex, 0);
    expect(manager.progress.totalCorrectCount, 0);

    await manager.submitAnswer(0, true);
    await manager.submitAnswer(0, false);
    expect(manager.currentIndex, 1);
    expect(manager.progress.totalCorrectCount, 1);
    expect(manager.progress.totalWrongCount, 0);
  });

  group('错题本连续答对', () {
    WrongQuestionRecord record() => WrongQuestionRecord(
      questionType: 'gan_wuxing',
      input: '甲',
      correctAnswer: '木',
      userAnswer: '火',
    );

    test('旧数据没有 correctStreak 时为 0', () {
      final parsed = WrongQuestionRecord.fromJson({
        'questionType': 'gan_wuxing',
        'input': '甲',
        'correctAnswer': '木',
        'userAnswer': '火',
        'wrongCount': 2,
        'lastWrongTime': DateTime(2025).toIso8601String(),
      });
      expect(parsed.correctStreak, 0);
      expect(parsed.toJson()['correctStreak'], 0);
    });

    test('连续答对 2 次后移出错题本', () async {
      await StorageService.recordWrongQuestion(record());

      expect(await StorageService.recordWrongQuestionCorrect(record()), 1);
      final kept = await StorageService.loadWrongQuestions();
      expect(kept, hasLength(1));
      expect(kept.single.correctStreak, 1);

      expect(await StorageService.recordWrongQuestionCorrect(record()), 2);
      expect(await StorageService.loadWrongQuestions(), isEmpty);
      expect(await StorageService.recordWrongQuestionCorrect(record()), isNull);
    });

    test('再次答错时连续答对次数清零', () async {
      await StorageService.recordWrongQuestion(record());
      await StorageService.recordWrongQuestionCorrect(record());

      await StorageService.recordWrongQuestion(record());
      final records = await StorageService.loadWrongQuestions();
      expect(records.single.correctStreak, 0);
      expect(records.single.wrongCount, 2);
    });
  });
}
