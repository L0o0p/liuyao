import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/services/local_store.dart';
import 'package:liuyao/services/storage_service.dart';
import 'package:liuyao/services/sync/sync_backend.dart';
import 'package:liuyao/services/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryBackend implements SyncBackend {
  Map<String, Map<String, dynamic>> remote = {};
  Map<String, Map<String, dynamic>> pushed = {};

  @override
  Future<Map<String, Map<String, dynamic>>> pull({required int since}) async {
    return remote.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
  }

  @override
  Future<Set<String>> push(Map<String, Map<String, dynamic>> items) async {
    pushed = items.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
    return items.keys.toSet();
  }
}

class _FailingBackend implements SyncBackend {
  @override
  Future<Map<String, Map<String, dynamic>>> pull({required int since}) async {
    throw Exception('offline');
  }

  @override
  Future<Set<String>> push(Map<String, Map<String, dynamic>> items) async {
    return {};
  }
}

Map<String, dynamic> _progress(String moduleId, int correct, int updatedAt) {
  return {
    'moduleId': moduleId,
    'firstRoundCompleted': false,
    'learnedItems': <String>[],
    'proficiency': <String, int>{},
    'currentQuestionIndex': 0,
    'totalCorrectCount': correct,
    'totalWrongCount': 0,
    'currentRoundQuestions': <Map<String, dynamic>>[],
    'currentPartCorrectCount': 0,
    'currentPartWrongCount': 0,
    'updatedAt': updatedAt,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.initialize();
  });

  test('合并时较新者胜，删除标记也参与比较', () {
    final merged = SyncEngine.merge(
      local: {
        'progress:a': _progress('a', 1, 300),
        'progress:b': _progress('b', 2, 100),
        'wrong:gan_wuxing:甲': {
          'questionType': 'gan_wuxing',
          'input': '甲',
          'updatedAt': 100,
        },
        'wrong:zhi_wuxing:子': {'deleted': true, 'updatedAt': 400},
        'progress:local-only': _progress('local-only', 4, 10),
      },
      remote: {
        'progress:a': _progress('a', 9, 100),
        'progress:b': _progress('b', 8, 200),
        'wrong:gan_wuxing:甲': {'deleted': true, 'updatedAt': 250},
        'wrong:zhi_wuxing:子': {
          'questionType': 'zhi_wuxing',
          'input': '子',
          'updatedAt': 150,
        },
        'progress:remote-only': _progress('remote-only', 5, 20),
      },
    );

    expect(merged['progress:a']!['totalCorrectCount'], 1);
    expect(merged['progress:b']!['totalCorrectCount'], 8);
    expect(merged['wrong:gan_wuxing:甲']!['deleted'], isTrue);
    expect(merged['wrong:zhi_wuxing:子']!['deleted'], isTrue);
    expect(merged['progress:local-only']!['totalCorrectCount'], 4);
    expect(merged['progress:remote-only']!['totalCorrectCount'], 5);
  });

  test('时间相同时保留本地', () {
    final merged = SyncEngine.merge(
      local: {'progress:a': _progress('a', 3, 100)},
      remote: {'progress:a': _progress('a', 9, 100)},
    );
    expect(merged['progress:a']!['totalCorrectCount'], 3);
  });

  test('导入不会覆盖本地较新的数据，但会写入较新的外来数据', () async {
    await LocalStore.instance.writeRaw(
      'progress:tiangandizhi_wuxing',
      _progress('tiangandizhi_wuxing', 5, 200),
      pending: false,
    );

    final older = await SyncEngine.instance.importJson(
      jsonEncode({
        'schema_version': 2,
        'exportedAt': 1,
        'items': {
          'progress:tiangandizhi_wuxing': _progress(
            'tiangandizhi_wuxing',
            1,
            100,
          ),
        },
      }),
    );
    expect(older.applied, 0);
    expect(older.keptLocal, 1);
    expect(
      (await StorageService.loadProgress(
        'tiangandizhi_wuxing',
      )).totalCorrectCount,
      5,
    );

    final newer = await SyncEngine.instance.importJson(
      jsonEncode({
        'schema_version': 2,
        'exportedAt': 2,
        'items': {
          'progress:tiangandizhi_wuxing': _progress(
            'tiangandizhi_wuxing',
            9,
            300,
          ),
          'wrong:gan_wuxing:乙': {
            'questionType': 'gan_wuxing',
            'input': '乙',
            'correctAnswer': '木',
            'userAnswer': '火',
            'wrongCount': 1,
            'lastWrongTime': '2024-02-01T00:00:00.000',
            'updatedAt': 300,
          },
        },
      }),
    );
    expect(newer.applied, 2);
    expect(
      (await StorageService.loadProgress(
        'tiangandizhi_wuxing',
      )).totalCorrectCount,
      9,
    );
    final wrongs = await StorageService.loadWrongQuestions();
    expect(wrongs.single.input, '乙');
  });

  test('不支持的 schema_version 会被拒绝', () async {
    expect(
      () =>
          SyncEngine.instance.importJson('{"schema_version": 1, "items": {}}'),
      throwsFormatException,
    );
  });

  test('云端较新的记录会写入本地，失败时不抛出', () async {
    await LocalStore.instance.writeRaw(
      'progress:demo',
      _progress('demo', 1, 100),
      pending: true,
    );
    final backend = _MemoryBackend()
      ..remote['progress:demo'] = _progress('demo', 9, 200)
      ..remote['progress:extra'] = _progress('extra', 3, 50);
    final engine = SyncEngine(backend: backend);

    await engine.sync();

    expect((await StorageService.loadProgress('demo')).totalCorrectCount, 9);
    expect((await StorageService.loadProgress('extra')).totalCorrectCount, 3);

    await SyncEngine(backend: _FailingBackend()).sync();
    expect((await StorageService.loadProgress('demo')).totalCorrectCount, 9);
  });

  test('空同步实现不会改动本地数据', () async {
    await LocalStore.instance.writeRaw(
      'progress:demo',
      _progress('demo', 4, 80),
      pending: true,
    );
    final version = SyncEngine.dataVersion.value;
    await SyncEngine.instance.sync();
    expect((await StorageService.loadProgress('demo')).totalCorrectCount, 4);
    expect(SyncEngine.dataVersion.value, version);
  });
}
