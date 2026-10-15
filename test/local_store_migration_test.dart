import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/models/srs_card.dart';
import 'package:liuyao/services/local_store.dart';
import 'package:liuyao/services/srs_scheduler.dart';
import 'package:liuyao/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('旧错题迁移后立刻到期，对得上的熟练度变成复习卡或学习卡', () async {
    SharedPreferences.setMockInitialValues({
      'schema_version': 2,
      'wrong:gan_wuxing:甲': jsonEncode({
        'questionType': 'gan_wuxing',
        'input': '甲',
        'correctAnswer': '木',
        'userAnswer': '火',
        'wrongCount': 2,
        'lastWrongTime': '2024-01-02T00:00:00.000',
        'updatedAt': 1234,
      }),
      'wrong:gan_wuxing:丙': jsonEncode({
        'questionType': 'gan_wuxing',
        'input': '丙',
      }),
      'progress:tiangandizhi_wuxing': jsonEncode({
        'moduleId': 'tiangandizhi_wuxing',
        'learnedItems': ['甲', 'gan_wuxing:乙'],
        'proficiency': {
          '甲': 70,
          'gan_wuxing:戊': 100,
          'gan_wuxing:己': 60,
          'gan_wuxing:丁': 40,
        },
      }),
    });

    final before = DateTime.now();
    await StorageService.initialize();
    final after = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(LocalStore.schemaVersionKey), 3);
    expect(prefs.getString('wrong:gan_wuxing:甲'), isNull);
    expect(prefs.getString('wrong:gan_wuxing:丙'), isNull);
    expect(prefs.getString('progress:tiangandizhi_wuxing'), isNull);
    expect(prefs.containsKey('srs:甲'), isFalse);

    final jia = await StorageService.loadCard('gan_wuxing:甲');
    expect(jia, isNotNull);
    expect(jia!.state, SrsState.learning);
    expect(jia.lapses, 2);
    expect(jia.updatedAt, 1234);
    expect(_isAround(jia.dueAt, before, after), isTrue);

    final bing = await StorageService.loadCard('gan_wuxing:丙');
    expect(bing!.state, SrsState.learning);
    expect(bing.lapses, 1);
    expect(_isAround(bing.dueAt, before, after), isTrue);

    final yi = await StorageService.loadCard('gan_wuxing:乙');
    expect(yi!.state, SrsState.learning);
    expect(_isAround(yi.dueAt, before, after), isTrue);

    final ding = await StorageService.loadCard('gan_wuxing:丁');
    expect(ding!.state, SrsState.learning);
    expect(ding.intervalDays, 0);
    expect(_isAround(ding.dueAt, before, after), isTrue);

    final wu = await StorageService.loadCard('gan_wuxing:戊');
    expect(wu!.state, SrsState.review);
    expect(wu.intervalDays, SrsScheduler.intervalDaysForScore(100));
    expect(wu.lapses, 0);
    expect(
      wu.dueAt.isAfter(before.add(const Duration(days: 6, hours: 20))),
      isTrue,
    );

    final ji = await StorageService.loadCard('gan_wuxing:己');
    expect(ji!.state, SrsState.review);
    expect(ji.intervalDays, 1);
    expect(ji.dueAt.isAfter(before.add(const Duration(hours: 20))), isTrue);
    expect(ji.dueAt.isBefore(after.add(const Duration(days: 1, hours: 1))), isTrue);

    expect(await StorageService.loadCard('甲'), isNull);

    final dueAt = jia.dueAt;
    await StorageService.initialize();
    final prefsAgain = await SharedPreferences.getInstance();
    expect(prefsAgain.getString('wrong:gan_wuxing:甲'), isNull);
    expect(prefsAgain.getInt(LocalStore.schemaVersionKey), 3);
    expect((await StorageService.loadCard('gan_wuxing:甲'))!.dueAt, dueAt);
  });

  test('更早的进度和错题会先收成新键，再变成复习卡', () async {
    SharedPreferences.setMockInitialValues({
      'module_progress_tiangandizhi_wuxing': jsonEncode({
        'moduleId': 'tiangandizhi_wuxing',
        'firstRoundCompleted': true,
        'learnedItems': ['甲', 'gan_wuxing:乙'],
        'proficiency': {'甲': 70, 'gan_wuxing:戊': 80},
        'totalCorrectCount': 8,
        'totalWrongCount': 2,
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
        {'input': '子'},
      ]),
    });

    final before = DateTime.now();
    await StorageService.initialize();
    final after = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getInt(LocalStore.schemaVersionKey), 3);
    expect(prefs.getString('module_progress_tiangandizhi_wuxing'), isNull);
    expect(prefs.getString('wrong_questions'), isNull);
    expect(prefs.getString('progress:tiangandizhi_wuxing'), isNull);
    expect(prefs.getString('wrong:gan_wuxing:甲'), isNull);

    final jia = await StorageService.loadCard('gan_wuxing:甲');
    expect(jia!.lapses, 2);
    expect(jia.state, SrsState.learning);
    expect(_isAround(jia.dueAt, before, after), isTrue);

    final wu = await StorageService.loadCard('gan_wuxing:戊');
    expect(wu!.state, SrsState.review);
    expect(wu.intervalDays, SrsScheduler.intervalDaysForScore(80));
    expect(wu.dueAt.isAfter(after), isTrue);

    expect(await StorageService.loadCard('子'), isNull);
    expect(await StorageService.loadCard('甲'), isNull);
  });

  test('复习卡片按知识点保存，删除留下标记', () async {
    await StorageService.initialize();
    await StorageService.saveCard(
      SrsScheduler.introduce('gan_wuxing:甲', DateTime(2026, 10, 15)),
    );

    final loaded = await StorageService.loadCard('gan_wuxing:甲');
    expect(loaded!.state, SrsState.learning);
    expect(loaded.itemKey, 'gan_wuxing:甲');

    await StorageService.deleteCard('gan_wuxing:甲');
    expect(await StorageService.loadCard('gan_wuxing:甲'), isNull);
    final tombstone = await LocalStore.instance.get('srs:gan_wuxing:甲');
    expect(tombstone?['deleted'], isTrue);
    expect(LocalStore.updatedAtOf(tombstone!), greaterThan(0));
  });

  test('每日新学计数跨天清零', () async {
    await StorageService.initialize();
    final firstDay = DateTime(2026, 10, 15, 8);
    await StorageService.addIntroduced(firstDay, 2);
    await StorageService.addIntroduced(DateTime(2026, 10, 15, 21), 3);
    expect(await StorageService.introducedOn(DateTime(2026, 10, 15, 23)), 5);
    expect(await StorageService.introducedOn(DateTime(2026, 10, 16, 0, 30)), 0);
  });
}

bool _isAround(DateTime value, DateTime before, DateTime after) {
  return !value.isBefore(before.subtract(const Duration(seconds: 5))) &&
      !value.isAfter(after.add(const Duration(seconds: 5)));
}
