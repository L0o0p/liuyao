import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/module_progress.dart';
import '../models/wrong_question_record.dart';

/// 本地存储服务
/// 负责管理用户学习进度和错题记录的持久化存储
/// 使用 SharedPreferences 作为存储引擎
///
/// 设计思路：
/// 1. 学习进度：按模块ID存储（module_progress_xxx）
/// 2. 错题记录：统一存储所有错题（wrong_questions）
class StorageService {
  static const String _keyPrefix = 'module_progress_';
  static const String _wrongQuestionsKey = 'wrong_questions';

  /// 保存模块进度到本地
  /// @param progress 要保存的进度对象
  static Future<void> saveProgress(ModuleProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyPrefix + progress.moduleId;
    final jsonString = jsonEncode(progress.toJson());
    await prefs.setString(key, jsonString);
  }

  /// 从本地加载模块进度
  /// @param moduleId 模块ID
  /// @return 进度对象，如果不存在则返回新创建的默认进度
  static Future<ModuleProgress> loadProgress(String moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyPrefix + moduleId;
    final jsonString = prefs.getString(key);

    if (jsonString == null) {
      // 首次学习该模块，返回默认进度
      return ModuleProgress(moduleId: moduleId);
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ModuleProgress.fromJson(json);
    } catch (e) {
      // 解析失败，返回默认进度
      print('Failed to parse progress for $moduleId: $e');
      return ModuleProgress(moduleId: moduleId);
    }
  }

  /// 清除某个模块的进度（重置学习）
  /// @param moduleId 模块ID
  static Future<void> clearProgress(String moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyPrefix + moduleId;
    await prefs.remove(key);
  }

  /// 清除所有模块的进度
  static Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_keyPrefix)) {
        await prefs.remove(key);
      }
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
    final allRecords = await loadWrongQuestions();

    // 检查是否已存在该题的错题记录
    final existingIndex = allRecords.indexWhere(
      (r) => r.uniqueId == record.uniqueId,
    );

    if (existingIndex != -1) {
      // 已存在，更新错误次数
      allRecords[existingIndex].incrementWrongCount(record.userAnswer);
    } else {
      // 新错题，添加到列表
      allRecords.add(record);
    }

    await _saveWrongQuestions(allRecords);
  }

  /// 加载所有错题记录
  /// @return 错题记录列表（按最后答错时间倒序排列）
  static Future<List<WrongQuestionRecord>> loadWrongQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_wrongQuestionsKey);

    if (jsonString == null) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final records = jsonList
          .map(
            (json) =>
                WrongQuestionRecord.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      // 按最后答错时间倒序排列（最近的在前面）
      records.sort((a, b) => b.lastWrongTime.compareTo(a.lastWrongTime));

      return records;
    } catch (e) {
      print('Failed to parse wrong questions: $e');
      return [];
    }
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
    final allRecords = await loadWrongQuestions();
    allRecords.removeWhere((r) => r.uniqueId == uniqueId);
    await _saveWrongQuestions(allRecords);
  }

  /// 清空所有错题记录
  static Future<void> clearWrongQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_wrongQuestionsKey);
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

  /// 内部方法：保存错题记录列表
  static Future<void> _saveWrongQuestions(
    List<WrongQuestionRecord> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = records.map((r) => r.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_wrongQuestionsKey, jsonString);
  }
}
