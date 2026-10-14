import '../models/module_progress.dart';
import '../models/wrong_question_record.dart';
import 'local_store.dart';

/// 本地存储服务
/// 负责管理用户学习进度和错题记录的持久化存储
///
/// 设计思路：
/// 1. 学习进度：按模块拆成 progress:{moduleId}
/// 2. 错题记录：按题型和输入拆成 wrong:{questionType}:{input}
/// 3. 每条数据都带 updatedAt，删除用删除标记，方便以后同步
/// 4. 对外方法签名保持不变，界面层不用跟着改
class StorageService {
  /// 启动时把旧版 SharedPreferences 数据迁到新键。
  static Future<void> initialize() async {
    await LocalStore.instance.migrateIfNeeded();
  }

  /// 保存模块进度
  /// @param progress 要保存的进度对象
  static Future<void> saveProgress(ModuleProgress progress) async {
    progress.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await LocalStore.instance.put(
      _progressKey(progress.moduleId),
      progress.toJson(),
    );
  }

  /// 从本地加载模块进度
  /// @param moduleId 模块ID
  /// @return 进度对象，如果不存在则返回新创建的默认进度
  static Future<ModuleProgress> loadProgress(String moduleId) async {
    final data = await LocalStore.instance.get(_progressKey(moduleId));
    if (data == null || LocalStore.isDeleted(data)) {
      return ModuleProgress(moduleId: moduleId);
    }

    try {
      return ModuleProgress.fromJson(data);
    } catch (e) {
      print('Failed to parse progress for $moduleId: $e');
      return ModuleProgress(moduleId: moduleId);
    }
  }

  /// 清除某个模块的进度（重置学习）
  /// @param moduleId 模块ID
  static Future<void> clearProgress(String moduleId) async {
    await LocalStore.instance.delete(_progressKey(moduleId));
  }

  /// 清除所有模块的进度
  static Future<void> clearAllProgress() async {
    final keys = await LocalStore.instance.keysWithPrefix(
      LocalStore.progressPrefix,
    );
    for (final key in keys) {
      await LocalStore.instance.delete(key);
    }
  }

  /// 检查模块是否是首次学习
  /// @param moduleId 模块ID
  /// @return true 表示首次学习，false 表示已有学习记录
  static Future<bool> isFirstTime(String moduleId) async {
    final progress = await loadProgress(moduleId);
    return !progress.firstRoundCompleted;
  }

  // ========== 错题记录管理 ==========

  /// 记录错题
  /// 设计原理：
  /// - 如果该题已存在错题记录 → 增加错误次数
  /// - 如果是新错题 → 创建新记录
  ///
  /// @param record 错题记录
  static Future<void> recordWrongQuestion(WrongQuestionRecord record) async {
    final key = _wrongKey(record.questionType, record.input);
    final existing = await LocalStore.instance.get(key);

    final WrongQuestionRecord stored;
    if (existing != null && !LocalStore.isDeleted(existing)) {
      stored = WrongQuestionRecord.fromJson(existing);
      stored.incrementWrongCount(record.userAnswer);
    } else {
      stored = record;
    }
    stored.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await LocalStore.instance.put(key, stored.toJson());
  }

  /// 在错题本中答对一次
  /// 连续答对次数 +1，达到 [WrongQuestionRecord.requiredCorrectStreak] 时移出错题本
  ///
  /// @param record 错题记录
  /// @return 更新后的连续答对次数；记录已不存在时返回 null
  static Future<int?> recordWrongQuestionCorrect(
    WrongQuestionRecord record,
  ) async {
    final key = _wrongKey(record.questionType, record.input);
    final existing = await LocalStore.instance.get(key);
    if (existing == null || LocalStore.isDeleted(existing)) return null;

    final stored = WrongQuestionRecord.fromJson(existing);
    stored.correctStreak++;
    if (stored.correctStreak >= WrongQuestionRecord.requiredCorrectStreak) {
      await LocalStore.instance.delete(key);
    } else {
      stored.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await LocalStore.instance.put(key, stored.toJson());
    }
    return stored.correctStreak;
  }

  /// 加载所有错题记录
  /// @return 错题记录列表（按最后答错时间倒序排列）
  static Future<List<WrongQuestionRecord>> loadWrongQuestions() async {
    final keys = await LocalStore.instance.keysWithPrefix(
      LocalStore.wrongPrefix,
    );
    final records = <WrongQuestionRecord>[];

    for (final key in keys) {
      final data = await LocalStore.instance.get(key);
      if (data == null || LocalStore.isDeleted(data)) continue;
      try {
        records.add(WrongQuestionRecord.fromJson(data));
      } catch (e) {
        print('Failed to parse wrong question $key: $e');
      }
    }

    records.sort((a, b) => b.lastWrongTime.compareTo(a.lastWrongTime));
    return records;
  }

  /// 根据错误次数筛选错题
  /// @param minWrongCount 最小错误次数
  /// @return 符合条件的错题记录
  static Future<List<WrongQuestionRecord>> loadWrongQuestionsByCount({
    int minWrongCount = 1,
  }) async {
    final allRecords = await loadWrongQuestions();
    return allRecords.where((r) => r.wrongCount >= minWrongCount).toList();
  }

  /// 根据题目类型筛选错题
  /// @param questionType 题目类型
  /// @return 该类型的错题记录
  static Future<List<WrongQuestionRecord>> loadWrongQuestionsByType(
    String questionType,
  ) async {
    final allRecords = await loadWrongQuestions();
    return allRecords.where((r) => r.questionType == questionType).toList();
  }

  /// 移除某个错题记录
  /// 使用场景：用户答对多次后，可以将该题从错题本移除
  ///
  /// @param uniqueId 错题唯一标识
  static Future<void> removeWrongQuestion(String uniqueId) async {
    final keys = await LocalStore.instance.keysWithPrefix(
      LocalStore.wrongPrefix,
    );
    for (final key in keys) {
      final data = await LocalStore.instance.get(key);
      if (data == null || LocalStore.isDeleted(data)) continue;
      try {
        final record = WrongQuestionRecord.fromJson(data);
        if (record.uniqueId == uniqueId) {
          await LocalStore.instance.delete(key);
        }
      } catch (e) {
        print('Failed to remove wrong question $key: $e');
      }
    }
  }

  /// 清空所有错题记录
  static Future<void> clearWrongQuestions() async {
    final keys = await LocalStore.instance.keysWithPrefix(
      LocalStore.wrongPrefix,
    );
    for (final key in keys) {
      await LocalStore.instance.delete(key);
    }
  }

  /// 获取错题统计信息
  /// @return Map包含: totalCount（总错题数）, averageWrongCount（平均错误次数）
  static Future<Map<String, dynamic>> getWrongQuestionsStats() async {
    final allRecords = await loadWrongQuestions();

    if (allRecords.isEmpty) {
      return {
        'totalCount': 0,
        'averageWrongCount': 0.0,
        'maxWrongCount': 0,
        'questionTypeBreakdown': <String, int>{},
      };
    }

    final totalCount = allRecords.length;
    final totalWrongCount = allRecords.fold<int>(
      0,
      (sum, r) => sum + r.wrongCount,
    );
    final averageWrongCount = totalWrongCount / totalCount;
    final maxWrongCount = allRecords
        .map((r) => r.wrongCount)
        .reduce((a, b) => a > b ? a : b);

    // 按题目类型统计
    final typeBreakdown = <String, int>{};
    for (final record in allRecords) {
      typeBreakdown[record.questionType] =
          (typeBreakdown[record.questionType] ?? 0) + 1;
    }

    return {
      'totalCount': totalCount,
      'averageWrongCount': averageWrongCount,
      'maxWrongCount': maxWrongCount,
      'questionTypeBreakdown': typeBreakdown,
    };
  }

  static String _progressKey(String moduleId) =>
      '${LocalStore.progressPrefix}$moduleId';

  static String _wrongKey(String questionType, String input) =>
      '${LocalStore.wrongPrefix}$questionType:$input';
}
