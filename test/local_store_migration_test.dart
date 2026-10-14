import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/models/wrong_question_record.dart';
import 'package:liuyao/services/local_store.dart';
import 'package:liuyao/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('旧格式进度和错题会迁移到新键', () async {
    SharedPreferences.setMockInitialValues({
      'module_progress_tiangandizhi_wuxing': jsonEncode({
        'moduleId': 'tiangandizhi_wuxing',
        'firstRoundCompleted': true,
        'learnedItems': ['甲'],
        'proficiency': {'甲': 70},
        'currentQuestionIndex': 3,
        'totalCorrectCount': 8,
        'totalWrongCount': 2,
        'currentRoundQuestions': [
          {
            'text': '甲 属于什么五行？',
            'options': ['木', '火'],
            'correctAnswer': '木',
          },
        ],
        'currentPartCorrectCount': 1,
        'currentPartWrongCount': 0,
      }),
      'wrong_questions': jsonEncode([
        {
          'questionType': 'gan_wuxing',
          'input': '甲',
          'correctAnswer': '木',
          'userAnswer': '火',
          'wrongCount': 2,
          'lastWrongTime': '2024-01-02T00:00:00.000',
        },
        {
          'questionType': 'zhi_wuxing',
          'input': '子',
          'correctAnswer': '水',
          'userAnswer': '木',
          'wrongCount': 1,
          'lastWrongTime': '2024-01-01T00:00:00.000',
        },
      ]),
    });

    await StorageService.initialize();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(LocalStore.schemaVersionKey), 2);
    expect(prefs.getString('module_progress_tiangandizhi_wuxing'), isNull);
    expect(prefs.getString('wrong_questions'), isNull);
    expect(prefs.containsKey('progress:tiangandizhi_wuxing'), isTrue);
    expect(prefs.containsKey('wrong:gan_wuxing:甲'), isTrue);
    expect(prefs.containsKey('wrong:zhi_wuxing:子'), isTrue);

    final progress = await StorageService.loadProgress('tiangandizhi_wuxing');
    expect(progress.firstRoundCompleted, isTrue);
    expect(progress.totalCorrectCount, 8);
    expect(progress.totalWrongCount, 2);
    expect(progress.learnedItems, ['甲']);
    expect(progress.proficiency['甲'], 70);
    expect(progress.updatedAt, 0);
    expect(progress.currentRoundQuestions.single.questionType, isEmpty);

    final wrongs = await StorageService.loadWrongQuestions();
    expect(wrongs, hasLength(2));
    expect(wrongs.first.input, '甲');
    expect(wrongs.first.wrongCount, 2);
    expect(wrongs.first.updatedAt, 0);

    final stored = await LocalStore.instance.get(
      'progress:tiangandizhi_wuxing',
    );
    expect(stored?['updatedAt'], 0);

    // 再次启动不应把已删除的旧键写回来。
    await StorageService.initialize();
    final prefsAgain = await SharedPreferences.getInstance();
    expect(prefsAgain.getString('module_progress_tiangandizhi_wuxing'), isNull);
    expect(prefsAgain.getInt(LocalStore.schemaVersionKey), 2);
    expect(
      (await StorageService.loadProgress(
        'tiangandizhi_wuxing',
      )).totalCorrectCount,
      8,
    );
  });

  test('错题按题型拆开保存，重复作答会累加次数，删除留下标记', () async {
    await StorageService.initialize();

    await StorageService.recordWrongQuestion(
      WrongQuestionRecord(
        questionType: 'gan_wuxing',
        input: '甲',
        correctAnswer: '木',
        userAnswer: '火',
      ),
    );
    await StorageService.recordWrongQuestion(
      WrongQuestionRecord(
        questionType: 'gan_wuxing',
        input: '甲',
        correctAnswer: '木',
        userAnswer: '土',
      ),
    );

    final records = await StorageService.loadWrongQuestions();
    expect(records, hasLength(1));
    expect(records.single.wrongCount, 2);
    expect(records.single.userAnswer, '土');

    await StorageService.removeWrongQuestion(records.single.uniqueId);
    expect(await StorageService.loadWrongQuestions(), isEmpty);

    final tombstone = await LocalStore.instance.get('wrong:gan_wuxing:甲');
    expect(tombstone?['deleted'], isTrue);
    expect(LocalStore.updatedAtOf(tombstone!), greaterThan(0));
  });
}
